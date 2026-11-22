import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/providers/faction_flights_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/territory_map/flights_globe.dart';

const flightsButtonSize = 52.0;
const _onAccent = Color(0xFF1B1200);

class FlightsButton extends StatelessWidget {
  const FlightsButton({super.key, required this.flights, required this.theme, required this.onTap});

  final FactionFlightsController flights;
  final ThemeProvider theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: flights,
      builder: (context, _) {
        final count = flights.flyingNow;
        return SizedBox.square(
          dimension: flightsButtonSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: theme.secondBackground,
                elevation: 6,
                shape: CircleBorder(side: BorderSide(color: theme.mainText.withValues(alpha: 0.2))),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: Tooltip(
                    message: 'Faction flights',
                    child: Center(child: Icon(Icons.public, size: 28, color: theme.mainText)),
                  ),
                ),
              ),
              if (flights.membersLoading)
                const Positioned(
                  top: -2,
                  right: -2,
                  child: SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: flightsTornColor),
                  ),
                )
              else if (flights.membersFailed || count != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: flights.membersFailed ? Colors.grey : flightsTornColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        flights.membersFailed ? '!' : '$count',
                        style: const TextStyle(color: _onAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
