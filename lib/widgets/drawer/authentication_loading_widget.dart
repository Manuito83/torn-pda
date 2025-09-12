import 'package:flutter/material.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class AuthenticationLoadingWidget extends StatefulWidget {
  final ThemeProvider themeProvider;
  final WebViewProvider webViewProvider;

  const AuthenticationLoadingWidget({
    super.key,
    required this.themeProvider,
    required this.webViewProvider,
  });

  @override
  State<AuthenticationLoadingWidget> createState() => _AuthenticationLoadingWidgetState();
}

class _AuthenticationLoadingWidgetState extends State<AuthenticationLoadingWidget> with TickerProviderStateMixin {
  late List<AnimationController> _waveControllers;
  late List<Animation<double>> _waveAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _waveControllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 1500 + (index * 200)),
        vsync: this,
      );
    });

    _waveAnimations = _waveControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();

    // Start animations with staggered delays
    for (int i = 0; i < _waveControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _waveControllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _waveControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Oops...',
          style: TextStyle(
            color: widget.themeProvider.mainText,
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 30),
        const CircularProgressIndicator(),
        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 0; i < 3; i++)
                    AnimatedBuilder(
                      animation: _waveAnimations[i],
                      builder: (context, child) {
                        return Container(
                          width: 20 + (_waveAnimations[i].value * (20 + i * 10)),
                          height: 20 + (_waveAnimations[i].value * (20 + i * 10)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.themeProvider.mainText.withValues(
                                alpha: (1.0 - _waveAnimations[i].value) * 0.5,
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  Icon(
                    Icons.cell_tower,
                    size: 28,
                    color: widget.themeProvider.mainText,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const Image(
                  image: AssetImage('images/icons/torn_pda.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            Text(
              'Retrieving server information...',
              style: TextStyle(
                color: widget.themeProvider.mainText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Text(
            "Please wait, Torn PDA can't locate your user details from the server. "
            "It will try for up to one minute",
            style: TextStyle(
              color: widget.themeProvider.mainText.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 30),

        // Access Torn button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              widget.webViewProvider.openBrowserPreference(
                context: context,
                url: 'https://www.torn.com',
                browserTapType: BrowserTapType.notification,
              );
            },
            icon: const Icon(Icons.language, size: 20),
            label: const Text(
              'Access Torn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 3,
            ),
          ),
        ),

        const SizedBox(height: 15),

        Text(
          'You can continue browsing while authentication completes',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.themeProvider.mainText.withValues(alpha: 0.6),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
