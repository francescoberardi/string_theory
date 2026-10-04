import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';
import '../services/health/health_sync_service.dart';
import '../theme/court_midnight_theme.dart';
import '../widgets/add_racquet_modal.dart';
import '../widgets/racquet_card.dart';
import '../widgets/workout_assignment_sheet.dart';
import 'settings_screen.dart';

export '../widgets/racquet_card.dart';

/// Screen displaying the virtual gear bag with responsive mobile/tablet layout
/// and an empty state demo bag seeder (Story 1.5).
class VirtualBagScreen extends StatefulWidget {
  final BagBloc? bagBloc;

  /// Overrides the [HealthSyncService] otherwise read from the context.
  final HealthSyncService? healthSyncService;

  const VirtualBagScreen({super.key, this.bagBloc, this.healthSyncService});

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
  static const keySimulateWorkoutBadge = Key(
    'virtual_bag_simulate_workout_badge',
  );
  static const keyLogSessionFab = Key('virtual_bag_fab_log_session');

  /// Formats a workout duration as e.g. `1h 30m`, `2h` or `45m`.
  static String formatWorkoutDuration(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '${rest}m';
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}m';
  }

  @override
  State<VirtualBagScreen> createState() => _VirtualBagScreenState();
}

class _VirtualBagScreenState extends State<VirtualBagScreen> {
  int _navIndex = 0;
  HealthSyncService? _healthSyncService;
  StreamSubscription<DetectedWorkout>? _workoutSubscription;

  /// Detections received since the last frame, surfaced as one SnackBar.
  final _detectionBuffer = <DetectedWorkout>[];
  bool _detectionFlushScheduled = false;
  bool _isAssignmentSheetOpen = false;

  Future<void> _openDetectedAssignmentSheet(
    DetectedWorkout workout,
    List<Racquet> racquets,
    BagBloc bloc,
  ) async {
    if (_isAssignmentSheetOpen) return;
    _isAssignmentSheetOpen = true;
    try {
      await WorkoutAssignmentSheet.showForDetected(
        context,
        workout: workout,
        racquets: racquets,
        bagBloc: bloc,
        healthSyncService: _healthSyncService,
      );
    } finally {
      if (mounted) {
        _isAssignmentSheetOpen = false;
      }
    }
  }

