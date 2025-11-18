part of 'themes.dart';

class UIInputDecoration {
  UIInputDecoration._();

  static InputDecoration defaultStyle({
    String? labelText,
    required String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool? enabled = true,
  }) {
    return InputDecoration(
      isDense: true,

      contentPadding: UIInsets.sm,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: UIColors.textbox, width: 1.5),

        borderRadius: UIRadius.mdBorder,
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: UIColors.textbox, width: 1.5),
        borderRadius: UIRadius.mdBorder,
      ),
      disabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: UIColors.textbox, width: 0.8),
        borderRadius: UIRadius.mdBorder,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: UIColors.card, width: 2),
        borderRadius: UIRadius.mdBorder,
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: UIColors.error, width: 1.5),
        borderRadius: UIRadius.mdBorder,
      ),
      hintText: hintText,
      fillColor: enabled == false ? Colors.grey.shade100 : UIColors.background,
      filled: true,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      counterStyle: UITextStyles.caption.copyWith(color: UIColors.secondary),
      label: labelText != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UISpacing.sm,
                vertical: UISpacing.xs,
              ),
              decoration: const BoxDecoration(
                color: UIColors.card,
                borderRadius: UIRadius.smBorder,
              ),
              child: Text(
                labelText.toUpperCase(),
                style: UITextStyles.caption.copyWith(
                  color: UIColors.card,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  static InputDecoration hintStyle({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: const OutlineInputBorder(borderRadius: UIRadius.smBorder),
      contentPadding: UIInsets.sm,
    );
  }
}

/// UI spacing constants
class UISpacing {
  UISpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 28.0;
}

/// Spacing box widgets for vertical and horizontal spacing
class UIGap {
  UIGap._();

  // Vertical spacing
  static Widget xsVertical() => const SizedBox(height: UISpacing.xs);

  static Widget sVertical() => const SizedBox(height: UISpacing.sm);

  static Widget mdVertical() => const SizedBox(height: UISpacing.md);

  static Widget lVertical() => const SizedBox(height: UISpacing.lg);

  static Widget xlVertical() => const SizedBox(height: UISpacing.xl);

  // Horizontal spacing
  static Widget xsHorizontal() => const SizedBox(width: UISpacing.xs);

  static Widget sHorizontal() => const SizedBox(width: UISpacing.sm);

  static Widget mdHorizontal() => const SizedBox(width: UISpacing.md);

  static Widget lHorizontal() => const SizedBox(width: UISpacing.lg);

  static Widget xlHorizontal() => const SizedBox(width: UISpacing.xl);
}

/// UI padding utilities
class UIInsets {
  UIInsets._();

  // Basic padding values
  static const EdgeInsets xs = EdgeInsets.all(UISpacing.xs);
  static const EdgeInsets sm = EdgeInsets.all(UISpacing.sm);
  static const EdgeInsets md = EdgeInsets.all(UISpacing.md);
  static const EdgeInsets l = EdgeInsets.all(UISpacing.lg);
  static const EdgeInsets xl = EdgeInsets.all(UISpacing.xl);

  // Directional padding (const versions with md)
  static const EdgeInsets left = EdgeInsets.only(left: UISpacing.md);
  static const EdgeInsets right = EdgeInsets.only(right: UISpacing.md);
  static const EdgeInsets top = EdgeInsets.only(top: UISpacing.md);
  static const EdgeInsets bottom = EdgeInsets.only(bottom: UISpacing.md);
  static const EdgeInsets horizontal = EdgeInsets.symmetric(
    horizontal: UISpacing.md,
  );
  static const EdgeInsets vertical = EdgeInsets.symmetric(
    vertical: UISpacing.md,
  );
}

/// UI radius utilities
class UIRadius {
  UIRadius._();

  // Basic radius values
  static const Radius xs = Radius.circular(UISpacing.xs);
  static const Radius sm = Radius.circular(UISpacing.sm);
  static const Radius md = Radius.circular(UISpacing.md);
  static const Radius l = Radius.circular(UISpacing.lg);
  static const Radius xl = Radius.circular(UISpacing.xl);

  // Border radius values
  static const BorderRadius xsBorder = BorderRadius.all(xs);
  static const BorderRadius smBorder = BorderRadius.all(sm);
  static const BorderRadius mdBorder = BorderRadius.all(md);
  static const BorderRadius lBorder = BorderRadius.all(l);
  static const BorderRadius xlBorder = BorderRadius.all(xl);

  // Directional border radius
  static const BorderRadius top = BorderRadius.vertical(top: md);
  static const BorderRadius bottom = BorderRadius.vertical(bottom: md);
  static const BorderRadius right = BorderRadius.horizontal(right: md);
  static const BorderRadius left = BorderRadius.horizontal(left: md);

  // RoundedSuperellipseBorder for buttons and cards
  static const RoundedSuperellipseBorder xsShape = RoundedSuperellipseBorder(
    borderRadius: xsBorder,
  );
  static const RoundedSuperellipseBorder smShape = RoundedSuperellipseBorder(
    borderRadius: smBorder,
  );
  static const RoundedSuperellipseBorder mdShape = RoundedSuperellipseBorder(
    borderRadius: mdBorder,
  );
  static const RoundedSuperellipseBorder lShape = RoundedSuperellipseBorder(
    borderRadius: lBorder,
  );
  static const RoundedSuperellipseBorder xlShape = RoundedSuperellipseBorder(
    borderRadius: xlBorder,
  );
}

/// UI divider utilities
class UIDivider {
  UIDivider._();

  // Thickness constants
  static const double thin = 0.5;
  static const double medium = 1.0;
  static const double thick = 1.5;

  // Horizontal dividers
  static const Widget horizontal = Divider(height: 1, thickness: thin);
  static const Widget horizontalMedium = Divider(height: 1, thickness: medium);
  static const Widget horizontalThick = Divider(height: 1, thickness: thick);

  // Vertical dividers
  static const Widget vertical = VerticalDivider(width: 1, thickness: thin);
  static const Widget verticalMedium = VerticalDivider(
    width: 1,
    thickness: medium,
  );
  static const Widget verticalThick = VerticalDivider(
    width: 1,
    thickness: thick,
  );
}

/// UI border utilities
class UIBorders {
  UIBorders._();

  // Border width constants
  static const double thin = 1.0;
  static const double medium = 2.0;
  static const double thick = 3.0;

  // BorderSide constants
  static const BorderSide thinSide = BorderSide(
    width: thin,
    color: Color(0xFFE0E0E0),
  );
  static const BorderSide mediumSide = BorderSide(
    width: medium,
    color: Color(0xFFE0E0E0),
  );
  static const BorderSide thickSide = BorderSide(
    width: thick,
    color: Color(0xFFE0E0E0),
  );

  // All sides borders
  static const Border all = Border.fromBorderSide(thinSide);
  static const Border allMedium = Border.fromBorderSide(mediumSide);
  static const Border allThick = Border.fromBorderSide(thickSide);

  // Directional borders
  static const Border top = Border(top: thinSide);
  static const Border bottom = Border(bottom: thinSide);
  static const Border left = Border(left: thinSide);
  static const Border right = Border(right: thinSide);

  // Horizontal and vertical borders
  static const Border horizontal = Border(top: thinSide, bottom: thinSide);
  static const Border vertical = Border(left: thinSide, right: thinSide);
}

/// UI shadow utilities
class UIShadows {
  UIShadows._();

  // No shadow
  static const List<BoxShadow> none = [];

  // Small shadow - subtle elevation
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D000000), // ~5% opacity
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  // Medium shadow - standard elevation
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000), // ~10% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0D000000), // ~5% opacity
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  // Large shadow - prominent elevation
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A000000), // ~10% opacity
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0D000000), // ~5% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Extra large shadow - maximum elevation
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x26000000), // ~15% opacity
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x1A000000), // ~10% opacity
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

/// UI duration utilities for animations
class UIDurations {
  UIDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

/// UI size utilities for common UI elements
class UISizes {
  UISizes._();

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;

  // Button heights
  static const double buttonSm = 32.0;
  static const double buttonMd = 40.0;
  static const double buttonLg = 48.0;

  // Avatar sizes
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 80.0;
}

/// UI opacity utilities
class UIOpacity {
  UIOpacity._();

  static const int invisible = 0;
  static const int disabled = 97;
  static const int medium = 124;
  static const int high = 170;
  static const int visible = 255;
}

/// UI elevation utilities for Material elevation levels
class UIElevation {
  UIElevation._();

  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 2.0;
  static const double level3 = 4.0;
  static const double level4 = 6.0;
  static const double level5 = 8.0;
}
