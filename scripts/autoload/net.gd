extends Node
## Red: cooperativo de 2 jugadores con código de partida.
## El código codifica IP + puerto en base32 (sin servidores externos).
## El anfitrión intenta abrir el puerto con UPnP; también hay código LAN y búsqueda automática en la red local.
##
## Flujo de conexión (evita que el cliente entre en un mundo que el anfitrión aún no ha creado):
##   cliente conecta -> _hello(protocolo) -> _hello_reply(ok, mundo_listo)
##   el cliente espera en la sala hasta que el anfitrión entra en la partida (_host_world_ready)

signal peer_joined(id: int)
signal peer_left(id: int)
signal connected_ok                 # cliente: enlace establecido y versión aceptada (en la sala de espera)
signal world_ready                  # cliente: el anfitrión ya está en la partida, se puede entrar
signal connect_failed(reason: String)  # timeout | version | full | refused
signal host_closed
signal upnp_done(ok: bool, external_ip: String)
signal lobby_changed                # anfitrión: alguien ha entrado o salido de la sala
signal lan_games_changed            # cliente: lista de partidas de la red local actualizada

const PORT := 24680
const LAN_PORT := 24681
const MAX_PEERS := 1  # anfitrión + 1 = 2 jugadores
const ALPHA := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # sin 0/O/1/I
const PROTOCOL := 3   # súbelo si cambian las RPC: versiones distintas no pueden jugar juntas
const CONNECT_TIMEOUT := 9.0
const HELLO_TIMEOUT := 8.0

var online := false
var is_host := false
var host_in_world := false
var external_ip := ""
var local_ip := ""
var upnp_ok := false
var upnp_note := ""
var lan_games := {}  # ip -> {"name", "port", "seen"}
var _upnp: UPNP
var _threads: Array[Thread] = []
var _upnp_gen := 0
var _connect_t := -1.0
var _hello_t := -1.0
var _bc: PacketPeerUDP
var _bc_t := 0.0
var _listen: PacketPeerUDP

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)
	local_ip = _find_local_ip()

func _process(delta: float) -> void:
	if _connect_t >= 0.0:
		_connect_t += delta
		if _connect_t > CONNECT_TIMEOUT:
			_fail("timeout")
	if _hello_t >= 0.0:
		_hello_t += delta
		if _hello_t > HELLO_TIMEOUT:
			_fail("version")
	if is_host and _bc:
		_bc_t -= delta
		if _bc_t <= 0.0:
			_bc_t = 1.0
			_broadcast()
	if _listen:
		_poll_lan()

func is_online() -> bool:
	return online

func my_id() -> int:
	return multiplayer.get_unique_id()

func peers() -> PackedInt32Array:
	return multiplayer.get_peers()

func has_partner() -> bool:
	return online and not multiplayer.get_peers().is_empty()

# ------------------------------------------------------------------ anfitrión
func host() -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PEERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	online = true
	is_host = true
	host_in_world = false
	upnp_ok = false
	upnp_note = ""
	external_ip = ""
	local_ip = _find_local_ip()
	_upnp_gen += 1
	_start_thread(_upnp_setup.bind(_upnp_gen))
	_bc = PacketPeerUDP.new()
	_bc.set_broadcast_enabled(true)
	_bc_t = 0.0
	return OK

func _start_thread(fn: Callable) -> void:
	var th := Thread.new()
	_threads.append(th)
	th.start(func() -> void:
		fn.call()
		call_deferred("_reap_thread", th))

func _reap_thread(th: Thread) -> void:
	if th.is_started():
		th.wait_to_finish()
	_threads.erase(th)

func _upnp_setup(gen: int) -> void:
	var u := UPNP.new()
	var ok := false
	var ip := ""
	var note := ""
	if u.discover(2000, 2) == UPNP.UPNP_RESULT_SUCCESS and u.get_gateway() and u.get_gateway().is_valid_gateway():
		var r1 := u.add_port_mapping(PORT, PORT, "Seraphall", "UDP")
		ip = u.query_external_address()
		ok = r1 == UPNP.UPNP_RESULT_SUCCESS and ip != ""
		if ok and _is_private_ip(ip):
			# el router no tiene IP pública (CGNAT): el puerto abierto no sirve desde Internet
			ok = false
			ip = ""
			note = "cgnat"
	else:
		note = "no_upnp"
	call_deferred("_upnp_finished", gen, ok, ip, note, u)

