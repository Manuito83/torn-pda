class HtmlParser {
  static String parse(String htmlString) {
    RegExp expHtml = RegExp(r"<[^>]*>");
    var matches = expHtml.allMatches(htmlString).map((m) => m[0]);
    for (var m in matches) {
      htmlString = htmlString.replaceAll(m, '');
    }
    return htmlString;
  }
}
