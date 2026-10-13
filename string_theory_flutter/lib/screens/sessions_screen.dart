import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';
import '../client.dart' as app_client;
import '../services/health/health_sync_service.dart';
import '../theme/court_midnight_theme.dart';
import '../widgets/sessions/session_history_card.dart';
import '../widgets/workout_assignment_sheet.dart';

/// Dedicated screen for reviewing past tennis match and practice sessions,
/// stringbed court hours, and quick-logging sessions.
class SessionsScreen extends StatefulWidget {
  static const keySessionsScreen = Key('sessions_screen');
  static const keySessionsListView = Key('sessions_list_view');
  static const keySessionsEmptyState = Key('sessions_empty_state');
  static const keyLogSessionButton = Key('sessions_log_session_button');
  static const keyRetryButton = Key('sessions_retry_button');
  static const keyLoading = Key('sessions_loading_indicator');

  final BagBloc? bagBloc;
  final Client? client;
  final List<Racquet>? racquets;
  final HealthSyncService? healthSyncService;

  const SessionsScreen({
    super.key = keySessionsScreen,
    this.bagBloc,
    this.client,
    this.racquets,
    this.healthSyncService,
  });

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<SessionLog>? _sessions;
  bool _isLoading = true;
  bool _isFetching = false;
  String? _errorMessage;
  StreamSubscription<BagState>? _blocSubscription;

  @override
  void initState() {
    super.initState();
    _fetchSessionLogs();
    _subscribeToBloc();
  }

  @override
  void didUpdateWidget(covariant SessionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bagBloc != widget.bagBloc) {
      _blocSubscription?.cancel();
      _subscribeToBloc();
    }
  }

  @override
  void dispose() {
    _blocSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToBloc() {
    final bloc = widget.bagBloc ?? _resolveBagBloc();
    if (bloc != null) {
      _blocSubscription = bloc.stream.listen((state) {
        if (state is BagLoaded && mounted) {
          _fetchSessionLogs();
        }
      });
    }
  }

  BagBloc? _resolveBagBloc() {
    if (widget.bagBloc != null) return widget.bagBloc;
    try {
      return context.read<BagBloc>();
    } catch (_) {
      return null;
    }
  }

  Client? _resolveClient() {
    if (widget.client != null) return widget.client;
    final bloc = widget.bagBloc ?? _resolveBagBloc();
    if (bloc != null) {
      try {
        return bloc.client;
      } catch (_) {
        return null;
      }
    }
    try {
      return app_client.client;
    } catch (_) {
      return null;
    }
  }

  List<Racquet> _resolveRacquets() {
    if (widget.racquets != null) return widget.racquets!;
    final bloc = widget.bagBloc ?? _resolveBagBloc();
    if (bloc != null) {
      try {
        final state = bloc.state;
        if (state is BagLoaded) return state.racquets;
      } catch (_) {}
    }
    return const [];
  }

  String _resolveRacquetName(int racquetId, List<Racquet> racquets) {
    for (final r in racquets) {
      if (r.id == racquetId) return r.name;
    }
    return 'Racquet #$racquetId';
  }

  Future<void> _fetchSessionLogs() async {
    if (_isFetching) return;
    _isFetching = true;

    if (_sessions == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final client = _resolveClient();
      if (client == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Unable to connect to service. Please try again.';
          _isLoading = false;
        });
        return;
      }

      final logs = await client.session.getSessionLogs();
      if (!mounted) return;

      final sortedLogs = List<SessionLog>.from(logs)
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      setState(() {
        _sessions = sortedLogs;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load sessions. Please try again.';
        _isLoading = false;
      });
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _handleLogSession() async {
    final bloc = widget.bagBloc ?? _resolveBagBloc();
    final racquets = _resolveRacquets();
    if (bloc == null) return;

    await WorkoutAssignmentSheet.showForManual(
      context,
      racquets: racquets,
      bagBloc: bloc,
      healthSyncService: widget.healthSyncService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final racquets = _resolveRacquets();
    final hasSessions = _sessions != null && _sessions!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(hasSessions: hasSessions),
        Expanded(child: _buildBody(racquets: racquets)),
      ],
    );
  }

  Widget _buildHeader({required bool hasSessions}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sessions',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CourtMidnightTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Match & practice play history',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CourtMidnightTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (hasSessions) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              key: SessionsScreen.keyLogSessionButton,
              onPressed: _handleLogSession,
              icon: const Icon(Icons.add, size: 16, color: Colors.black),
              label: Text(
                'Log Session',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CourtMidnightTheme.primaryVolt,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody({required List<Racquet> racquets}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: SessionsScreen.keyLoading,
          valueColor: AlwaysStoppedAnimation<Color>(
            CourtMidnightTheme.primaryVolt,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: CourtMidnightTheme.healthCritical,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: CourtMidnightTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: SessionsScreen.keyRetryButton,
                onPressed: _fetchSessionLogs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CourtMidnightTheme.surfaceElevated,
                  foregroundColor: CourtMidnightTheme.textPrimary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sessions == null || _sessions!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: CourtMidnightTheme.primaryVolt,
      backgroundColor: CourtMidnightTheme.surface,
      onRefresh: _fetchSessionLogs,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            key: SessionsScreen.keySessionsListView,
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: _sessions!.length,
            itemBuilder: (context, index) {
              final session = _sessions![index];
              final racquetName =
                  _resolveRacquetName(session.racquetId, racquets);
              return SessionHistoryCard(
                key: ValueKey('session_${session.id ?? index}'),
                session: session,
                racquetName: racquetName,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: SessionsScreen.keySessionsEmptyState,
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
              'NO SESSIONS LOGGED',
              style: GoogleFonts.barlowCondensed(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CourtMidnightTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Your session history will appear here. Tap Log Session '
                'to record a match or practice session and track stringbed '
                'health. On iPhone and Android, tennis workouts from Apple Health '
                'or Health Connect are detected automatically.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CourtMidnightTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: SessionsScreen.keyLogSessionButton,
              onPressed: _handleLogSession,
              icon: const Icon(Icons.add, size: 18, color: Colors.black),
              label: Text(
                'Log Session',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CourtMidnightTheme.primaryVolt,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
