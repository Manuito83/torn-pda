import 'package:flutter/material.dart';

String easyCrimesJS({
  @required String nerve,
  @required String crime,
  @required String doCrime,
}) {
  return '''
    var first_load = true;
    
    if (first_load) {
      var loadingPlaceholderContent = `
        <div class="content-title m-bottom10">
          <h4 class="left">Crimes</h4>
          <hr class="page-head-delimiter">
          <div class="clear"></div>
        </div>`
        
      first_load = false;
    }
    
    loadingPlaceholderContent += `<img class="ajax-placeholder" src="/images/v2/main/ajax-loader.gif"/>`;
    
    window.location.hash = "#";
    \$(".content-wrapper").html(loadingPlaceholderContent);
    
    var action = 'https://www.torn.com/crimes.php?step=docrime$doCrime&timestamp=' + Date.now();
    
    ajaxWrapper({
      url: action,
      type: 'POST',
      data: 'nervetake=$nerve&crime=$crime',
      oncomplete: function(resp) {
        \$(".content-wrapper").html(resp.responseText);
      },
      onerror: function(e) {
        console.error(e)
      }
    });
  ''';
}
