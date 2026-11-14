const String blankProbeJs = r"""
(function () {
  var style = document.createElement('style');
  style.textContent = '* { pointer-events: auto !important; }';
  document.documentElement.appendChild(style);
  var vv = window.visualViewport;
  var w = vv ? vv.width : window.innerWidth, h = vv ? vv.height : window.innerHeight;
  var ox = vv ? vv.offsetLeft : 0, oy = vv ? vv.offsetTop : 0;
  var xs = [0.25, 0.75], ys = [0.1, 0.3, 0.5, 0.7, 0.9], points = [];
  for (var j = 0; j < ys.length; j++) {
    for (var i = 0; i < xs.length; i++) {
      var el = document.elementsFromPoint(ox + xs[i] * w, oy + ys[j] * h)[0], color = null;
      if (el && !/^(img|canvas|video|iframe|svg)$/i.test(el.tagName)) {
        for (var e = el; e; e = e.parentElement) {
          var m = getComputedStyle(e).backgroundColor.match(/[\d.]+/g);
          if (m && (m.length < 4 || parseFloat(m[3]) > 0)) {
            color = [+m[0], +m[1], +m[2]];
            break;
          }
        }
      }
      points.push([xs[i], ys[j], color]);
    }
  }
  style.remove();
  var sim = window.__pdaSimulateBlank | 0;
  if (sim > 0) window.__pdaSimulateBlank = sim - 1;
  return JSON.stringify({
    ready: document.readyState,
    text: document.body ? document.body.textContent.length : 0,
    points: points,
    sim: sim
  });
})();
""";