  Future<void> _openManualAssignmentSheet(
    List<Racquet> racquets,
    BagBloc bloc,
  ) async {
    if (_isAssignmentSheetOpen) return;
    _isAssignmentSheetOpen = true;
    try {
      await WorkoutAssignmentSheet.showForManual(
        context,
        racquets: racquets,
        bagBloc: bloc,
        healthSyncService: _healthSyncService,
      );
    } finally {
      if (mounted) {
        _isAssignmentSheetOpen = false;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindHealthSyncService(
      widget.healthSyncService ?? context.read<HealthSyncService>(),
    );
  }

  @override
  void didUpdateWidget(covariant VirtualBagScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.healthSyncService != oldWidget.healthSyncService) {
      _bindHealthSyncService(
        widget.healthSyncService ?? context.read<HealthSyncService>(),
      );
    }
  }

  void _bindHealthSyncService(HealthSyncService service) {
    if (identical(service, _healthSyncService)) return;
    _workoutSubscription?.cancel();
    _healthSyncService = service;
    _workoutSubscription = service.workouts.listen(_onWorkoutDetected);
    // Pull recently completed workouts (no-op when simulated).
    unawaited(service.syncWorkouts());
  }

  /// Buffers detections arriving within the same frame (e.g. one sync that
  /// finds several workouts) so each batch yields a single SnackBar.
  void _onWorkoutDetected(DetectedWorkout workout) {
    if (!mounted) return;
    _detectionBuffer.add(workout);
    if (_detectionFlushScheduled) return;
    _detectionFlushScheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) => _flushDetections());
    binding.ensureVisualUpdate();
  }

  void _flushDetections() {
    _detectionFlushScheduled = false;
    final batch = List.of(_detectionBuffer);
    _detectionBuffer.clear();
    if (!mounted || batch.isEmpty) return;

    final message = switch (batch) {
      [final workout] =>
        '${VirtualBagScreen.formatWorkoutDuration(workout.durationMinutes)} '
            'Tennis Match Detected',
      _ => '${batch.length} Tennis Matches Detected',
    };

    final bloc = _resolveBloc(context);
    final currentState = bloc.state;
    final racquets = (currentState is BagLoaded)
        ? currentState.racquets
        : <Racquet>[];

    // Auto-open only over the bag tab itself; otherwise the Assign action
    // below remains the way in.
    final isBagVisible =
        _navIndex == 0 && (ModalRoute.of(context)?.isCurrent ?? true);
    if (racquets.isNotEmpty && isBagVisible) {
      _openDetectedAssignmentSheet(batch.first, racquets, bloc);
    }

    // Replace any detection still on screen instead of queueing behind it.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: CourtMidnightTheme.surface,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(
            label: 'Assign',
            textColor: CourtMidnightTheme.primaryVolt,
            onPressed: () {
              // The SnackBar can outlive this screen.
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (_isAssignmentSheetOpen) return;
              final bloc = _resolveBloc(context);
              final activeState = bloc.state;
              _openDetectedAssignmentSheet(
                batch.first,
                activeState is BagLoaded ? activeState.racquets : <Racquet>[],
                bloc,
              );
            },
          ),
          content: Row(
            children: [
              const Icon(
                Icons.sports_tennis,
                color: CourtMidnightTheme.primaryVolt,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: CourtMidnightTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  void dispose() {
    _workoutSubscription?.cancel();
    super.dispose();
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

    return BlocConsumer<BagBloc, BagState>(
      bloc: effectiveBloc,
      listener: (context, state) {
        if (state is BagLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: CourtMidnightTheme.healthCritical,
              behavior: SnackBarBehavior.floating,
              content: Text(
                state.errorMessage!,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          );
        }
      },
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
        MaterialPageRoute(
          builder: (_) => SettingsScreen(
            bagBloc: _resolveBloc(context),
          ),
        ),
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
    final logFab = _buildLogSessionFab(context, state);
    final addFab = _buildAddRacquetFab(context, state);
    final showBadge = _healthSyncService?.supportsSimulation ?? false;

    final children = <Widget>[
      if (showBadge) _buildSimulateWorkoutBadge(),
      if (showBadge && logFab != null) const SizedBox(height: 12),
      ?logFab,
      if ((showBadge || logFab != null) && addFab != null)
        const SizedBox(height: 12),
      ?addFab,
    ];

    if (children.isEmpty) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );
  }

  Widget _buildSimulateWorkoutBadge() {
    return Material(
      color: CourtMidnightTheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: CourtMidnightTheme.primaryVolt.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: VirtualBagScreen.keySimulateWorkoutBadge,
        onTap: () => _healthSyncService?.simulateWorkout(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            '🧪 Simulate Workout',
            style: GoogleFonts.barlowCondensed(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: CourtMidnightTheme.primaryVolt,
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildLogSessionFab(BuildContext context, BagState state) {
    if (state is BagLoaded && state.racquets.isNotEmpty) {
      return FloatingActionButton.extended(
        key: VirtualBagScreen.keyLogSessionFab,
        heroTag: 'virtual_bag_fab_log_session_hero',
        backgroundColor: CourtMidnightTheme.surface,
        foregroundColor: CourtMidnightTheme.primaryVolt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: CourtMidnightTheme.primaryVolt,
            width: 1.5,
          ),
        ),
        onPressed: () {
          _openManualAssignmentSheet(
            state.racquets,
            _resolveBloc(context),
          );
        },
        icon: const Icon(
          Icons.timer_outlined,
          color: CourtMidnightTheme.primaryVolt,
        ),
        label: Text(
          '+ Log Session',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: CourtMidnightTheme.primaryVolt,
          ),
        ),
      );
    }
    return null;
  }

  Widget? _buildAddRacquetFab(BuildContext context, BagState state) {
    if (state is BagLoaded && state.racquets.isNotEmpty) {
      return FloatingActionButton.extended(
        key: const Key('virtual_bag_fab_add'),
        heroTag: 'virtual_bag_fab_add_hero',
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
