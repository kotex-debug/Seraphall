extends Node
## Red: cooperativo de 2 jugadores con código de partida.
## El código codifica IP + puerto en base32 (sin servidores externos).
## El anfitrión intenta abrir el puerto con UPnP; también hay código LAN.

signal peer_joined(id: int)
signal peer_left(id: int)
signal connected_ok
signal connect_failed
signal host_closed
signal upnp_done(ok: bool, external_ip: String)

const PORT := 24680
const MAX_PEERS := 1  # anfitrión + 1 = 2 jugadores
const ALPHA := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # sin 0/O/1/I

var online := false
var is_host := false
var external_ip := ""
var local_ip := ""
var upnp_ok := false
var _upnp: UPNP
var _upnp_thread: Thread

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(func(id): peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id): peer_left.emit(id))
	multiplayer.connected_to_server.connect(func(): connected_ok.emit())
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)
	local_ip = _find_local_ip()

func is_online() -> bool:
	return online

func my_id() -> int:
	return multiplayer.get_unique_id()

func peers() -> PackedInt32Array:
	return multiplayer.get_peers()

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
	_upnp_thread = Thread.new()
	_upnp_thread.start(_upnp_setup)
	return OK

func _upnp_setup() -> void:
	_upnp = UPNP.new()
	var ok := false
	var ip := ""
	if _upnp.discover(2000, 2) == UPNP.UPNP_RESULT_SUCCESS and _upnp.get_gateway() and _upnp.get_gateway().is_valid_gateway():
		var r1 := _upnp.add_port_mapping(PORT, PORT, "Seraphall", "UDP")
		ip = _upnp.query_external_address()
		ok = r1 == UPNP.UPNP_RESULT_SUCCESS and ip != ""
	call_deferred("_upnp_finished", ok, ip)

func _upnp_finished(ok: bool, ip: String) -> void:
	if _upnp_thread:
		_upnp_thread.wait_to_finish()
		_upnp_thread = null
	upnp_ok = ok
	external_ip = ip
	upnp_done.emit(ok, ip)

# ------------------------------------------------------------------ cliente
func join(code: String) -> Error:
	close()
	var target := decode(code)
	if target.is_empty():
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(target.ip, target.port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	online = true
	is_host = false
	return OK

func join_ip(ip: String, port := PORT) -> Error:
	close()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	online = true
	is_host = false
	return OK

func close() -> void:
	if online and is_host and upnp_ok and _upnp:
		_upnp.delete_port_mapping(PORT, "UDP")
	if multiplayer.multiplayer_peer and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	online = false
	is_host = false

func _on_failed() -> void:
	close()
	connect_failed.emit()

func _on_server_gone() -> void:
	close()
	host_closed.emit()

func _exit_tree() -> void:
	close()

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
	c = c.replace("0", "O").replace("1", "I")
	if c.length() != 10:
		# también se admite escribir una IP directamente
		if code.count(".") == 3:
			return {"ip": code.strip_edges(), "port": PORT}
		return {}
	var v := 0
	for ch in c:
		var i := ALPHA.find(ch)
		if i < 0:
			return {}
		v = (v << 5) | i
	var port := v & 0xFFFF
	v >>= 16
	var ip := "%d.%d.%d.%d" % [(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255]
	return {"ip": ip, "port": port}

func online_code() -> String:
	return encode(external_ip) if external_ip != "" else ""

func lan_code() -> String:
	return encode(local_ip) if local_ip != "" else ""

func _find_local_ip() -> String:
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254"):
			if a.begins_with("192.168.") or a.begins_with("10.") or a.begins_with("172."):
				return a
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127."):
			return a
	return "127.0.0.1"
