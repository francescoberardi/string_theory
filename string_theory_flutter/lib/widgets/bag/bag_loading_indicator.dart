import 'package:flutter/material.dart';

import '../../theme/court_midnight_theme.dart';

/// Centered spinner shown while the bag is loading.
class BagLoadingIndicator extends StatelessWidget {
  const BagLoadingIndicator({super.key});

  static const keyLoadingIndicator = Key('virtual_bag_loading_indicator');

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        key: keyLoadingIndicator,
        color: CourtMidnightTheme.primaryVolt,
      ),
    );
  }
}
