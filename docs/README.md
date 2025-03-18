# Documentation for developers

MAIN INDEX


- ## Javascript-webview communication

  Refer to the [specific documentation](./webview/webview-handlers.md).
  
  From JS code, you can communicate with the native (Flutter) side of Torn PDA, which offers some additional capabilities (such as notifications) and also helps to overcome restrictions imposed by Torn (such as cross-origin http requests).
<br></br>
- ## GM support for PDA

  As a general rule, Torn PDA supports standard Javascript and jQuery, but it does not include any external libraries that are served in frameworks such as GM or TM. 

  However, you can refer to this [script](https://github.com/Manuito83/torn-pda/blob/master/userscripts/GMforPDA.user.js) which incorporates handlers to make life easier when converting scripts, supporting dot notation (e.g.: 'GM.addStyle') and underscore notation (e.g.: 'GM\_addStyle'). Please note that, while this script and functionality are still under development, it is an advanced version of some [pre-existing handlers ](https://github.com/Manuito83/torn-pda/blob/a3e58b591317cf41b557072745a7ee20033e4908/lib/utils/js_handlers.dart#L178)which were incorporated natively to the app long ago; adding the newest version (via script) on top of the basic handlers that come with Torn PDA should be no problem, as the former will overwrite the latter.

  Whilst these handlers supply vanilla JS counterparts to the GM_ functions, they cannot prepare your script to run on mobile devices: viewports are different, the page looks different, some selectors change, etcetera. So even if using these handlers, be prepared to adapt your script as necessary.



