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
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(30),
          decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.success),
          child: Text(
            message,
            style: TextStyle(color: CupertinoColors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  Future.delayed(Duration(seconds: 2), () => overlayEntry.remove());
}
