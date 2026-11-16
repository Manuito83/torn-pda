class ChatYoutube {
  ChatYoutube._();

  // Without it, error 153
  static const String origin = 'https://www.tornpda.com';

  /// [videoId] must be 11 safe characters
  static String page(String videoId) =>
      '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="referrer" content="strict-origin-when-cross-origin">
<style>html,body{margin:0;height:100%;background:#000;overflow:hidden}#p{width:100%;height:100%}</style>
</head>
<body>
<div id="p"></div>
<script>
function tell(o) { try { window.flutter_inappwebview.callHandler('pdaYoutube', o); } catch (e) {} }
var api = document.createElement('script');
api.src = 'https://www.youtube.com/iframe_api';
api.onerror = function () { tell({ state: 'error', code: 0 }); };
document.head.appendChild(api);
function onYouTubeIframeAPIReady() {
  new YT.Player('p', {
    host: 'https://www.youtube-nocookie.com',
    videoId: '$videoId',
    playerVars: { autoplay: 1, playsinline: 1, rel: 0, origin: '$origin' },
    events: {
      onReady: function (e) { tell({ state: 'ready' }); e.target.playVideo(); },
      onError: function (e) { tell({ state: 'error', code: e.data }); },
    },
  });
}
</script>
</body>
</html>
''';
}
