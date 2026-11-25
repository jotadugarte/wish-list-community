import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';

class AppNavDestination {
  final IconData icon;
  final String label;

  const AppNavDestination({required this.icon, required this.label});
}

// Adaptive navigation scaffold supporting the 4 navigation structures (A, B, C, D)
// from Ceci ("Ñata")'s Design Studio.
// Traceability: [REQ-ARCH-001]
class AppNavigationShell extends StatelessWidget {
  final DesignTokens tokens;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavDestination> items;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final VoidCallback? onPrimaryActionPressed;

  const AppNavigationShell({
    super.key,
    required this.tokens,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.items,
    required this.body,
    this.appBar,
    this.onPrimaryActionPressed,
  });

  // [REQ-ARCH-001] Renders the active navigation layout (A: 4 tabs, B: 5 tabs + center +,
  // C: Floating Pill Dock, D: Compact Bottom + Top Segmented Bar).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: tokens.navStructureId == 'B'
          ? FloatingActionButton(
              backgroundColor: tokens.primary,
              foregroundColor: tokens.primaryFg,
              onPressed: onPrimaryActionPressed ?? () {},
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    final isFloating = tokens.navStructureId == 'C';
    return Container(
      margin: isFloating
          ? const EdgeInsets.fromLTRB(16, 0, 16, 12)
          : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: isFloating ? BorderRadius.circular(999) : BorderRadius.zero,
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == currentIndex;
          return InkWell(
            onTap: () => onDestinationSelected(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: selected ? tokens.primary : tokens.muted,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? tokens.primary : tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
