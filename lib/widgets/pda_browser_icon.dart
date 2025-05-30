import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_provider.dart';
import 'package:torn_pda/widgets/status_color_counter.dart';

class PdaBrowserIcon extends StatelessWidget {
  final Color? color;

  const PdaBrowserIcon({
    this.color,
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
          GetBuilder<ChainStatusController>(
            builder: (provider) {
              if (provider.statusColorWidgetEnabled) return const StatusColorCounter();
              return const SizedBox.shrink();
            },
          ),
          GestureDetector(
            child: Image.asset(
              'images/icons/torn_pda_browser.png',
              width: 25,
              color: color,
            ),
            onTap: () {
              context.read<WebViewProvider>().pdaIconActivation(
                    shortTap: true,
                    automaticLogin: automaticLogins,
                    context: context,
                  );

              // When the browser opens, the player color status update needs to occur directly from the provider
              // as other sections action as source (e.g.: Profile) might have stopped their calls
              Get.find<ChainStatusController>().statusUpdateSource = "provider";
            },
            onLongPress: () {
              context.read<WebViewProvider>().pdaIconActivation(
                    shortTap: false,
                    automaticLogin: automaticLogins,
                    context: context,
                  );

              Get.find<ChainStatusController>().statusUpdateSource = "provider";
            },
          ),
        ],
      ),
    );
  }
}
