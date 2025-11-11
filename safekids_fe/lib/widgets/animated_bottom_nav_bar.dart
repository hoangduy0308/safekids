import 'dart:math' show sin, pi;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'package:safekids_app/theme/app_typography.dart';

/// Modern Material 3 Animated Bottom Navigation Bar
///
/// Features:
/// - Flat design (no gradient)
/// - Bounce icon animation on selection
/// - Fade-in/out text transition
/// - Ripple effect on tap
/// - Light/dark mode support
/// - Floating effect with shadow
/// - Inspired by Notion, Linear, Apple Fitness+
class AnimatedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;
  final Color? backgroundColor;
  final Color? accentColor;
  final double height;
  final EdgeInsets margin;
  final BorderRadius borderRadius;
  final bool isLiquidGlass;
  final double blurSigma;

  const AnimatedBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.accentColor,
    this.height = 56,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 20),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.isLiquidGlass = true,
    this.blurSigma = 30.0,
  }) : super(key: key);

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar>
    with TickerProviderStateMixin {
  late Map<int, AnimationController> _bounceControllers;
  late Map<int, AnimationController> _fadeControllers;

  @override
  void initState() {
    super.initState();
    _bounceControllers = {};
    _fadeControllers = {};

    for (int i = 0; i < widget.items.length; i++) {
      _bounceControllers[i] = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
      _fadeControllers[i] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }

    // Trigger animation for initial index
    _triggerBounceAnimation(widget.currentIndex);
    _triggerFadeAnimation(widget.currentIndex);
  }

  void _triggerBounceAnimation(int index) {
    _bounceControllers[index]?.forward(from: 0.0);
  }

  void _triggerFadeAnimation(int index) {
    for (int i = 0; i < widget.items.length; i++) {
      if (i == index) {
        _fadeControllers[i]?.forward();
      } else {
        _fadeControllers[i]?.reverse();
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _triggerBounceAnimation(widget.currentIndex);
      _triggerFadeAnimation(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    for (var controller in _bounceControllers.values) {
      controller.dispose();
    }
    for (var controller in _fadeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        widget.backgroundColor ??
        (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white);
    final accentColor =
        widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final surfaceColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : Colors.grey.shade50;

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: widget.isLiquidGlass
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blurSigma,
                  sigmaY: widget.blurSigma,
                ),
                child: _buildNavContent(
                  accentColor,
                  surfaceColor,
                  isDarkMode,
                  backgroundColor,
                ),
              )
            : _buildNavContent(
                accentColor,
                surfaceColor,
                isDarkMode,
                backgroundColor,
              ),
      ),
    );
  }

  Widget _buildNavContent(
    Color accentColor,
    Color surfaceColor,
    bool isDarkMode,
    Color backgroundColor,
  ) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.isLiquidGlass
            ? (isDarkMode
                  ? Colors.grey.shade900.withOpacity(
                      0.8,
                    ) // Adjusted for consistency
                  : Colors.white.withOpacity(0.8)) // Adjusted for consistency
            : backgroundColor,
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.4) // Adjusted for prominence
              : Colors.white.withOpacity(0.4), // Adjusted for prominence
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          widget.items.length,
          (index) => _buildNavItem(
            context,
            item: widget.items[index],
            index: index,
            isActive: widget.currentIndex == index,
            accentColor: accentColor,
            backgroundColor: surfaceColor,
            bounceController: _bounceControllers[index]!,
            fadeController: _fadeControllers[index]!,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required NavBarItem item,
    required int index,
    required bool isActive,
    required Color accentColor,
    required Color backgroundColor,
    required AnimationController bounceController,
    required AnimationController fadeController,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDarkMode
        ? Colors.grey.shade600
        : Colors.grey.shade500;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.onTap(index);
          _triggerBounceAnimation(index);
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 41,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bounce animation for icon
              AnimatedBuilder(
                animation: bounceController,
                builder: (context, child) {
                  final bounce =
                      sin(bounceController.value * pi) * 3; // 3px bounce
                  return Transform.translate(
                    offset: Offset(0, -bounce),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: isActive
                      ? BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: Icon(
                    item.icon,
                    color: isActive ? accentColor : inactiveColor,
                    size: isActive ? 22 : 20,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              // Fade animation for label
              SizedBox(
                height: 12,
                child: FadeTransition(
                  opacity: fadeController,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: isActive ? 10 : 9,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? accentColor : inactiveColor,
                      letterSpacing: 0,
                      height: 1.1,
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

/// Navigation bar item model
class NavBarItem {
  final IconData icon;
  final String label;

  NavBarItem({required this.icon, required this.label});
}