func _upnp_finished(gen: int, ok: bool, ip: String, note: String, u: UPNP) -> void:
	if gen != _upnp_gen or not is_host:
		if ok:
			_start_thread(func() -> void: u.delete_port_mapping(PORT, "UDP"))
		return
	_upnp = u
	upnp_ok = ok
	upnp_note = note
	external_ip = ip
	upnp_done.emit(ok, ip)

func announce_world_ready() -> void:
	## El anfitrión ya tiene el mundo creado: quien espere en la sala puede entrar.
	host_in_world = true
	if not online or not is_host:
		return
	for pid in multiplayer.get_peers():
		_host_world_ready.rpc_id(pid)

func _on_peer_connected(id: int) -> void:
	if is_host:
		_apply_timeouts(id)
	peer_joined.emit(id)
	lobby_changed.emit()

func _on_peer_disconnected(id: int) -> void:
	peer_left.emit(id)
	lobby_changed.emit()

# ------------------------------------------------------------------ apretón de manos
func _apply_timeouts(id: int) -> void:
	## Crear el mundo bloquea varios segundos: sin esto ENet da por muerta la conexión mientras carga
	var mp := multiplayer.multiplayer_peer
	if mp is ENetMultiplayerPeer:
		var pkt: ENetPacketPeer = (mp as ENetMultiplayerPeer).get_peer(id)
		if pkt:
			pkt.set_timeout(64, 25000, 60000)

func _on_connected_to_server() -> void:
	_connect_t = -1.0
	_hello_t = 0.0
	_apply_timeouts(1)
	_hello.rpc_id(1, PROTOCOL)

@rpc("any_peer", "call_remote", "reliable")
func _hello(proto: int) -> void:
	if not is_host:
		return
	var sender := multiplayer.get_remote_sender_id()
	var ok := proto == PROTOCOL
	_hello_reply.rpc_id(sender, ok, host_in_world)
	if not ok:
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			var mp := multiplayer.multiplayer_peer
			if mp is ENetMultiplayerPeer and sender in multiplayer.get_peers():
				(mp as ENetMultiplayerPeer).disconnect_peer(sender))

@rpc("authority", "call_remote", "reliable")
func _hello_reply(ok: bool, in_world: bool) -> void:
	_hello_t = -1.0
	if not ok:
		_fail("version")
		return
	connected_ok.emit()
	if in_world:
		world_ready.emit()

@rpc("authority", "call_remote", "reliable")
func _host_world_ready() -> void:
	world_ready.emit()

# ------------------------------------------------------------------ cliente
func join(code: String) -> Error:
	# También acepta una IP o nombre directo (útil con redes virtuales como Radmin VPN, ZeroTier o Tailscale)
	var raw := code.strip_edges()
	if raw.contains("."):
		var parts := raw.split(":")
		var port := int(parts[1]) if parts.size() == 2 and parts[1].is_valid_int() else PORT
		return join_ip(parts[0], port)
	var target := decode(raw)
	if target.is_empty():
		return ERR_INVALID_PARAMETER
	return join_ip(target.ip, target.port)

func join_ip(ip: String, port := PORT) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	online = true
	is_host = false
	_connect_t = 0.0
	return OK

func close() -> void:
	_connect_t = -1.0
	_hello_t = -1.0
	_bc = null
	host_in_world = false
	_upnp_gen += 1
	if online and is_host and upnp_ok and _upnp:
		# borrar el mapeo es una llamada de red: nunca en el hilo principal
		var u := _upnp
		_start_thread(func() -> void: u.delete_port_mapping(PORT, "UDP"))
	_upnp = null
	upnp_ok = false
	if multiplayer.multiplayer_peer and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	online = false
	is_host = false

func _fail(reason: String) -> void:
	close()
	connect_failed.emit(reason)

func _on_failed() -> void:
	_fail("timeout")

func _on_server_gone() -> void:
	close()
	host_closed.emit()

func _exit_tree() -> void:
	close()
	lan_listen_stop()
	for th in _threads:
		if th.is_started():
			th.wait_to_finish()
	_threads.clear()

# ------------------------------------------------------------------ red local: anuncio y búsqueda
func _broadcast() -> void:
	var nm: String = str(G.look.get("name", "Desplumado"))
	var data := JSON.stringify({"g": "SERAPHALL", "v": PROTOCOL, "n": nm.substr(0, 16), "p": PORT, "full": has_partner()}).to_utf8_buffer()
	for dest in _broadcast_targets():
		if _bc.set_dest_address(dest, LAN_PORT) == OK:
			_bc.put_packet(data)

