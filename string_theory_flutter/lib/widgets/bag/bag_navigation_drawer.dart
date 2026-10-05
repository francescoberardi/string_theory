import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Persistent side navigation drawer for desktop / web (>1024dp):
/// Bag, Sessions, Account.
class BagNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const BagNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const keyNavigationDrawer = Key('virtual_bag_navigation_drawer');

  @override
  Widget build(BuildContext context) {
    return Container(
      key: keyNavigationDrawer,
      width: 240,
      decoration: const BoxDecoration(
        color: CourtMidnightTheme.surface,
        border: Border(
          right: BorderSide(
            color: CourtMidnightTheme.surfaceBorder,
            width: 1,
          ),
        ),
      ),
      child: NavigationDrawerTheme(
        data: NavigationDrawerThemeData(
          backgroundColor: CourtMidnightTheme.surface,
          indicatorColor: CourtMidnightTheme.primaryVolt.withValues(
            alpha: 0.15,
          ),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return GoogleFonts.barlowCondensed(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? CourtMidnightTheme.primaryVolt
                  : CourtMidnightTheme.textSecondary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: isSelected
                  ? CourtMidnightTheme.primaryVolt
                  : CourtMidnightTheme.textSecondary,
            );
          }),
        ),
        child: NavigationDrawer(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: CourtMidnightTheme.surface,
          elevation: 0,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.sports_tennis,
                    color: CourtMidnightTheme.primaryVolt,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'STRING THEORY',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlowCondensed(
                        color: CourtMidnightTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: CourtMidnightTheme.surfaceBorder,
            ),
            const SizedBox(height: 12),
            const NavigationDrawerDestination(
              icon: Icon(Icons.sports_tennis),
              label: Text('Bag'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.history),
              label: Text('Sessions'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              label: Text('Account'),
            ),
          ],
        ),
      ),
    );
  }
}
