import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../client.dart' as app_client;
import '../services/auth_service.dart';

/// Settings screen displaying current authentication info, guest ID,
/// and stubbed account upgrade options (FR-2).
class SettingsScreen extends StatelessWidget {
  final AuthService? authService;

  const SettingsScreen({super.key, this.authService});

  AuthService get _authService => authService ?? app_client.authService;

  void _showLinkAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1E20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A3034)),
          ),
          title: Text(
            'Link Account',
            style: GoogleFonts.barlowCondensed(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Linking your account with Google or Email will preserve all your virtual gear bags, racquets, string logs, and health scores across devices and prevent data loss if you reinstall the app.',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _UpgradeOptionTile(
                icon: Icons.g_mobiledata,
                title: 'Continue with Google',
                subtitle: 'Sync gear across Android and iOS',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showLinkFeedback(context, 'Google linking preview enabled');
                },
              ),
              const SizedBox(height: 12),
              _UpgradeOptionTile(
                icon: Icons.email_outlined,
                title: 'Continue with Email',
                subtitle: 'Sign in with magic code or password',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showLinkFeedback(context, 'Email linking preview enabled');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white60),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLinkFeedback(BuildContext context, String message) {
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

  Future<void> _confirmReauthenticate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A3034)),
        ),
        title: Text(
          'Re-authenticate Guest?',
          style: GoogleFonts.barlowCondensed(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'This will generate a new anonymous guest identity. Your current session will be replaced.',
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
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC6F10E),
              foregroundColor: Colors.black,
            ),
            child: Text(
              'Re-authenticate',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _authService.loginAsGuest();
        if (context.mounted) {
          _showLinkFeedback(context, 'Guest session refreshed');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A3034)),
        ),
        title: Text(
          'Sign Out Device?',
          style: GoogleFonts.barlowCondensed(
            color: const Color(0xFFFF453A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Signing out will remove your guest session token from secure storage. You will lose access to data associated with this guest identity.',
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

    if (confirmed == true && context.mounted) {
      await _authService.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device signed out')),
        );
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
      body: ValueListenableBuilder(
        valueListenable: auth.authInfoListenable,
        builder: (context, authInfo, _) {
          final isAuthed = auth.isAuthenticated;
          final userId = auth.currentUserId ?? 'Not authenticated';

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
                Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                child: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFFC6F10E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Guest Account',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    isAuthed
                                        ? 'Anonymous session active'
                                        : 'Offline / Unauthenticated',
                                    style: GoogleFonts.inter(
                                      color: isAuthed
                                          ? const Color(0xFFC6F10E)
                                          : const Color(0xFFFF9F0A),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAuthed
                                  ? const Color(
                                      0xFFC6F10E,
                                    ).withValues(alpha: 0.15)
                                  : const Color(
                                      0xFFFF453A,
                                    ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isAuthed
                                    ? const Color(
                                        0xFFC6F10E,
                                      ).withValues(alpha: 0.4)
                                    : const Color(
                                        0xFFFF453A,
                                      ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              isAuthed ? 'ANONYMOUS' : 'DISCONNECTED',
                              style: GoogleFonts.barlowCondensed(
                                color: isAuthed
                                    ? const Color(0xFFC6F10E)
                                    : const Color(0xFFFF453A),
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
                      Text(
                        'User Identifier (AuthUserId):',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
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
                      const SizedBox(height: 16),
                      Text(
                        'Your racquets, string jobs, and tension decay data are currently stored under this anonymous guest account on this device.',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => _showLinkAccountDialog(context),
                          icon: const Icon(Icons.link, color: Colors.black),
                          label: Text(
                            'Link Google / Email',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC6F10E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.refresh,
                          color: Colors.white70,
                        ),
                        title: Text(
                          'Re-authenticate Guest',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Recreates an anonymous guest identity',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () => _confirmReauthenticate(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2A3034)),
                          ),
                          child: Text(
                            'Refresh',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFC6F10E),
                            ),
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFF2A3034)),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.logout,
                          color: Color(0xFFFF453A),
                        ),
                        title: Text(
                          'Sign Out Device',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF453A),
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Removes guest token from secure storage',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: OutlinedButton(
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

class _UpgradeOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _UpgradeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF121516),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A3034)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFC6F10E), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}
