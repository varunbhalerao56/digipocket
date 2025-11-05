part of 'themes.dart';

class AppTheme {
  static ThemeData get lightTheme => AppThemeData.lightTheme;
}

class AppThemeData {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Poppins',
      textTheme: _textTheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: UIColors.background,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UIColors.primary,
          foregroundColor: UIColors.background,
          iconColor: UIColors.background,
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: UIColors.shadow,
          elevation: 4,
          enableFeedback: true,
          enabledMouseCursor: SystemMouseCursors.click,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: UIColors.background,
        foregroundColor: UIColors.primary,
        elevation: 4,
        titleTextStyle: _textTheme.bodyMedium?.copyWith(color: UIColors.primary),
        centerTitle: true,
        surfaceTintColor: UIColors.background,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: UIColors.background,
        selectedItemColor: UIColors.primary,
        unselectedItemColor: UIColors.secondary,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: UIColors.primary,
          foregroundColor: UIColors.background,
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16)),
          enableFeedback: true,
          enabledMouseCursor: SystemMouseCursors.click,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: UIColors.background,
          foregroundColor: UIColors.primary,
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16)),
          enableFeedback: true,
          enabledMouseCursor: SystemMouseCursors.click,
          iconColor: UIColors.primary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: UIColors.card,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: UIColors.secondary.withAlpha(35)),
        labelStyle: TextStyle(color: UIColors.primary),
        deleteIconColor: UIColors.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: UIColors.primary,
        linearTrackColor: UIColors.secondary.withAlpha(35),
        circularTrackColor: UIColors.secondary.withAlpha(35),
        trackGap: 4,
        strokeCap: StrokeCap.round,
        borderRadius: BorderRadius.circular(16),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: UIColors.success,
        textColor: UIColors.background,
        textStyle: TextStyle(fontSize: 8),
        largeSize: 16,
        smallSize: 12,
        padding: EdgeInsets.all(1),
        offset: Offset(5, -5),
      ),
      iconTheme: IconThemeData(color: UIColors.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(UIColors.primary),
        trackColor: WidgetStateProperty.all(UIColors.secondary.withAlpha(35)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return UIColors.primary;
          }
          return UIColors.secondary.withAlpha(35);
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        overlayColor: WidgetStateProperty.all(UIColors.secondary.withAlpha(35)),
        side: BorderSide(color: UIColors.secondary.withAlpha(35)),
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(4)),
        mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
      ),
      cardTheme: CardThemeData(
        color: UIColors.card,
        shadowColor: const Color.fromARGB(20, 10, 0, 0),
        shape: RoundedSuperellipseBorder(
          // side: BorderSide(color: AppColors.textbox, width: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        surfaceTintColor: UIColors.card,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: UIColors.primary,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16)),
        showCloseIcon: true,
        closeIconColor: UIColors.background,
        behavior: SnackBarBehavior.fixed,
        elevation: 4,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: UIColors.primary,
        foregroundColor: UIColors.background,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 4,
        enableFeedback: true,
      ),
      dividerTheme: DividerThemeData(color: UIColors.secondary.withAlpha(35), thickness: 1, space: 16),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: UIColors.card,
        isDense: true,
        focusColor: UIColors.primary,

        labelStyle: TextStyle(color: UIColors.placeholder),
        hintStyle: TextStyle(color: UIColors.placeholder),
        iconColor: UIColors.primary,
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(0)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(0)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(0)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: UIColors.primary,
        selectionColor: UIColors.primary.withAlpha(50),
        selectionHandleColor: UIColors.primary,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: UIColors.primary,
        scaffoldBackgroundColor: UIColors.background,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return UIColors.primary;
          }
          return UIColors.secondary.withAlpha(80);
        }),
      ),
      colorSchemeSeed: UIColors.primary,
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(UIColors.card),
          shape: WidgetStateProperty.all(RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16))),
          side: WidgetStateProperty.all(BorderSide(color: UIColors.border, width: 0.25)),
          elevation: WidgetStateProperty.all(4),
          padding: WidgetStateProperty.all(EdgeInsets.all(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: UIColors.card,
          isDense: true,
          focusColor: UIColors.primary,
          hoverColor: UIColors.primary,
          labelStyle: TextStyle(color: UIColors.placeholder),
          hintStyle: TextStyle(color: UIColors.placeholder),
          iconColor: UIColors.primary,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: UIColors.border, width: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: UIColors.border, width: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: UIColors.border, width: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