func _broadcast_targets() -> Array:
	var out := ["255.255.255.255", "127.0.0.1"]
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254"):
			var p := a.split(".")
			out.append("%s.%s.%s.255" % [p[0], p[1], p[2]])
	return out

func lan_listen_start() -> void:
	lan_listen_stop()
	lan_games.clear()
	_listen = PacketPeerUDP.new()
	if _listen.bind(LAN_PORT) != OK:
		_listen = null

func lan_listen_stop() -> void:
	if _listen:
		_listen.close()
		_listen = null

func _poll_lan() -> void:
	var changed := false
	var now := Time.get_ticks_msec()
	while _listen.get_available_packet_count() > 0:
		var pkt := _listen.get_packet()
		var ip := _listen.get_packet_ip()
		var d: Variant = JSON.parse_string(pkt.get_string_from_utf8())
		if d is Dictionary and d.get("g", "") == "SERAPHALL" and int(d.get("v", 0)) == PROTOCOL and not bool(d.get("full", false)):
			if not lan_games.has(ip):
				changed = true
			lan_games[ip] = {"name": str(d.get("n", "?")), "port": int(d.get("p", PORT)), "seen": now}
	for ip2 in lan_games.keys():
		if now - int(lan_games[ip2].seen) > 3500:
			lan_games.erase(ip2)
			changed = true
	if changed:
		lan_games_changed.emit()

# ------------------------------------------------------------------ códigos
func encode(ip: String, port := PORT) -> String:
	var parts := ip.split(".")
	if parts.size() != 4:
		return ""
	var v := 0
	for p in parts:
		v = (v << 8) | (int(p) & 255)
	v = (v << 16) | (port & 0xFFFF)  # 48 bits
	var s := ""
	for i in 10:  # 10 * 5 = 50 bits
		s = ALPHA[v & 31] + s
		v >>= 5
	return s.substr(0, 5) + "-" + s.substr(5, 5)

func decode(code: String) -> Dictionary:
	var c := code.strip_edges().to_upper().replace("-", "").replace(" ", "")
	if c.length() != 10:
		return {}
	var v := 0
	for ch in c:
		var i := ALPHA.find(ch)
		if i < 0:
			return {}
		v = (v << 5) | i
	var port := v & 0xFFFF
	v >>= 16
	if port == 0:
		return {}
	var ip := "%d.%d.%d.%d" % [(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255]
	return {"ip": ip, "port": port}

func online_code() -> String:
	return encode(external_ip) if external_ip != "" else ""

func lan_code() -> String:
	return encode(local_ip) if local_ip != "" else ""

func _is_private_ip(ip: String) -> bool:
	var p := ip.split(".")
	if p.size() != 4:
		return true
	var a := int(p[0])
	var b := int(p[1])
	return a == 10 or a == 127 or (a == 192 and b == 168) or (a == 172 and b >= 16 and b <= 31) or (a == 100 and b >= 64 and b <= 127) or (a == 169 and b == 254)

func _find_local_ip() -> String:
	## Elige el adaptador real: VirtualBox, WSL, Hyper-V o VMware dan códigos con los que nadie puede conectar
	var best := ""
	var best_score := -1
	for itf in IP.get_local_interfaces():
		var nm: String = (str(itf.get("friendly", "")) + " " + str(itf.get("name", ""))).to_lower()
		for a: String in itf.get("addresses", []):
			if a.count(".") != 3 or a.begins_with("127.") or a.begins_with("169.254"):
				continue
			var sc := 1
			if a.begins_with("192.168."):
				sc = 4
			elif a.begins_with("10."):
				sc = 3
			elif a.begins_with("172."):
				sc = 2
			if a.begins_with("192.168.56.") or a.begins_with("192.168.137."):
				sc = 1
			for bad in ["virtual", "vmware", "vbox", "hyper-v", "vethernet", "wsl", "docker", "bluetooth", "loopback", "tap", "tun"]:
				if nm.contains(bad):
					sc = 0
			if sc > best_score:
				best_score = sc
				best = a
	if best != "":
		return best
	for a2 in IP.get_local_addresses():
		if a2.count(".") == 3 and not a2.begins_with("127."):
			return a2
	return "127.0.0.1"
