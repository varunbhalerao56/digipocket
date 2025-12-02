import 'package:digipocket/global/themes/themes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Custom Cupertino-style Filter Chip
class CupertinoFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const CupertinoFilterChip({super.key, required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelected();
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: ShapeDecoration(
          color: selected ? UIColors.logo : UIColors.background.withAlpha(40),
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: selected ? UIColors.logo : UIColors.background.withAlpha(60), width: 1),
          ),
        ),
        child: Text(
          label,
          style: UITextStyles.subheadline.copyWith(
            color: selected ? UIColors.primary : UIColors.background,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class CupertinoFilterChipSecondary extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const CupertinoFilterChipSecondary({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: ShapeDecoration(
          color: selected ? UIColors.logo : UIColors.primary.withAlpha(40),
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: selected ? UIColors.logo : UIColors.primary.withAlpha(50), width: 1),
          ),
        ),
        child: Text(
          label,
          style: UITextStyles.subheadline.copyWith(
            color: selected ? UIColors.primary : UIColors.primary.withAlpha(230),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

void showCupertinoSnackbar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _AnimatedSnackbar(message: message, onDismiss: () => overlayEntry.remove()),
  );

  overlay.insert(overlayEntry);
}

class _AnimatedSnackbar extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _AnimatedSnackbar({required this.message, required this.onDismiss});

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation
    _controller.forward();

    // Dismiss after delay
    Future.delayed(const Duration(seconds: 2), _dismiss);
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.success),
              child: Text(
                widget.message,
                style: UITextStyles.body.copyWith(color: UIColors.background),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
