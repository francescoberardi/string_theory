import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';
import '../bloc/bag_bloc.dart';
import '../client.dart';
import '../domain/decay_engine.dart';
import '../theme/court_midnight_theme.dart';
import '../widgets/radial_health_gauge.dart';
import '../widgets/restring_sheet.dart';
import '../widgets/timeline/restring_timeline_tile.dart';

const List<String> _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) {
  return '${_shortMonths[date.month - 1]} ${date.day}, ${date.year}';
}

/// Static widget keys for targeting elements on [RacquetDetailScreen].
abstract final class RacquetDetailKeys {
  static const overviewTab = Key('racquet_detail_overview_tab');
  static const historyTab = Key('racquet_detail_history_tab');
  static const restrungTodayButton = Key(
    'racquet_detail_restrung_today_button',
  );
  static const historyRetryButton = Key('racquet_detail_history_retry_button');
  static const historyEmptyState = Key('racquet_detail_history_empty_state');
  static const tensionLossCard = Key('racquet_detail_tension_loss_card');
}

/// Detailed view of a racquet displaying its current health score, stringbed
/// specifications, tension decay analysis, and historical restring timeline.
class RacquetDetailScreen extends StatefulWidget {
  final Racquet racquet;
  final BagBloc? bagBloc;
  final Client? client;

  const RacquetDetailScreen({
    super.key,
    required this.racquet,
    this.bagBloc,
    this.client,
  });

  @override
  State<RacquetDetailScreen> createState() => _RacquetDetailScreenState();
}

class _RacquetDetailScreenState extends State<RacquetDetailScreen> {
  int? _lastActiveStringJobId;
  bool _isLoadingHistory = true;
  String? _historyError;
  List<RestringEvent> _history = [];

  BagBloc _resolveBloc(BuildContext context) =>
      widget.bagBloc ?? context.read<BagBloc>();

  Client _resolveClient(BuildContext context) {
    if (widget.client != null) return widget.client!;
    if (widget.bagBloc != null) return widget.bagBloc!.client;
    try {
      return context.read<BagBloc>().client;
    } catch (_) {
      return client;
    }
  }

  @override
  void initState() {
    super.initState();
    _lastActiveStringJobId = widget.racquet.activeStringJobId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() async {
    final racquetId = widget.racquet.id;
    if (racquetId == null) {
      if (mounted) {
        setState(() {
          _history = [];
          _isLoadingHistory = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      if (_history.isEmpty) {
        _isLoadingHistory = true;
      }
      _historyError = null;
    });

    try {
      final apiClient = _resolveClient(context);
      final history = await apiClient.bag.getRestringHistory(
        racquetId: racquetId,
      );
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString();
          _isLoadingHistory = false;
        });
      }
    }
  }

