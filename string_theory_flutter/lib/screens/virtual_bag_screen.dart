import 'package:flutter/material.dart';

import '../bloc/bag_bloc.dart';

/// Screen displaying the virtual gear bag with responsive mobile/tablet layout
/// and an empty state demo bag seeder (Story 1.5).
class VirtualBagScreen extends StatefulWidget {
  final BagBloc? bagBloc;

  const VirtualBagScreen({super.key, this.bagBloc});

  static const keyEmptyState = Key('virtual_bag_empty_state');
  static const keyEmptyAddButton = Key('virtual_bag_empty_add_button');
  static const keyLoadSampleBagButton = Key('virtual_bag_load_sample_bag_button');
  static const keyRacquetList = Key('virtual_bag_racquet_list');
  static const keyRacquetGrid = Key('virtual_bag_racquet_grid');
  static const keyBottomNav = Key('virtual_bag_bottom_nav');
  static const keyNavigationRail = Key('virtual_bag_navigation_rail');
  static const keyLoadingIndicator = Key('virtual_bag_loading_indicator');

  @override
  State<VirtualBagScreen> createState() => _VirtualBagScreenState();
}

class _VirtualBagScreenState extends State<VirtualBagScreen> {
  @override
  Widget build(BuildContext context) {
    // Red-phase stub pending Story 1.5 implementation
    return const Scaffold(
      body: Center(
        child: Text('Virtual Bag (Stub)'),
      ),
    );
  }
}
