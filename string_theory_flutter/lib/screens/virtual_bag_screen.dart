import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';
import '../theme/court_midnight_theme.dart';
import '../widgets/add_racquet_modal.dart';
import 'settings_screen.dart';

/// Screen displaying the virtual gear bag with responsive mobile/tablet layout
/// and an empty state demo bag seeder (Story 1.5).
class VirtualBagScreen extends StatefulWidget {
  final BagBloc? bagBloc;

  const VirtualBagScreen({super.key, this.bagBloc});

  static const keyEmptyState = Key('virtual_bag_empty_state');
  static const keyEmptyAddButton = Key('virtual_bag_empty_add_button');
  static const keyLoadSampleBagButton = Key(
    'virtual_bag_load_sample_bag_button',
  );
  static const keyRacquetList = Key('virtual_bag_racquet_list');
  static const keyRacquetGrid = Key('virtual_bag_racquet_grid');
  static const keyBottomNav = Key('virtual_bag_bottom_nav');
  static const keyNavigationRail = Key('virtual_bag_navigation_rail');
  static const keyLoadingIndicator = Key('virtual_bag_loading_indicator');

  @override
  State<VirtualBagScreen> createState() => _VirtualBagScreenState();
}

class _VirtualBagScreenState extends State<VirtualBagScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  BagBloc _resolveBloc(BuildContext context) {
    if (widget.bagBloc != null) {
      return widget.bagBloc!;
    }
    return context.read<BagBloc>();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBloc = widget.bagBloc ?? context.read<BagBloc>();
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return BlocBuilder<BagBloc, BagState>(
      bloc: effectiveBloc,
      builder: (context, state) {
        final content = _navIndex == 1
            ? _buildSessionsPlaceholder()
            : _buildBodyForState(context, state, isMobile);

        if (isMobile) {
          return Scaffold(
            backgroundColor: CourtMidnightTheme.background,
            body: SafeArea(child: content),
            bottomNavigationBar: BottomNavigationBar(
              key: VirtualBagScreen.keyBottomNav,
              type: BottomNavigationBarType.fixed,
              backgroundColor: CourtMidnightTheme.surface,
              selectedItemColor: CourtMidnightTheme.primaryVolt,
              unselectedItemColor: CourtMidnightTheme.textSecondary,
              currentIndex: _navIndex,
              onTap: (index) => _onNavigationTapped(context, index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_tennis),
                  label: 'Bag',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Sessions',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.manage_accounts_outlined),
                  label: 'Account',
                ),
              ],
            ),
            floatingActionButton: _buildFab(context, state),
          );
        }