  void _onBagStateChanged(BagState state) {
    if (state is BagLoaded) {
      final updated = state.racquets
          .where((r) => r.id == widget.racquet.id)
          .firstOrNull;
      if (updated != null &&
          updated.activeStringJobId != _lastActiveStringJobId) {
        _lastActiveStringJobId = updated.activeStringJobId;
        _fetchHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBloc = _resolveBloc(context);

    return BlocConsumer<BagBloc, BagState>(
      bloc: effectiveBloc,
      listener: (context, state) => _onBagStateChanged(state),
      builder: (context, state) {
        final currentRacquet = (state is BagLoaded)
            ? (state.racquets
                      .where((r) => r.id == widget.racquet.id)
                      .firstOrNull ??
                  widget.racquet)
            : widget.racquet;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: CourtMidnightTheme.background,
            appBar: AppBar(
              leading: const BackButton(),
              title: Text(currentRacquet.name),
              bottom: TabBar(
                indicatorColor: CourtMidnightTheme.primaryVolt,
                indicatorWeight: 3,
                labelColor: CourtMidnightTheme.primaryVolt,
                unselectedLabelColor: CourtMidnightTheme.textSecondary,
                labelStyle: GoogleFonts.barlowCondensed(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                tabs: const [
                  Tab(key: RacquetDetailKeys.overviewTab, text: 'Overview'),
                  Tab(key: RacquetDetailKeys.historyTab, text: 'History'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildOverviewTab(context, currentRacquet, effectiveBloc),
                _buildHistoryTab(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    Racquet racquet,
    BagBloc bloc,
  ) {
    final job = racquet.activeStringJob;
    final health = job?.currentHealthScore;
    final isCritical = health != null && health < 40;

    final stringTitle = [
      if (job?.brand != null && job!.brand!.trim().isNotEmpty)
        job.brand!.trim(),
      if (job?.model != null && job!.model!.trim().isNotEmpty)
        job.model!.trim(),
    ].join(' ');

    final tensionLossText = (job != null && health != null)
        ? DecayEngine.calculateTensionLossText(
            healthScore: health,
            installedTensionLbs: job.installedTension ?? 52.0,
          )
        : null;

    final remainingHours = job != null
        ? (job.maxRatedHours - job.totalCourtHours).clamp(
            0.0,
            job.maxRatedHours,
          )
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card with Radial Health Gauge & Identity
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isCritical
                  ? CourtMidnightTheme.healthCriticalBg
                  : CourtMidnightTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCritical
                    ? CourtMidnightTheme.healthCritical
                    : CourtMidnightTheme.surfaceBorder,
                width: isCritical ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                RadialHealthGauge(
                  healthScore: health,
                  size: 96,
                  animate: true,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              racquet.name,
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: CourtMidnightTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (racquet.isPrimary) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CourtMidnightTheme.primaryVolt,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PRIMARY',
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stringTitle.isNotEmpty
                            ? stringTitle
                            : 'No string mounted',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CourtMidnightTheme.textSecondary,
                        ),
                      ),
                      if (job != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${job.materialCategory.displayName} • ${job.installedTension != null ? '${job.installedTension!.toStringAsFixed(0)} lbs' : '—'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CourtMidnightTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Strung on ${_formatDate(job.stringingDate)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: CourtMidnightTheme.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tension Decay Estimator Card
          if (tensionLossText != null && tensionLossText.isNotEmpty)
            Container(
              key: RacquetDetailKeys.tensionLossCard,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: CourtMidnightTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: CourtMidnightTheme.surfaceBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_down,
                    color: CourtMidnightTheme.primaryVolt,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTIMATED TENSION LOSS',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: CourtMidnightTheme.textTertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tensionLossText,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CourtMidnightTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Performance Stats Grid
          if (job != null) ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'COURT HOURS',
                    value: '${job.totalCourtHours.toStringAsFixed(1)}h',
                    subtitle: 'logged on stringbed',
                    icon: Icons.sports_tennis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'REMAINING RATED',
                    value: '${remainingHours.toStringAsFixed(1)}h',
                    subtitle: 'of ${job.maxRatedHours.toStringAsFixed(0)}h max',
                    icon: Icons.hourglass_bottom,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'INSTALLED TENSION',
                    value: job.installedTension != null
                        ? '${job.installedTension!.toStringAsFixed(0)} lbs'
                        : '—',
                    subtitle: 'initial mounting',
                    icon: Icons.speed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'MATERIAL',
                    value: job.materialCategory.displayName,
                    subtitle: 'string classification',
                    icon: Icons.category_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Restrung Today Action CTA
            SizedBox(
              height: 52,
              child: isCritical
                  ? ElevatedButton.icon(
                      key: RacquetDetailKeys.restrungTodayButton,
                      onPressed: () => RestringSheet.show(
                        context,
                        racquet: racquet,
                        bagBloc: bloc,
                      ),
                      icon: const Icon(Icons.restart_alt, size: 20),
                      label: Text(
                        'Restrung Today',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CourtMidnightTheme.healthCritical,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      key: RacquetDetailKeys.restrungTodayButton,
                      onPressed: () => RestringSheet.show(
                        context,
                        racquet: racquet,
                        bagBloc: bloc,
                      ),
                      icon: const Icon(Icons.restart_alt, size: 20),
                      label: Text(
                        'Restrung Today',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CourtMidnightTheme.primaryVolt,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(
          color: CourtMidnightTheme.primaryVolt,
        ),
      );
    }

    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: CourtMidnightTheme.healthCritical,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load restring history',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CourtMidnightTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _historyError!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CourtMidnightTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: RacquetDetailKeys.historyRetryButton,
                onPressed: _fetchHistory,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CourtMidnightTheme.primaryVolt,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            key: RacquetDetailKeys.historyEmptyState,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CourtMidnightTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CourtMidnightTheme.surfaceBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history,
                  size: 40,
                  color: CourtMidnightTheme.textTertiary,
                ),
                const SizedBox(height: 14),
                Text(
                  'No Restring History',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CourtMidnightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No past restrings recorded for this racquet yet. Restring history will appear here once you retire your first stringbed.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CourtMidnightTheme.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: CourtMidnightTheme.primaryVolt,
      backgroundColor: CourtMidnightTheme.surface,
      onRefresh: _fetchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final event = _history[index];
          return RestringTimelineTile(
            event: event,
            isFirst: index == 0,
            isLast: index == _history.length - 1,
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CourtMidnightTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CourtMidnightTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: CourtMidnightTheme.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CourtMidnightTheme.textTertiary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CourtMidnightTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CourtMidnightTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
