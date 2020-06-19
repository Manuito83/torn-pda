import 'package:universal_html/html.dart' as html;

class HtmlParser {
  static String parse(String htmlString) {
    var text = html.Element.span()..appendHtml(htmlString);
    return text.innerText;
  }
}