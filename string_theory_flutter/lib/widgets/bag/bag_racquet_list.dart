import 'dart:async';

import 'package:flutter/material.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../../bloc/bag_bloc.dart';
import '../../screens/racquet_detail_screen.dart';
import '../../screens/virtual_bag_screen.dart';
import '../../theme/court_midnight_theme.dart';

/// Pull-to-refresh racquet list on mobile (<600dp), multi-column grid
/// (2-column tablet, 3-column desktop) on wider screens.
class BagRacquetList extends StatelessWidget {
  final List<Racquet> racquets;
  final BagBloc bloc;
  final bool isMobile;
  final int? crossAxisCount;

  /// Optional fixed main-axis extent override for the multi-column grid
  /// (tablet and desktop). When null, dynamically computes
  /// [resolveGridCardExtent] based on active text scaling.
  final double? mainAxisExtent;

  const BagRacquetList({
    super.key,
    required this.racquets,
    required this.bloc,
    required this.isMobile,
    this.crossAxisCount,
    this.mainAxisExtent,
  });

  static const keyRacquetList = Key('virtual_bag_racquet_list');
  static const keyRacquetGrid = Key('virtual_bag_racquet_grid');

  /// Base height of a grid card at 1.0x text scale: room for the gauge, specs,
  /// the dead-stringbed badge and the `[Restrung Today]` button.
  static const gridCardExtent = 176.0;

  /// Resolves the grid card height dynamically based on the provided [textScaler]
  /// to prevent vertical text overflow under accessibility text scaling.
  static double resolveGridCardExtentForScaler(TextScaler textScaler) {
    // Estimated vertical content breakdown:
    // Fixed non-text padding, borders and gaps:
    // card vertical padding (24) + border (3) + column spacers (3 + 2 + 4 + 6 = 15) + button/badge padding ≈ 52.0
    // Scalable text & button content:
    // Title (24) + specs (16) + hours/tension (16) + badge (20) + button (42) ≈ 118.0
    // Base total ≈ 170.0 with comfortable breathing room at 1.0x scale (176.0).
    final titleHeight = textScaler.scale(24.0);
    final specsHeight = textScaler.scale(16.0);
    final hoursHeight = textScaler.scale(16.0);
    final badgeHeight = textScaler.scale(20.0);
    final buttonHeight = textScaler.scale(42.0);
    const fixedElementsHeight = 52.0;

    final dynamicExtent =
        fixedElementsHeight +
        titleHeight +
        specsHeight +
        hoursHeight +
        badgeHeight +
        buttonHeight;

    return dynamicExtent > gridCardExtent ? dynamicExtent : gridCardExtent;
  }

  /// Resolves the grid card height dynamically based on the current
  /// [MediaQueryData.textScaler] to prevent vertical text overflow under
  /// accessibility text scaling.
  static double resolveGridCardExtent(BuildContext context) {
    final textScaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    return resolveGridCardExtentForScaler(textScaler);
  }

  /// Longest a pull-to-refresh spinner waits for the reload to settle.
  static const refreshTimeout = Duration(seconds: 8);

  /// Holds the spinner until the reload emits [BagLoaded] or [BagError], or
  /// [refreshTimeout] passes.
  Future<void> _onRefresh() async {
    final settled = Completer<void>();
    bloc.add(LoadBag(onSettled: settled.complete));
    try {
      await settled.future.timeout(refreshTimeout);
    } on TimeoutException {
      // Release the spinner; the reload still lands when it settles.
    }
  }

  int _resolveCrossAxisCount(BuildContext context) {
    if (crossAxisCount != null && crossAxisCount! > 0) {
      return crossAxisCount!;
    }
    final width = MediaQuery.sizeOf(context).width;
    if (width > VirtualBagScreen.kDesktopBreakpoint) return 3;
    return 2;
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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _resolveCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: mainAxisExtent ?? resolveGridCardExtent(context),
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
