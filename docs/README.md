# Documentation for developers

Main index:
- [Javascript-webview communication](./webview/webview-handlers.md)

  From JS code, you can communicate with the native (Flutter) side of Torn PDA, which offers some additional capabilities (such as notifications) and also helps to overcome restrictions imposed by Torn (such as cross-origin http requests).
<br></br>
- [GM for PDA](https://github.com/Manuito83/torn-pda/blob/master/userscripts/GMforPDA.user.js)

  As a general rule, Torn PDA supports standard Javascript and jQuery, but it does not include any external libraries that are served in frameworks such as GM or TM. 

  However, Torn PDA incorporates basic GM handlers to make life easier when converting scripts, supporting dot notation (e.g.: 'GM.addStyle') and underscore notation (e.g.: 'GM_addStyle').

  Whilst these handlers supply vanilla JS counterparts to the GM_ functions, they cannot prepare your script to run on mobile devices: viewports are different, the page looks different, some selectors change, etcetera. So even if using these handlers, be prepared to adapt your script as necessary.



