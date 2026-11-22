import 'package:torn_pda/utils/js_snippets/remote_snippets.dart';

const cityMapEarlyHideGroup = '__TornPDA_CityMapEarlyHide__';

const _pauseStyleId = 'pda-city-pause';
const _pauseCss = '.leaflet-container{visibility:hidden !important;touch-action:pan-y !important;isolation:isolate}';

// Torn's map back if no answer
const _earlyHideRescueMs = 15000;

// city_map_early_hide base, runs at document start
// RC keys: snippet_city_map_early_hide_js + snippet_city_map_early_hide_version
String cityMapEarlyHideBaseJS() {
  return '''
    (function() {
      const host = location.hostname;
      if (location.pathname !== '/city.php' || (host !== 'torn.com' && !host.endsWith('.torn.com'))) return;
      const style = document.createElement('style');
      style.id = '$_pauseStyleId';
      style.textContent = '$_pauseCss';
      function attach() { (document.head || document.documentElement).appendChild(style); }
      if (document.documentElement) {
        attach();
      } else {
        new MutationObserver(function(_, observer) {
          if (!document.documentElement) return;
          observer.disconnect();
          attach();
        }).observe(document, { childList: true });
      }
      setTimeout(function() {
        if (window._pdaCityMapPaused === undefined) style.remove();
      }, $_earlyHideRescueMs);
    })();
  ''';
}

// city_map_clean base, reads window._pdaCityMapClean
// RC keys: snippet_city_map_clean_js + snippet_city_map_clean_version
String cityMapCleanBaseJS() {
  return '''
    (function() {
      const map = (window.torn && window.torn.map) ? window.torn.map.lmap : null;
      if (!map) return "NOT_READY";

      function layerKind(l) {
        const o = l.options;
        if (!o) return null;
        if (o.tcmap && o.db_id !== undefined) return 'territory';
        if (o.iconUrls && o.iconUrls[0] && String(o.iconUrls[0]).indexOf('/rackets_png/') > -1) return 'racket';
        return null;
      }

      function setLayerHidden(l, hidden) {
        try {
          const kind = layerKind(l);
          if (!kind) return;
          const o = l.options;
          if (hidden) {
            if (!l._pdaClean) l._pdaClean = { fill: o.fill, stroke: o.stroke, interactive: o.interactive, zoomStart: o.zoomStart };
            o.interactive = false;
            if (kind === 'territory') {
              l.setStyle({ fill: false, stroke: false });
            } else {
              o.zoomStart = 99;
              l.redraw();
            }
          } else if (l._pdaClean) {
            const saved = l._pdaClean;
            delete l._pdaClean;
            o.interactive = saved.interactive;
            if (kind === 'territory') {
              l.setStyle({ fill: saved.fill, stroke: saved.stroke });
            } else {
              o.zoomStart = saved.zoomStart;
              l.redraw();
            }
          }
        } catch (e) {}
      }

      // Also hide layers Torn adds later
      if (!map._pdaCleanBound) {
        map._pdaCleanBound = true;
        map.on('layeradd', function(e) { setLayerHidden(e.layer, window._pdaCityMapClean === true); });
      }

      const hide = window._pdaCityMapClean === true;
      map.eachLayer(function(l) { setLayerHidden(l, hide); });
      if (hide) map.closePopup();
      return hide ? "HIDDEN" : "SHOWN";
    })();
  ''';
}

// city_map_data base: owners, rackets, sites and items as JSON
// RC keys: snippet_city_map_data_js + snippet_city_map_data_version
String cityMapDataBaseJS() {
  return '''
    (function() {
      const map = (window.torn && window.torn.map) ? window.torn.map.lmap : null;
      const data = (window.torn && window.torn.model) ? window.torn.model.__data : null;
      if (!map || !data) return "NOT_READY";
      const out = { time: 0, owners: {}, irradiated: [], rackets: {}, sites: [], items: [] };

      try { out.time = Number(data.currentTimeStamp) || Math.floor(Date.now() / 1000); } catch (e) {}

      const codes = {};
      try { data.territoriesShapes.forEach(function(r) { codes[r[1]] = r[6]; }); } catch (e) {}

      try {
        const terrs = data.terrCollectionById || {};
        Object.keys(terrs).forEach(function(id) {
          if (codes[id]) out.owners[codes[id]] = Number(terrs[id].factionID) || 0;
        });
      } catch (e) {}

      try {
        Object.keys(data.dirtyBombs || {}).forEach(function(id) {
          if (codes[id]) out.irradiated.push(codes[id]);
        });
      } catch (e) {}

      try {
        (data.rackets || []).forEach(function(r) {
          const code = codes[r.territoryID];
          if (code) out.rackets[code] = { name: String(r.name), level: Number(r.level) || 0, reward: String(r.description || '') };
        });
      } catch (e) {}

      try {
        (data.standardMapObjects || []).forEach(function(s) {
          if (s.link) out.sites.push({ title: String(s.title), link: String(s.link), x: Number(s.center_x), y: Number(s.center_y) });
        });
      } catch (e) {}

      // Same marker read as the City Finder
      try {
        map.eachLayer(function(l) {
          try {
            const o = l.options;
            if (!o || !o.iconUrls || !o.iconUrls[0] || typeof l.getLatLng !== 'function') return;
            const u = String(o.iconUrls[0]);
            const idx = u.indexOf('city_items/');
            if (idx < 0) return;
            const id = Number(u.substring(idx + 11).split('/')[0]);
            const ll = l.getLatLng();
            if (id) out.items.push({ id: id, lat: ll.lat, lng: ll.lng });
          } catch (e) {}
        });
      } catch (e) {}

      return JSON.stringify(out);
    })();
  ''';
}