        // Tablet / Desktop layout (>=600dp)
        return Scaffold(
          backgroundColor: CourtMidnightTheme.background,
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  key: VirtualBagScreen.keyNavigationRail,
                  backgroundColor: CourtMidnightTheme.surface,
                  selectedIndex: _navIndex,
                  onDestinationSelected: (index) =>
                      _onNavigationTapped(context, index),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(
                    color: CourtMidnightTheme.primaryVolt,
                  ),
                  selectedLabelTextStyle: GoogleFonts.barlowCondensed(
                    color: CourtMidnightTheme.primaryVolt,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: CourtMidnightTheme.textSecondary,
                  ),
                  unselectedLabelTextStyle: GoogleFonts.inter(
                    color: CourtMidnightTheme.textSecondary,
                    fontSize: 12,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.sports_tennis),
                      label: Text('Bag'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history),
                      label: Text('Sessions'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.manage_accounts_outlined),
                      label: Text('Account'),
                    ),
                  ],
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: CourtMidnightTheme.surfaceBorder,
                ),
                Expanded(child: content),
              ],
            ),
          ),
          floatingActionButton: _buildFab(context, state),
        );
      },
    );
  }

  void _onNavigationTapped(BuildContext context, int index) {
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    } else {
      setState(() => _navIndex = index);
    }
  }

  Widget _buildSessionsPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CourtMidnightTheme.primaryVolt.withValues(alpha: 0.12),
                border: Border.all(
                  color: CourtMidnightTheme.primaryVolt.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.sports_tennis,
                size: 38,
                color: CourtMidnightTheme.primaryVolt,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'COURT SESSIONS',
              style: GoogleFonts.barlowCondensed(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CourtMidnightTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Session logging & Apple Health sync coming soon in Epic 2.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CourtMidnightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFab(BuildContext context, BagState state) {
    if (_navIndex != 0) return null;
    if (state is BagLoaded && state.racquets.isNotEmpty) {
      return FloatingActionButton.extended(
        key: const Key('virtual_bag_fab_add'),
        backgroundColor: CourtMidnightTheme.primaryVolt,
        foregroundColor: Colors.black,
        onPressed: () {
          AddRacquetModal.show(context, bagBloc: _resolveBloc(context));
        },
        icon: const Icon(Icons.add),
        label: Text(
          'Add Racquet',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildBodyForState(
    BuildContext context,
    BagState state,
    bool isMobile,
  ) {
    if (state is BagLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: VirtualBagScreen.keyLoadingIndicator,
          color: CourtMidnightTheme.primaryVolt,
        ),
      );
    }

    if (state is BagError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: CourtMidnightTheme.healthCritical,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: GoogleFonts.inter(
                  color: CourtMidnightTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _resolveBloc(context).add(const LoadBag()),
                icon: const Icon(Icons.refresh),
                label: const Text('Reload Bag'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CourtMidnightTheme.primaryVolt,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is BagLoaded) {
      if (state.racquets.isEmpty) {
        return _buildEmptyState(context);
      }

      if (isMobile) {
        return RefreshIndicator(
          color: CourtMidnightTheme.primaryVolt,
          backgroundColor: CourtMidnightTheme.surface,
          onRefresh: () async {
            _resolveBloc(context).add(const LoadBag());
          },
          child: ListView.separated(
            key: VirtualBagScreen.keyRacquetList,
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 88,
            ),
            itemCount: state.racquets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return RacquetCard(
                racquet: state.racquets[index],
                bloc: _resolveBloc(context),
              );
            },
          ),
        );
      }

      // Tablet / Desktop multi-column grid (>=600dp)
      return RefreshIndicator(
        color: CourtMidnightTheme.primaryVolt,
        backgroundColor: CourtMidnightTheme.surface,
        onRefresh: () async {
          _resolveBloc(context).add(const LoadBag());
        },
        child: GridView.builder(
          key: VirtualBagScreen.keyRacquetGrid,
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
            mainAxisExtent: 140,
          ),
          itemCount: state.racquets.length,
          itemBuilder: (context, index) {
            return RacquetCard(
              racquet: state.racquets[index],
              bloc: _resolveBloc(context),
            );
          },
        ),
      );
    }

    // Default loading state for BagInitial
    return const Center(
      child: CircularProgressIndicator(
        key: VirtualBagScreen.keyLoadingIndicator,
        color: CourtMidnightTheme.primaryVolt,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          key: VirtualBagScreen.keyEmptyState,
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: CourtMidnightTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CourtMidnightTheme.surfaceBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CourtMidnightTheme.primaryVolt.withValues(alpha: 0.12),
                  border: Border.all(
                    color: CourtMidnightTheme.primaryVolt.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.sports_tennis,
                  size: 38,
                  color: CourtMidnightTheme.primaryVolt,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'YOUR BAG IS EMPTY',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: CourtMidnightTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your racquets to track stringbed decay, tension loss, and court hours.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CourtMidnightTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  key: VirtualBagScreen.keyEmptyAddButton,
                  onPressed: () {
                    AddRacquetModal.show(
                      context,
                      bagBloc: _resolveBloc(context),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: Text(
                    '+ Add Racquet',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CourtMidnightTheme.primaryVolt,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  key: VirtualBagScreen.keyLoadSampleBagButton,
                  onPressed: () {
                    _resolveBloc(context).add(const SeedSampleBag());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CourtMidnightTheme.primaryVolt,
                    side: const BorderSide(
                      color: CourtMidnightTheme.primaryVolt,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '⚡ Load Sample Bag',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CourtMidnightTheme.primaryVolt,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Athletic racquet card displaying stringbed health, specs, and status badges.
class RacquetCard extends StatelessWidget {
  final Racquet racquet;
  final BagBloc bloc;
  final VoidCallback? onTap;

  const RacquetCard({
    super.key,
    required this.racquet,
    required this.bloc,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final job = racquet.activeStringJob;
    final hasJob = job != null;
    final health = hasJob ? job.currentHealthScore : null;

    final Color healthColor;
    if (health == null) {
      healthColor = CourtMidnightTheme.textTertiary;
    } else if (health >= 70) {
      healthColor = CourtMidnightTheme.healthOptimal;
    } else if (health >= 40) {
      healthColor = CourtMidnightTheme.healthDegraded;
    } else {
      healthColor = CourtMidnightTheme.healthCritical;
    }

    final isCritical = health != null && health < 40;
    final cardBg = isCritical
        ? CourtMidnightTheme.healthCriticalBg
        : CourtMidnightTheme.surface;
    final cardBorder = isCritical
        ? Border.all(color: CourtMidnightTheme.healthCritical, width: 1.5)
        : Border.all(color: CourtMidnightTheme.surfaceBorder, width: 1.0);

    final stringParts = <String>[];
    if (job != null) {
      final nameParts = [
        if (job.brand != null && job.brand!.trim().isNotEmpty)
          job.brand!.trim(),
        if (job.model != null && job.model!.trim().isNotEmpty)
          job.model!.trim(),
      ].join(' ');
      if (nameParts.isNotEmpty) stringParts.add(nameParts);
      if (job.installedTension != null) {
        stringParts.add('${job.installedTension!.toStringAsFixed(0)} lbs');
      }
    }
    final stringSpecs = stringParts.isNotEmpty
        ? stringParts.join(' • ')
        : 'No string mounted';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: cardBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Radial Health Gauge
            _buildHealthGauge(health, healthColor),
            const SizedBox(width: 14),

            // Center: Racquet specs & strings
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          racquet.name,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CourtMidnightTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (racquet.isPrimary) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CourtMidnightTheme.primaryVolt,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PRIMARY',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stringSpecs,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: hasJob
                          ? CourtMidnightTheme.textSecondary
                          : CourtMidnightTheme.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (job != null)
                    Text(
                      '${job.materialCategory.displayName} • ${job.totalCourtHours.toStringAsFixed(1)}h / ${job.maxRatedHours.toStringAsFixed(0)}h max',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: CourtMidnightTheme.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (isCritical) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CourtMidnightTheme.healthCritical.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: CourtMidnightTheme.healthCritical.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: CourtMidnightTheme.healthCritical,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Dead Stringbed — High Shock Risk',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: CourtMidnightTheme.healthCritical,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right: Quick context menu
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: CourtMidnightTheme.textTertiary,
                size: 20,
              ),
              color: CourtMidnightTheme.surfaceElevated,
              onSelected: (value) async {
                if (value == 'primary' && racquet.id != null) {
                  bloc.add(SetPrimaryRacquet(racquet.id!));
                } else if (value == 'delete' && racquet.id != null) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: CourtMidnightTheme.surfaceElevated,
                      title: Text(
                        'Delete Racquet',
                        style: GoogleFonts.barlowCondensed(
                          color: CourtMidnightTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to remove "${racquet.name}" from your bag? This cannot be undone.',
                        style: GoogleFonts.inter(
                          color: CourtMidnightTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: CourtMidnightTheme.textTertiary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: CourtMidnightTheme.healthCritical,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && racquet.id != null) {
                    bloc.add(DeleteRacquet(racquet.id!));
                  }
                }
              },
              itemBuilder: (context) => [
                if (!racquet.isPrimary && racquet.id != null)
                  const PopupMenuItem(
                    value: 'primary',
                    child: Text('Set as Primary'),
                  ),
                if (racquet.id != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete Racquet',
                      style: TextStyle(
                        color: CourtMidnightTheme.healthCritical,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthGauge(int? health, Color healthColor) {
    final displayValue = health != null ? '$health%' : '--';
    final progress = health != null ? (health.clamp(0, 100)) / 100.0 : 0.0;

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: CourtMidnightTheme.surfaceBorder,
            valueColor: AlwaysStoppedAnimation<Color>(healthColor),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayValue,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: health != null
                      ? CourtMidnightTheme.textPrimary
                      : CourtMidnightTheme.textTertiary,
                  height: 1.0,
                ),
              ),
              Text(
                health != null ? 'HEALTH' : 'UNSTRUNG',
                style: GoogleFonts.barlowCondensed(
                  fontSize: health != null ? 8 : 7,
                  fontWeight: FontWeight.bold,
                  color: healthColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
