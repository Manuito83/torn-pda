// Project imports:
import 'package:torn_pda/models/userscript_model.dart';

// JS snippet that ships compiled, but a newer version from RC can replace it at runtime
class RemoteSnippet {
  final String id;
  final String version;
  final String Function() buildBase;

  const RemoteSnippet({required this.id, required this.version, required this.buildBase});
}

class _Override {
  final String version;
  final String js;
  const _Override(this.version, this.js);
}

// Things to avoid (so that it works when pasted into RC):
//   - no backticks / template strings
//       bad:  addStyle(`.x{color:red}`)
//       ok:   addStyle('.x{color:red}')
//   - no backslashes (so /\d/ style regex is out, but new RegExp('[0-9]') is fine)
//       bad:  url.match(/city_items\/(\d+)\//)[1]
//       ok:   url.match(new RegExp('city_items/([0-9]+)/'))[1]
//       ok:   url.substring(url.indexOf('city_items/') + 11).split('/')[0]
class RemoteSnippets {
  RemoteSnippets._();

  static const String cityItemsHighlight = 'city_items_highlight';

  static final Map<String, RemoteSnippet> _registry = {
    cityItemsHighlight: const RemoteSnippet(
      id: cityItemsHighlight,
      version: '1.0.0',
      buildBase: _cityItemsHighlightBaseJS,
    ),
  };

  static final Map<String, _Override> _overrides = {};

  // Registered ids; drawer reads snippet_<id>_js + snippet_<id>_version for each
  static Iterable<String> get ids => _registry.keys;

  // Store a per-snippet override; empty js or version clears it
  static void setOverride(String id, String version, String js) {
    if (version.trim().isEmpty || js.trim().isEmpty) {
      _overrides.remove(id);
    } else {
      _overrides[id] = _Override(version.trim(), js);
    }
  }

  // Override JS if it's newer than the base, else the compiled base
  static String resolve(String id) {
    final base = _registry[id];
    if (base == null) return '';
    if (usingOverride(id)) return _overrides[id]!.js;
    return base.buildBase();
  }

  // Is the RC override (not the base) the one in use for id
  static bool usingOverride(String id) {
    final base = _registry[id];
    if (base == null) return false;
    final over = _overrides[id];
    return over != null && over.js.isNotEmpty && UserScriptModel.isNewerVersion(over.version, base.version);
  }

  // city_items_highlight base
  static String _cityItemsHighlightBaseJS() {
    return '''
      (function() {
        function addStyle(css) {
          let s = document.getElementById('pda-cityitem-style');
          if (!s) { s = document.createElement('style'); s.id = 'pda-cityitem-style'; document.head.append(s); }
          s.textContent = css;
        }

        function getMap() {
          try {
            if (window.torn && window.torn.map && window.torn.map.lmap) return window.torn.map.lmap;
          } catch (e) {}
          return null;
        }

        // City items are the canvas markers whose icon points at /city_items/<id>/
        function collectItems(map) {
          const out = [];
          try {
            map.eachLayer(function(l) {
              try {
                const o = l.options;
                if (o && o.iconUrls && o.iconUrls[0] && typeof l.getLatLng === 'function') {
                  const u = String(o.iconUrls[0]);
                  const idx = u.indexOf('city_items/');
                  if (idx > -1) {
                    const id = u.substring(idx + 11).split('/')[0];
                    if (id && !isNaN(Number(id))) out.push({ marker: l, latlng: l.getLatLng(), id: id });
                  }
                }
              } catch (e) {}
            });
          } catch (e) {}
          return out;
        }

        function buildHighlights() {
          const map = getMap();
          if (!map || typeof L === 'undefined') return;

          const items = collectItems(map);
          const ids = items.map(function(it) { return it.id; });
          window._pdaCityItemIds = ids; // stashed for the return value below

          if (!window._pdaHighlightLayer) {
            window._pdaHighlightLayer = L.layerGroup().addTo(map);
          }
          const layer = window._pdaHighlightLayer;

          // Hidden via the widget toggle
          if (window._pdaCityHighlightHidden) { layer.clearLayers(); window._pdaCityItemSig = null; return; }

          // Only rebuild the rings when the set of items actually changed
          const sig = ids.join(',');
          if (sig === window._pdaCityItemSig) return;
          window._pdaCityItemSig = sig;
          layer.clearLayers();

          const SIZE = 40;
          for (let i = 0; i < items.length; i++) {
            try {
              const icon = L.divIcon({
                className: '',
                html: '<img class="pdaCityItemBig" src="/images/items/' + items[i].id + '/large.png">',
                iconSize: [SIZE, SIZE],
                iconAnchor: [SIZE / 2, SIZE / 2]
              });

              // Interactive so the whole 40px is clickable
              const canvasMarker = items[i].marker;
              L.marker(items[i].latlng, { icon: icon, interactive: true, keyboard: false, bubblingMouseEvents: false })
                .on('click', function() { try { canvasMarker.fire('click'); } catch (e) {} })
                .addTo(layer);
            } catch (e) {}
          }
        }

        // Exposed so the city widget show/hide button can toggle the overlay
        window._pdaSetCityHighlightHidden = function(hidden) {
          window._pdaCityHighlightHidden = !!hidden;
          window._pdaCityItemSig = null;
          buildHighlights();
        };

        addStyle('.pdaCityItemBig{box-sizing:border-box !important;display:block !important;width:40px !important;height:40px !important;object-fit:contain;border:3px dashed rgb(21 101 255);border-radius:50% !important;background:rgb(206 202 184 / 77%);box-shadow:0 0 6px 2px rgb(21 101 255 / 55%);padding:3px;cursor:pointer}');

        // Only start highlighting once the map is ready
        if (getMap() && typeof L !== 'undefined') {
          buildHighlights();
          if (window._pdaHlInterval) clearInterval(window._pdaHlInterval);
          window._pdaHlInterval = setInterval(buildHighlights, 2500);
        }

        // Single return for Flutter: the item ids, or NOT_READY while the map is still loading
        try {
          if (!(window.torn && window.torn.map && window.torn.map.lmap)) return "NOT_READY";
          return JSON.stringify(window._pdaCityItemIds || []);
        } catch (e) {
          return "NOT_READY";
        }
      })();
    ''';
  }
}

// city item highlighter (RC-overridable)
String highlightCityItemsJS() => RemoteSnippets.resolve(RemoteSnippets.cityItemsHighlight);
