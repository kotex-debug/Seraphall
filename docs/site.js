// Sin JavaScript la web se lee entera: todo esto solo añade interacción encima.
(function () {
  "use strict";
  var root = document.documentElement;
  root.classList.add("js");
  var calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var $ = function (s, el) { return (el || document).querySelector(s); };
  var $$ = function (s, el) { return Array.prototype.slice.call((el || document).querySelectorAll(s)); };

  // --- portada: brasas que suben y plumas que caen
  var fx = $(".fx");
  if (fx && !calm) {
    for (var i = 0; i < 26; i++) {
      var e = document.createElement("i");
      e.className = "ember";
      e.style.left = Math.random() * 100 + "%";
      e.style.setProperty("--dx", (Math.random() * 120 - 60) + "px");
      e.style.animationDuration = 7 + Math.random() * 9 + "s";
      e.style.animationDelay = -Math.random() * 16 + "s";
      fx.appendChild(e);
    }
    for (var k = 0; k < 7; k++) {
      var f = document.createElement("img");
      f.className = "fall px";
      f.src = "img/sprites/icon_feather.png";
      f.alt = "";
      f.style.left = Math.random() * 100 + "%";
      f.style.setProperty("--dx", (Math.random() * 180 - 90) + "px");
      f.style.animationDuration = 12 + Math.random() * 12 + "s";
      f.style.animationDelay = -Math.random() * 24 + "s";
      fx.appendChild(f);
    }
  }

  // --- la película: botones de avance
  var film = $(".film");
  if (film) {
    $$(".film-nav button").forEach(function (b) {
      b.addEventListener("click", function () {
        var step = film.firstElementChild.getBoundingClientRect().width + 20;
        film.scrollBy({ left: step * Number(b.dataset.dir), behavior: calm ? "auto" : "smooth" });
      });
    });
  }

  // --- las plumas: mismas reglas que en el juego (README, "Las plumas")
  var wings = $(".wings");
  if (wings) {
    var box = $(".angel", wings);
    var ring = [];
    // cinco plumas por ala, abiertas hacia arriba como en el sprite
    [-118, -98, -78, -58, -38, 38, 58, 78, 98, 118].forEach(function (a) {
      var b = document.createElement("span");
      b.className = "feather";
      b.setAttribute("aria-hidden", "true");
      b.style.setProperty("--a", a + "deg");
      b.style.setProperty("--t", (a < 0 ? -28 : 28) + "deg");
      b.innerHTML = '<img class="px" src="img/sprites/icon_feather.png" alt="">';
      box.appendChild(b);
      ring.push(b);
    });
    var n = 10;
    var order = [9, 0, 8, 1, 7, 2, 6, 3, 5, 4];
    var num = $(".count b", wings), state = $(".state", wings), note = $(".note", wings), mark = $(".scale i", wings);
    var lose = $("[data-act=lose]", wings), gain = $("[data-act=gain]", wings);
    var paint = function () {
      num.textContent = n;
      ring.forEach(function (b, idx) { b.classList.toggle("gone", order.indexOf(idx) >= n); });
      var t;
      if (n === 0) t = ["Sin una pluma", "Modo Desplumado. Ya no te queda nada que ofrecer: las Brasas se encienden gratis."];
      else if (n <= 3) t = ["Modo Desplumado", "Más daño y más velocidad, pero menos vida. La balanza del destino se inclina hacia el Trono."];
      else if (n >= 7) t = ["Alas Abiertas", "Conservar siete o más plumas inclina la balanza del destino hacia las Alas."];
      else t = ["Entre dos finales", "La balanza no se mueve. Encender la próxima Brasa te costará otra pluma."];
      state.textContent = t[0];
      note.textContent = t[1];
      mark.style.setProperty("--s", n >= 7 ? "82%" : n <= 3 ? "18%" : "50%");
      wings.classList.toggle("low", n <= 3);
      lose.disabled = n === 0;
      gain.disabled = n === 10;
    };
    lose.addEventListener("click", function () { if (n > 0) { n--; paint(); } });
    gain.addEventListener("click", function () { if (n < 10) { n++; paint(); } });
    $(".actions", wings).hidden = false;
    paint();
  }

  // --- el arsenal: una pestaña por arma
  var racks = $$(".rack");
  if (racks.length) {
    var pick = function (r, focus) {
      racks.forEach(function (x) {
        var on = x === r;
        x.setAttribute("aria-selected", on ? "true" : "false");
        x.tabIndex = on ? 0 : -1;
        $("#" + x.getAttribute("aria-controls")).hidden = !on;
      });
      if (focus) r.focus();
    };
    var cols = function () { return getComputedStyle(r0.parentNode).gridTemplateColumns.split(" ").length; };
    var r0 = racks[0];
    racks.forEach(function (r, idx) {
      r.addEventListener("click", function () { pick(r); });
      r.addEventListener("keydown", function (ev) {
        var d = { ArrowRight: 1, ArrowLeft: -1, ArrowDown: cols(), ArrowUp: -cols() }[ev.key];
        if (!d) return;
        ev.preventDefault();
        pick(racks[(idx + d + racks.length) % racks.length], true);
      });
    });
    pick(racks[0]);
  }

  // --- banda sonora: una pista cada vez
  var tracks = $$(".track");
  var player = tracks.length ? new Audio() : null;
  if (player && player.canPlayType("audio/ogg")) {
    player.preload = "none";
    var current = null;
    var stop = function () { if (current) current.setAttribute("aria-pressed", "false"); current = null; };
    player.addEventListener("ended", stop);
    tracks.forEach(function (t) {
      t.addEventListener("click", function () {
        if (current === t) { player.pause(); stop(); return; }
        stop();
        current = t;
        t.setAttribute("aria-pressed", "true");
        player.src = t.dataset.src;
        player.play().catch(stop);
      });
    });
  } else if (tracks.length) {
    $(".ost").hidden = true;
  }

  // --- altímetro: por qué Círculo de la Espiral vas al bajar la página
  var alti = $(".alti");
  if (alti) {
    var label = $("span", alti), timer = 0, queued = false;
    var measure = function () {
      queued = false;
      var max = document.documentElement.scrollHeight - innerHeight;
      var p = max > 0 ? Math.min(1, scrollY / max) : 0;
      alti.style.setProperty("--p", p.toFixed(4));
      label.textContent = "Círculo " + Math.max(1, Math.round(p * 100));
      alti.classList.add("on");
      clearTimeout(timer);
      timer = setTimeout(function () { alti.classList.remove("on"); }, 900);
    };
    addEventListener("scroll", function () { if (!queued) { queued = true; requestAnimationFrame(measure); } }, { passive: true });
  }

  // --- aparición por escalones
  var rv = $$(".rv");
  if (rv.length && "IntersectionObserver" in window && !calm) {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); } });
    }, { rootMargin: "0px 0px -8% 0px" });
    rv.forEach(function (el) { io.observe(el); });
  } else {
    rv.forEach(function (el) { el.classList.add("in"); });
  }

  // --- versión y tamaño reales de la última publicación (si falla, queda el texto de la página)
  if (window.fetch) {
    fetch("https://api.github.com/repos/kotex-debug/Seraphall/releases/latest").then(function (r) {
      return r.ok ? r.json() : null;
    }).then(function (rel) {
      if (!rel || !rel.tag_name) return;
      var zip = (rel.assets || []).filter(function (a) { return a.name === "Seraphall-Windows.zip"; })[0];
      $$("[data-version]").forEach(function (el) { el.textContent = rel.tag_name; });
      if (zip) $$("[data-size]").forEach(function (el) { el.textContent = Math.round(zip.size / 1e6) + " MB"; });
    }).catch(function () {});
  }
})();
