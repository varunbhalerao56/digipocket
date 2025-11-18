part of 'themes.dart';

/// UI text style utilities
class UITextStyles {
  UITextStyles._();

  static const String _fontFamily = "Poppins";

  // Large Title (used for the main screen title)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle largeTitlePrimary = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle largeTitleSecondary = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  // Title 1 (used for primary view titles)
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle title1Primary = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle title1Secondary = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  // Title 2 (used for section titles)
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle title2Primary = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle title2Secondary = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  // Title 3 (used for subsection titles)
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle title3Primary = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle title3Secondary = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  // Headline (emphasized heading in content)
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle headlinePrimary = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle headlineSecondary = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  // Body (default text style - most used)
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle bodyPrimary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle bodyBoldPrimary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  static const TextStyle bodyBoldSecondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  // Callout (for emphasized text or short descriptions)
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle calloutPrimary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle calloutSecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  // Subheadline (for secondary text)
  static const TextStyle subheadline = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle subheadlineBold = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle subheadlinePrimary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle subheadlineBoldPrimary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle subheadlineSecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  static const TextStyle subheadlineBoldSecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  // Footnote (for auxiliary information)
  static const TextStyle footnote = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle footnotePrimary = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle footnoteSecondary = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  // Caption (for labels and annotations)
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: UIColors.primary, // onBackground
    fontFamily: _fontFamily,
  );

  static const TextStyle captionPrimary = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle captionBoldPrimary = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: UIColors.primary, // primary
    fontFamily: _fontFamily,
  );

  static const TextStyle captionSecondary = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  static const TextStyle captionBoldSecondary = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: UIColors.secondary, // secondary
    fontFamily: _fontFamily,
  );

  // Custom text style builder
  static TextStyle custom({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = UIColors.primary,
    bool italic = false,
    String fontFamily = _fontFamily,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      fontFamily: fontFamily,
    );
  }
}
