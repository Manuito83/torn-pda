import 'package:torn_pda/config/webview_config.dart';

bool isTornHost(String? host) => host == 'torn.com' || (host ?? '').endsWith('.torn.com');

bool isTornUrl(String? url) => isTornHost(Uri.tryParse(url ?? '')?.host);

String get webviewUserAgentSuffix {
  const unknown = '##deviceBrand=unknown##deviceModel=unknown##deviceSoftware=unknown##';
  final device = WebviewConfig.userAgentForUser.isNotEmpty ? WebviewConfig.userAgentForUser : unknown;
  return '${WebviewConfig.agent} $device'.trim();
}
