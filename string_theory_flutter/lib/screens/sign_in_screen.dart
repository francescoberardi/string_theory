import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../client.dart' as app_client;
import '../theme/court_midnight_theme.dart';

/// First screen without a stored session: email sign-in or sign-up
/// (including the verification code step) and [Continue as guest].
///
/// It never navigates itself: once a sign-in succeeds the auth gate in
/// `main.dart` swaps it for the bag.
class SignInScreen extends StatefulWidget {
  /// Overrides the global client used by the email flow.
  final Client? client;

  /// Starts a guest session; defaults to `authService.continueAsGuest`.
  final Future<bool> Function()? onContinueAsGuest;

  const SignInScreen({super.key, this.client, this.onContinueAsGuest});

  static const keyEmailSignIn = Key('sign_in_email_form');
  static const keyContinueAsGuestButton = Key(
    'sign_in_continue_as_guest_button',
  );
  static const keyGuestError = Key('sign_in_guest_error');
  static const keyGuestRetryButton = Key('sign_in_guest_retry_button');

  /// Shown when the guest session can't be created (e.g. offline).
  static const guestErrorMessage =
      "Couldn't start a guest session. Check your connection and try again.";

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _guestInFlight = false;
  bool _guestFailed = false;

  Future<void> _continueAsGuest() async {
    if (_guestInFlight) return;
    setState(() {
      _guestInFlight = true;
      _guestFailed = false;
    });
    final continueAsGuest =
        widget.onContinueAsGuest ?? app_client.authService.continueAsGuest;
    var signedIn = false;
    try {
      signedIn = await continueAsGuest();
    } catch (e) {
      debugPrint('SignInScreen: guest sign-in failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _guestInFlight = false;
      _guestFailed = !signedIn;
    });
  }

  void _showEmailError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$error',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: CourtMidnightTheme.healthCritical,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourtMidnightTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.sports_tennis,
                    size: 48,
                    color: CourtMidnightTheme.primaryVolt,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'STRING THEORY',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.barlowCondensed(
                      color: CourtMidnightTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Know when your strings are dead before your elbow does.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: CourtMidnightTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CourtMidnightTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CourtMidnightTheme.surfaceBorder,
                      ),
                    ),
                    child: EmailSignInWidget(
                      key: SignInScreen.keyEmailSignIn,
                      client: widget.client ?? app_client.client,
                      startScreen: EmailFlowScreen.login,
                      onError: _showEmailError,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: CourtMidnightTheme.surfaceBorder),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: GoogleFonts.inter(
                            color: CourtMidnightTheme.textTertiary,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: CourtMidnightTheme.surfaceBorder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      key: SignInScreen.keyContinueAsGuestButton,
                      onPressed: _guestInFlight ? null : _continueAsGuest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CourtMidnightTheme.primaryVolt,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: CourtMidnightTheme.primaryVolt
                            .withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _guestInFlight
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.person_outline),
                      label: Text(
                        'Continue as guest',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No account needed. Your bag lives on this guest '
                    'identity only.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: CourtMidnightTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  if (_guestFailed) ...[
                    const SizedBox(height: 16),
                    _GuestErrorBanner(onRetry: _continueAsGuest),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _GuestErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: SignInScreen.keyGuestError,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: CourtMidnightTheme.healthCriticalBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CourtMidnightTheme.healthCritical.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            color: CourtMidnightTheme.healthCritical,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              SignInScreen.guestErrorMessage,
              style: GoogleFonts.inter(
                color: CourtMidnightTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            key: SignInScreen.keyGuestRetryButton,
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                color: CourtMidnightTheme.primaryVolt,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
