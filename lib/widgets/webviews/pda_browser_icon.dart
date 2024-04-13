import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_provider.dart';

class PdaBrowserIcon extends StatelessWidget {
  const PdaBrowserIcon({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    WebViewProvider webviewProvider = Provider.of<WebViewProvider>(context);

    final bool automaticLogins = context.read<NativeAuthProvider>().tryAutomaticLogins;

    if (webviewProvider.webViewSplitActive) {
      return Container();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Container(
            color: Colors.red[700],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 3),
              child: Text(
                "08:20",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
        GestureDetector(
          child: Image.asset(
            'images/icons/torn_pda_browser.png',
            width: 25,
          ),
          onTap: () {
            context.read<WebViewProvider>().pdaIconActivation(
                  shortTap: true,
                  automaticLogin: automaticLogins,
                  context: context,
                );
          },
          onLongPress: () {
            context.read<WebViewProvider>().pdaIconActivation(
                  shortTap: false,
                  automaticLogin: automaticLogins,
                  context: context,
                );
          },
        ),
      ],
    );
  }
}
