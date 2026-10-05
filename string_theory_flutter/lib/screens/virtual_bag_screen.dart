import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';
import '../domain/workout_formatting.dart' as formatting;
import '../services/health/health_sync_service.dart';
import '../theme/court_midnight_theme.dart';
import '../widgets/add_racquet_modal.dart';
import '../widgets/bag/add_racquet_fab.dart';
import '../widgets/bag/bag_bottom_nav.dart';
import '../widgets/bag/bag_empty_state.dart';
import '../widgets/bag/bag_error_view.dart';
import '../widgets/bag/bag_loading_indicator.dart';
import '../widgets/bag/bag_navigation_drawer.dart';
import '../widgets/bag/bag_navigation_rail.dart';
import '../widgets/bag/bag_racquet_list.dart';
import '../widgets/bag/bag_snack_bars.dart';
import '../widgets/bag/log_session_fab.dart';
import '../widgets/bag/pending_sync_banner.dart';
import '../widgets/bag/sessions_placeholder.dart';
import '../widgets/bag/simulate_workout_badge.dart';
import '../widgets/workout_assignment_sheet.dart';
import 'settings_screen.dart';

export '../widgets/racquet_card.dart';

const double kMobileBreakpoint = VirtualBagScreen.kMobileBreakpoint;
const double kDesktopBreakpoint = VirtualBagScreen.kDesktopBreakpoint;

/// Screen displaying the virtual gear bag with responsive mobile/tablet layout
/// and an empty state demo bag seeder (Story 1.5).
class VirtualBagScreen extends StatefulWidget {
  final BagBloc? bagBloc;

  /// Overrides the [HealthSyncService] otherwise read from the context.
  final HealthSyncService? healthSyncService;

  const VirtualBagScreen({super.key, this.bagBloc, this.healthSyncService});

  static const double kMobileBreakpoint = 600.0;
  static const double kDesktopBreakpoint = 1024.0;

  static const keyEmptyState = BagEmptyState.keyEmptyState;
  static const keyEmptyAddButton = BagEmptyState.keyEmptyAddButton;
  static const keyLoadSampleBagButton = BagEmptyState.keyLoadSampleBagButton;
  static const keyRacquetList = BagRacquetList.keyRacquetList;
  static const keyRacquetGrid = BagRacquetList.keyRacquetGrid;
  static const keyBottomNav = BagBottomNav.keyBottomNav;
  static const keyNavigationRail = BagNavigationRail.keyNavigationRail;
  static const keyNavigationDrawer = BagNavigationDrawer.keyNavigationDrawer;
  static const keyLoadingIndicator = BagLoadingIndicator.keyLoadingIndicator;
  static const keySimulateWorkoutBadge =
      SimulateWorkoutBadge.keySimulateWorkoutBadge;
  static const keyLogSessionFab = LogSessionFab.keyLogSessionFab;
  static const keyPendingSyncBanner = PendingSyncBanner.keyPendingSyncBanner;

  /// Formats a workout duration as e.g. `1h 30m`, `2h` or `45m`.
  static String formatWorkoutDuration(int minutes) =>
      formatting.formatWorkoutDuration(minutes);

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
        '${formatting.formatWorkoutDuration(workout.durationMinutes)} '
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
        buildDetectionSnackBar(
          message: message,
          onAssign: () {
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
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < VirtualBagScreen.kMobileBreakpoint;
    final isDesktop = width > VirtualBagScreen.kDesktopBreakpoint;
    final crossAxisCount = isDesktop ? 3 : 2;

    return BlocConsumer<BagBloc, BagState>(
      bloc: effectiveBloc,
      listener: (context, state) {
        if (state is BagLoaded && state.infoMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              buildInfoSnackBar(
                message: state.infoMessage!,
                hasPendingSync: state.pendingSyncCount > 0,
              ),
            );
        }
        if (state is BagLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(buildSuccessSnackBar(state.successMessage!));
        }
        if (state is BagLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(buildErrorSnackBar(state.errorMessage!));
        }
      },
      builder: (context, state) {
        final content = _navIndex == 1
            ? const SessionsPlaceholder()
            : _buildBodyForState(context, state, isMobile, crossAxisCount);

        if (isMobile) {
          return Scaffold(
            backgroundColor: CourtMidnightTheme.background,
            body: SafeArea(child: content),
            bottomNavigationBar: BagBottomNav(
              currentIndex: _navIndex,
              onTap: (index) => _onNavigationTapped(context, index),
            ),
            floatingActionButton: _buildFab(context, state),
          );
        }

        if (isDesktop) {
          return Scaffold(
            backgroundColor: CourtMidnightTheme.background,
            body: SafeArea(
              child: Row(
                children: [
                  BagNavigationDrawer(
                    selectedIndex: _navIndex,
                    onDestinationSelected: (index) =>
                        _onNavigationTapped(context, index),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
            floatingActionButton: _buildFab(context, state),
          );
        }

        // Tablet layout (600dp <= width <= 1024dp)
        return Scaffold(
          backgroundColor: CourtMidnightTheme.background,
          body: SafeArea(
            child: Row(
              children: [
                BagNavigationRail(
                  selectedIndex: _navIndex,
                  onDestinationSelected: (index) =>
                      _onNavigationTapped(context, index),
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

  Widget? _buildFab(BuildContext context, BagState state) {
    if (_navIndex != 0) return null;
    final racquets = state is BagLoaded ? state.racquets : const <Racquet>[];
    final hasRacquets = racquets.isNotEmpty;
    final showBadge = _healthSyncService?.supportsSimulation ?? false;

    final children = <Widget>[
      if (showBadge)
        SimulateWorkoutBadge(
          onTap: () => _healthSyncService?.simulateWorkout(),
        ),
      if (showBadge && hasRacquets) const SizedBox(height: 12),
      if (hasRacquets)
        LogSessionFab(
          onPressed: () =>
              _openManualAssignmentSheet(racquets, _resolveBloc(context)),
        ),
      if (hasRacquets) const SizedBox(height: 12),
      if (hasRacquets)
        AddRacquetFab(
          onPressed: () =>
              AddRacquetModal.show(context, bagBloc: _resolveBloc(context)),
        ),
    ];

    if (children.isEmpty) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );
  }

  Widget _buildBodyForState(
    BuildContext context,
    BagState state,
    bool isMobile,
    int crossAxisCount,
  ) {
    if (state is BagError) {
      return BagErrorView(
        message: state.message,
        onReload: () => _resolveBloc(context).add(const LoadBag()),
      );
    }

    if (state is BagLoaded) {
      final body = state.racquets.isEmpty
          ? BagEmptyState(
              onAddRacquet: () => AddRacquetModal.show(
                context,
                bagBloc: _resolveBloc(context),
              ),
              onLoadSampleBag: () =>
                  _resolveBloc(context).add(const SeedSampleBag()),
            )
          : BagRacquetList(
              racquets: state.racquets,
              bloc: _resolveBloc(context),
              isMobile: isMobile,
              crossAxisCount: crossAxisCount,
            );
      if (state.pendingSyncCount <= 0) return body;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PendingSyncBanner(count: state.pendingSyncCount, isMobile: isMobile),
          Expanded(child: body),
        ],
      );
    }

    // BagLoading and BagInitial
    return const BagLoadingIndicator();
  }
}
