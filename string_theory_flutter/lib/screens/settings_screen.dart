import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';
import '../client.dart' as app_client;
import '../services/auth_service.dart';

/// Settings: the signed-in account, sign-out and the developer controls.
class SettingsScreen extends StatefulWidget {
  final AuthService? authService;
  final Client? client;
  final BagBloc? bagBloc;

  const SettingsScreen({
    super.key,
    this.authService,
    this.client,
    this.bagBloc,
  });

  static const keyGuestBanner = Key('settings_guest_banner');
  static const keyAccountEmail = Key('settings_account_email');
  static const keySignOutButton = Key('settings_sign_out_button');
  static const keyConfirmSignOutButton = Key(
    'settings_confirm_sign_out_button',
  );
  static const keyDevTriggerDecayButton = Key('dev_trigger_decay_button');
  static const keyDevFastForwardButton = Key('dev_fast_forward_30_days_button');

  /// Sign-out warning for a guest, whose bag can't be reached again.
  static const guestSignOutWarning =
      'You are signed in as a guest. After signing out, this guest bag becomes '
      "unreachable and can't be recovered.";

  /// Asks to confirm a sign-out; resolves to whether the user confirmed.
  ///
  /// Warns that a guest bag becomes unreachable unless the account is known
  /// to be an email account: a guest whose lookup failed would otherwise lose
  /// the bag without a warning.
  static Future<bool> confirmSignOut(
    BuildContext context,
    AuthService authService,
  ) async {
    final isGuest = authService.account.value.kind != AccountKind.email;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A3034)),
        ),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.barlowCondensed(
            color: const Color(0xFFFF453A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          isGuest
              ? SettingsScreen.guestSignOutWarning
              : 'You will return to the sign-in screen. Sign in again with '
                    'the same email to get your bag back.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            key: SettingsScreen.keyConfirmSignOutButton,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF453A),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDecaying = false;
  bool _isFastForwarding = false;

  AuthService get _authService => widget.authService ?? app_client.authService;
  Client get _client => widget.client ?? app_client.client;

  @override
  void initState() {
    super.initState();
    // Retry an account lookup that failed earlier (e.g. offline at launch).
    _authService.refreshAccount();
  }

  void _showSuccessFeedback(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFC6F10E),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await SettingsScreen.confirmSignOut(
      context,
      _authService,
    );

    // The auth gate replaces the whole signed-in app with the sign-in screen,
    // so this screen goes away on its own.
    if (confirmed) {
      try {
        await _authService.signOut();
      } catch (e) {
        debugPrint('SettingsScreen: sign-out failed: $e');
        if (context.mounted) {
          _showErrorFeedback(context, "Couldn't sign out: $e");
        }
      }
    }
  }

  void _showErrorFeedback(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFFF453A),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _triggerFutureCallDecay(BuildContext context) async {
    if (_isDecaying) return;
    setState(() => _isDecaying = true);
    try {
      final updatedCount = await _client.bag.triggerDailyDecayNow();
      debugPrint(
        '[DevControl] DailyDecayFutureCall executed: $updatedCount active string jobs updated',
      );
      if (context.mounted) {
        _showSuccessFeedback(
          context,
          'Decay executed: $updatedCount string jobs updated',
        );
      }
      if (widget.bagBloc != null) {
        widget.bagBloc!.add(const LoadBag());
      } else if (context.mounted) {
        try {
          context.read<BagBloc>().add(const LoadBag());
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[DevControl] Error executing DailyDecayFutureCall: $e');
      if (context.mounted) {
        _showErrorFeedback(context, 'Error triggering decay: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDecaying = false);
      }
    }
  }

  Future<void> _fastForwardAging(BuildContext context) async {
    if (_isFastForwarding) return;
    setState(() => _isFastForwarding = true);
    try {
      int? targetRacquetId;
      String? targetRacquetName;

      BagBloc? bloc = widget.bagBloc;
      if (bloc == null && context.mounted) {
        try {
          bloc = context.read<BagBloc>();
        } catch (_) {}
      }

      final isLoaded = bloc != null && bloc.state is BagLoaded;
      if (isLoaded) {
        final racquets = (bloc.state as BagLoaded).racquets;
        final candidate =
            racquets
                .where((r) => r.isPrimary && r.activeStringJob != null)
                .firstOrNull ??
            racquets.where((r) => r.activeStringJob != null).firstOrNull;
        if (candidate != null) {
          targetRacquetId = candidate.id;
          targetRacquetName = candidate.name;
        }
      } else {
        // Fallback only if BagBloc is not available or not loaded yet
        final racquets = await _client.bag.getVirtualBag();
        final candidate =
            racquets
                .where((r) => r.isPrimary && r.activeStringJob != null)
                .firstOrNull ??
            racquets.where((r) => r.activeStringJob != null).firstOrNull;
        if (candidate != null) {
          targetRacquetId = candidate.id;
          targetRacquetName = candidate.name;
        }
      }

      if (targetRacquetId == null) {
        if (context.mounted) {
          _showErrorFeedback(
            context,
            'No racquet with an active string job found. Add or string a racquet first.',
          );
        }
        return;
      }

      final updated = await _client.bag.fastForwardRacquetAge(
        racquetId: targetRacquetId,
        days: 30,
      );

      final newHealth = updated.activeStringJob?.currentHealthScore ?? 0;
      debugPrint(
        '[DevControl] fastForwardRacquetAge executed on "$targetRacquetName": new health score $newHealth%',
      );

      if (context.mounted) {
        _showSuccessFeedback(
          context,
          'Aged "$targetRacquetName" by 30 days (Health: $newHealth%)',
        );
      }

      if (bloc != null) {
        bloc.add(FastForwardRacquetAge(targetRacquetId, days: 30));
      }
    } catch (e) {
      debugPrint('[DevControl] Error executing fastForwardRacquetAge: $e');
      if (context.mounted) {
        _showErrorFeedback(context, 'Error fast-forwarding age: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isFastForwarding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _authService;

    return Scaffold(
      backgroundColor: const Color(0xFF121516),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121516),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Settings',
          style: GoogleFonts.barlowCondensed(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ValueListenableBuilder<AccountInfo>(
        valueListenable: auth.account,
        builder: (context, account, _) {
          final userId = auth.currentUserId ?? 'Not signed in';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACCOUNT & SYNC',
                  style: GoogleFonts.barlowCondensed(
                    color: const Color(0xFFC6F10E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _AccountCard(account: account, userId: userId),
                const SizedBox(height: 28),
                Text(
                  'SESSION CONTROLS',
                  style: GoogleFonts.barlowCondensed(
                    color: const Color(0xFFC6F10E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A3034)),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.logout,
                      color: Color(0xFFFF453A),
                    ),
                    title: Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFF453A),
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Returns to the sign-in screen',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: OutlinedButton(
                      key: SettingsScreen.keySignOutButton,
                      onPressed: () => _confirmSignOut(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF453A)),
                      ),
                      child: Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFF453A),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'DEVELOPER & JUDGE CONTROLS',
                  style: GoogleFonts.barlowCondensed(
                    color: const Color(0xFFC6F10E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A3034)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Background Job Simulation',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Executes the Serverpod DailyDecayFutureCall worker on demand to recalculate static shelf-life decay across all active racquets.',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          key: SettingsScreen.keyDevTriggerDecayButton,
                          onPressed: _isDecaying
                              ? null
                              : () => _triggerFutureCallDecay(context),
                          icon: _isDecaying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.bolt, color: Colors.black),
                          label: Text(
                            _isDecaying
                                ? 'Calculating Decay...'
                                : '⚡ Trigger FutureCall Decay',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC6F10E),
                            disabledBackgroundColor: const Color(
                              0xFFC6F10E,
                            ).withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFF2A3034), height: 1),
                      const SizedBox(height: 20),
                      Text(
                        'Time-Warp Aging Simulator',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fast-forwards string age by 30 days on your active gear to immediately observe static relaxation, radial gauge transitions, and critical shock risk warnings.',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          key: SettingsScreen.keyDevFastForwardButton,
                          onPressed: _isFastForwarding
                              ? null
                              : () => _fastForwardAging(context),
                          icon: _isFastForwarding
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.fast_forward,
                                  color: Colors.black,
                                ),
                          label: Text(
                            _isFastForwarding
                                ? 'Aging Stringbed...'
                                : 'Fast-Forward 30 Days',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC6F10E),
                            disabledBackgroundColor: const Color(
                              0xFFC6F10E,
                            ).withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The signed-in account: the email for an email user, the guest banner for
/// a guest, or generic text while the account type is unknown.
class _AccountCard extends StatelessWidget {
  final AccountInfo account;
  final String userId;

  const _AccountCard({required this.account, required this.userId});

  static const _volt = Color(0xFFC6F10E);

  @override
  Widget build(BuildContext context) {
    final email = account.email;
    final (
      String title,
      String subtitle,
      String badge,
    ) = switch (account.kind) {
      AccountKind.email => ('Email Account', 'Signed in with email', 'EMAIL'),
      AccountKind.guest => ('Guest Account', 'Anonymous session', 'GUEST'),
      AccountKind.signedOut => (
        'Signed Out',
        'No active session',
        'SIGNED OUT',
      ),
      AccountKind.unknown => ('Account', 'Signed in', 'ACTIVE'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3034)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3034),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  account.kind == AccountKind.email
                      ? Icons.email_outlined
                      : Icons.person_outline,
                  color: _volt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(color: _volt, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _volt.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _volt.withValues(alpha: 0.4)),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.barlowCondensed(
                    color: _volt,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2A3034), height: 1),
          const SizedBox(height: 16),
          if (email != null) ...[
            Text(
              'Email:',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            SelectableText(
              email,
              key: SettingsScreen.keyAccountEmail,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'User Identifier (AuthUserId):',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          SelectableText(
            userId,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (account.isGuest) ...[
            const SizedBox(height: 16),
            Container(
              key: SettingsScreen.keyGuestBanner,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F0A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF9F0A).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF9F0A),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your bag lives on this guest identity only. Signing out '
                      'or clearing this browser or device leaves it '
                      'unreachable.',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