// city_item_pick base, async function body with id, lat, lng
// Clicks Torn's own marker and reports Torn's panel
// RC keys: snippet_city_item_pick_js + snippet_city_item_pick_version
String cityItemPickBaseJS() {
  return '''
    const map = (window.torn && window.torn.map) ? window.torn.map.lmap : null;
    if (!map) return { status: 'error', text: "Torn's map is not ready" };

    let marker = null;
    map.eachLayer(function(l) {
      try {
        const o = l.options;
        if (marker || !o || !o.iconUrls || String(o.iconUrls[0]).indexOf('city_items/' + id + '/') < 0) return;
        const ll = l.getLatLng();
        if (Math.abs(ll.lat - lat) < 0.000001 && Math.abs(ll.lng - lng) < 0.000001) marker = l;
      } catch (e) {}
    });
    if (!marker) return { status: 'gone' };
    if (marker.wasSent) return { status: 'sent' };

    function panelText() {
      try {
        const el = map._popup && map._popup.getElement ? map._popup.getElement() : null;
        if (!el) return '';
        return el.textContent.split(String.fromCharCode(10)).map(function(s) { return s.trim(); }).filter(Boolean).join(' ');
      } catch (e) { return ''; }
    }

    marker.fire('click');
    return await new Promise(function(resolve) {
      let waited = 0;
      const timer = setInterval(function() {
        waited += 250;
        const text = panelText();
        let result = null;
        if (!map.hasLayer(marker)) result = { status: 'found', text: text };
        else if (text && text.indexOf('Loading') < 0) result = { status: 'error', text: text };
        else if (waited >= 15000) result = { status: 'timeout' };
        if (result) { clearInterval(timer); map.closePopup(); resolve(result); }
      }, 250);
    });
  ''';
}

// city_map_pause base, reads window._pdaCityMapPaused
// Hides Torn's map, unmaximized
// RC keys: snippet_city_map_pause_js + snippet_city_map_pause_version
String cityMapPauseBaseJS() {
  return '''
    (function() {
      const map = (window.torn && window.torn.map) ? window.torn.map.lmap : null;
      let style = document.getElementById('$_pauseStyleId');

      // Torn's switch, saved choice kept
      function fullMode(on) {
        try {
          const tcMap = window.torn.map;
          if (typeof tcMap.fullMapSwitch !== 'function' || tcMap.isFullMode === on) return;
          const key = 'is_full_screen_mode';
          const saved = localStorage.getItem(key);
          tcMap.fullMapSwitch(on);
          if (saved === null) localStorage.removeItem(key); else localStorage.setItem(key, saved);
        } catch (e) {}
      }

      if (window._pdaCityMapPaused === true) {
        if (map && window.torn.map.isFullMode === true) {
          window._pdaCityWasFull = true;
          fullMode(false);
        }
        if (!style) {
          style = document.createElement('style');
          style.id = '$_pauseStyleId';
          style.textContent = '$_pauseCss';
          document.head.append(style);
          window._pdaHlBefore = !!window._pdaCityHighlightHidden;
        }
        window._pdaCityHighlightHidden = true;
        window._pdaCityItemSig = null;
        if (window._pdaHlInterval) { clearInterval(window._pdaHlInterval); window._pdaHlInterval = null; }
        if (window._pdaHighlightLayer) window._pdaHighlightLayer.clearLayers();
      } else {
        if (style) {
          style.remove();
          window._pdaCityHighlightHidden = window._pdaHlBefore === true;
        }
        const hole = document.getElementById('pda-city-hole');
        if (hole) hole.remove();
        if (window._pdaCityWasFull === true) {
          window._pdaCityWasFull = false;
          fullMode(true);
        }
        if (map) map.invalidateSize();
      }
      return true;
    })();
  ''';
}

