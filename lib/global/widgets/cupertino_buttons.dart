// cupertino_buttons.dart
import 'package:digipocket/global/themes/themes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Primary filled button (matches ElevatedButton/FilledButton)
class UIPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double minSize;

  const UIPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.minSize = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: onPressed != null ? UIColors.primary : UIColors.secondary.withAlpha(80),
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(borderRadius)),
        shadows: [BoxShadow(color: UIColors.shadow, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: CupertinoButton(
        onPressed: onPressed,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        borderRadius: BorderRadius.zero,
        color: Colors.transparent,
        minimumSize: Size(minSize, minSize),
        child: DefaultTextStyle(
          style: UITextStyles.bodyBold.copyWith(color: UIColors.background),
          child: child,
        ),
      ),
    );
  }
}

/// Text button (matches TextButton)
class UITextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double minSize;

  const UITextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.minSize = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: UIColors.background,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(borderRadius)),
      ),
      child: CupertinoButton(
        onPressed: onPressed,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        borderRadius: BorderRadius.zero,
        color: Colors.transparent,
        minimumSize: Size(minSize, minSize),
        child: DefaultTextStyle(
          style: UITextStyles.bodyBold.copyWith(color: UIColors.primary),
          child: child,
        ),
      ),
    );
  }
}

/// Borderless button (simple text-only button)
class UIBorderlessButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double minSize;

  const UIBorderlessButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.minSize = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      minimumSize: Size(minSize, minSize),
      child: DefaultTextStyle(style: UITextStyles.calloutPrimary, child: child),
    );
  }
}

/// Outlined button variant
class UIOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double minSize;
  final double borderWidth;

  const UIOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.minSize = 44.0,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: UIColors.primary, width: borderWidth),
        ),
      ),
      child: CupertinoButton(
        onPressed: onPressed,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        borderRadius: BorderRadius.zero,
        color: Colors.transparent,
        minimumSize: Size(minSize, minSize),
        child: DefaultTextStyle(
          style: UITextStyles.bodyBold.copyWith(color: UIColors.primary),
          child: child,
        ),
      ),
    );
  }
}

/// Icon button
class UIIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final double size;
  final Color? color;

  const UIIconButton({super.key, required this.onPressed, required this.icon, this.size = 44.0, this.color});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      minimumSize: Size(size, size),
      child: IconTheme(
        data: IconThemeData(color: color ?? UIColors.primary, size: size * 0.6),
        child: icon,
      ),
    );
  }
}
