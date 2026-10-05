import 'package:flutter/material.dart';

import '../../theme/court_midnight_theme.dart';

/// Rounded bottom-sheet chrome: drag pill, keyboard inset padding, a
/// scrollable body and a footer pinned below it.
class AssignmentSheetFrame extends StatelessWidget {
  final List<Widget> children;
  final Widget footer;

  const AssignmentSheetFrame({
    super.key,
    required this.children,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: CourtMidnightTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: CourtMidnightTheme.surfaceBorder),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Top drag pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CourtMidnightTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}