// city_map_hole base, async function body with picture
// False if the box fills the page
// RC keys: snippet_city_map_hole_js + snippet_city_map_hole_version
String cityMapHoleBaseJS() {
  return '''
    const map = (window.torn && window.torn.map) ? window.torn.map.lmap : null;
    if (!map) return false;
    const box = map.getContainer();
    const size = box.getBoundingClientRect();
    if (size.width >= window.innerWidth * 0.9 && size.height >= window.innerHeight * 0.85) return false;

    function button(text, action, main) {
      const b = document.createElement('button');
      b.textContent = text;
      b.style.cssText = 'border:0;border-radius:14px;cursor:pointer;color:#fff;font-size:12px;padding:6px 12px;' +
        (main ? 'background:#e67e00;font-weight:bold' : 'background:rgba(0,0,0,.65)');
      b.addEventListener('click', function(e) {
        e.stopPropagation();
        window.flutter_inappwebview.callHandler('PDA_cityMap', action);
      });
      return b;
    }

    // Bytes skip the page CSP
    async function draw(hole, picture) {
      const raw = atob(picture.substring(picture.indexOf(',') + 1));
      const bytes = new Uint8Array(raw.length);
      for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
      const bitmap = await createImageBitmap(new Blob([bytes], { type: 'image/png' }));
      let canvas = hole.querySelector('canvas');
      if (!canvas) {
        canvas = document.createElement('canvas');
        canvas.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;object-fit:cover';
        hole.insertBefore(canvas, hole.firstChild);
      }
      canvas.width = bitmap.width;
      canvas.height = bitmap.height;
      canvas.getContext('2d').drawImage(bitmap, 0, 0);
      bitmap.close();
    }

    let hole = document.getElementById('pda-city-hole');
    if (!hole) {
      hole = document.createElement('div');
      hole.id = 'pda-city-hole';
      hole.style.cssText = 'position:absolute;inset:0;z-index:1;visibility:visible;background:#2b2b2b;overflow:hidden';
      const buttons = document.createElement('div');
      buttons.style.cssText = 'position:absolute;left:8px;bottom:8px;display:flex;gap:8px';
      buttons.append(button('Open Map', 'open', true), button("Show Torn's map", 'torn', false));
      hole.append(buttons);
      hole.addEventListener('click', function(e) {
        e.stopPropagation();
        window.flutter_inappwebview.callHandler('PDA_cityMap', 'open');
      });
      ['mousedown', 'touchstart', 'pointerdown', 'dblclick', 'wheel'].forEach(function(name) {
        hole.addEventListener(name, function(e) { e.stopPropagation(); });
      });
      box.appendChild(hole);
    }
    if (picture) {
      try {
        await draw(hole, picture);
      } catch (e) {
        return false;
      }
    }
    return true;
  ''';
}

// city_map_rect base: box and page
// RC keys: snippet_city_map_rect_js + snippet_city_map_rect_version
String cityMapRectBaseJS() {
  return '''
    (function() {
      const map = (window.torn && window.torn.map) ? window.torn.map.lmap : null;
      if (!map) return "NOT_READY";
      const r = map.getContainer().getBoundingClientRect();
      return JSON.stringify({ x: r.left, y: r.top, w: r.width, h: r.height, vw: window.innerWidth, vh: window.innerHeight });
    })();
  ''';
}

// city_map_focus base, async function body with code
// Torn's link, plus the shape if drawn
// RC keys: snippet_city_map_focus_js + snippet_city_map_focus_version
String cityMapFocusBaseJS() {
  return '''
    const map = (window.torn && window.torn.map) ? window.torn.map.lmap : null;
    if (!map) return false;
    location.hash = 'terrName=' + code;
    map.getContainer().scrollIntoView({ block: 'center' });
    let id = null;
    try {
      window.torn.model.__data.territoriesShapes.forEach(function(r) { if (r[6] === code) id = r[1]; });
    } catch (e) {}
    let shape = null;
    map.eachLayer(function(l) {
      const o = l.options;
      if (o && o.tcmap && id !== null && o.db_id == id && typeof l.getBounds === 'function') shape = l;
    });
    if (shape) map.fitBounds(shape.getBounds());
    return shape !== null;
  ''';
}

String cityMapEarlyHideJS() => RemoteSnippets.resolve(RemoteSnippets.cityMapEarlyHide);

String cityMapCleanJS({required bool hidden}) {
  return 'window._pdaCityMapClean = $hidden;\n${RemoteSnippets.resolve(RemoteSnippets.cityMapClean)}';
}

String cityMapDataJS() => RemoteSnippets.resolve(RemoteSnippets.cityMapData);

String cityItemPickJS() => RemoteSnippets.resolve(RemoteSnippets.cityItemPick);

String cityMapPauseJS({required bool paused}) {
  return 'window._pdaCityMapPaused = $paused;\n${RemoteSnippets.resolve(RemoteSnippets.cityMapPause)}';
}

const cityMapArrivedJS = '!!window._pdaCityArrived;';

const cityMapFirstArrivalJS = '''
  (function() {
    const first = !window._pdaCityArrived;
    window._pdaCityArrived = true;
    return first;
  })();
''';

String cityMapHoleJS() => RemoteSnippets.resolve(RemoteSnippets.cityMapHole);

String cityMapRectJS() => RemoteSnippets.resolve(RemoteSnippets.cityMapRect);

String cityMapFocusJS() => RemoteSnippets.resolve(RemoteSnippets.cityMapFocus);
