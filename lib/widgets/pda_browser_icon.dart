import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_provider.dart';
import 'package:torn_pda/widgets/status_color_counter.dart';

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

    return SizedBox(
      width: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Consumer<ChainStatusProvider>(
            builder: (context, provider, child) {
              if (provider.statusColorWidgetEnabled) return StatusColorCounter();
              return SizedBox.shrink();
            },
          ),
          GestureDetector(
            child: Image.asset('images/icons/torn_pda_browser.png', width: 25),
            onTap: () {
              context.read<WebViewProvider>().pdaIconActivation(
                    shortTap: true,
                    automaticLogin: automaticLogins,
                    context: context,
                  );

              // When the browser opens, the player color status update needs to occur directly from the provider
              // as other sections action as source (e.g.: Profile) might have stopped their calls
              context.read<ChainStatusProvider>().statusUpdateSource = "provider";
            },
            onLongPress: () {
              context.read<WebViewProvider>().pdaIconActivation(
                    shortTap: false,
                    automaticLogin: automaticLogins,
                    context: context,
                  );

              context.read<ChainStatusProvider>().statusUpdateSource = "provider";
            },
          ),
        ],
      ),
    );
  }
}
