import 'package:flutter/material.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../../bloc/bag_bloc.dart';
import '../../screens/racquet_detail_screen.dart';
import '../../theme/court_midnight_theme.dart';
import '../racquet_card.dart';

/// Pull-to-refresh racquet list on mobile, two-column grid on wider screens.
class BagRacquetList extends StatelessWidget {
  final List<Racquet> racquets;
  final BagBloc bloc;
  final bool isMobile;

  const BagRacquetList({
    super.key,
    required this.racquets,
    required this.bloc,
    required this.isMobile,
  });

  static const keyRacquetList = Key('virtual_bag_racquet_list');
  static const keyRacquetGrid = Key('virtual_bag_racquet_grid');

  /// Height of a grid card: room for the gauge, specs, the dead-stringbed
  /// badge and the `[Restrung Today]` button.
  static const gridCardExtent = 176.0;

  Future<void> _onRefresh() async {
    bloc.add(const LoadBag());
  }

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return RefreshIndicator(
        color: CourtMidnightTheme.primaryVolt,
        backgroundColor: CourtMidnightTheme.surface,
        onRefresh: _onRefresh,
        child: ListView.separated(
          key: keyRacquetList,
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 88,
          ),
          itemCount: racquets.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final racquet = racquets[index];
            return RacquetCard(
              racquet: racquet,
              bloc: bloc,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RacquetDetailScreen(
                      racquet: racquet,
                      bagBloc: bloc,
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }

    // Tablet / Desktop multi-column grid (>=600dp)
    return RefreshIndicator(
      color: CourtMidnightTheme.primaryVolt,
      backgroundColor: CourtMidnightTheme.surface,
      onRefresh: _onRefresh,
      child: GridView.builder(
        key: keyRacquetGrid,
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 88,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: gridCardExtent,
        ),
        itemCount: racquets.length,
        itemBuilder: (context, index) {
          final racquet = racquets[index];
          return RacquetCard(
            racquet: racquet,
            bloc: bloc,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RacquetDetailScreen(
                    racquet: racquet,
                    bagBloc: bloc,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
