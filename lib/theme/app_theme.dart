import 'package:flutter/material.dart';

class BonnyColors extends ThemeExtension<BonnyColors> {
  const BonnyColors({
    required this.background,
    required this.surface,
    required this.secondarySurface,
    required this.cardTint,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.inverseText,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.supportAccent,
    required this.success,
    required this.warning,
    required this.strongWarning,
    required this.danger,
    required this.info,
    required this.border,
    required this.divider,
    required this.hero,
    required this.heroSecondary,
  });

  final Color background;
  final Color surface;
  final Color secondarySurface;
  final Color cardTint;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color inverseText;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color supportAccent;
  final Color success;
  final Color warning;
  final Color strongWarning;
  final Color danger;
  final Color info;
  final Color border;
  final Color divider;
  final Color hero;
  final Color heroSecondary;

  @override
  BonnyColors copyWith({
    Color? background,
    Color? surface,
    Color? secondarySurface,
    Color? cardTint,
    Color? primaryText,
    Color? secondaryText,
    Color? mutedText,
    Color? inverseText,
    Color? primaryAccent,
    Color? secondaryAccent,
    Color? supportAccent,
    Color? success,
    Color? warning,
    Color? strongWarning,
    Color? danger,
    Color? info,
    Color? border,
    Color? divider,
    Color? hero,
    Color? heroSecondary,
  }) {
    return BonnyColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      secondarySurface: secondarySurface ?? this.secondarySurface,
      cardTint: cardTint ?? this.cardTint,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      mutedText: mutedText ?? this.mutedText,
      inverseText: inverseText ?? this.inverseText,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      supportAccent: supportAccent ?? this.supportAccent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      strongWarning: strongWarning ?? this.strongWarning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      hero: hero ?? this.hero,
      heroSecondary: heroSecondary ?? this.heroSecondary,
    );
  }

  @override
  BonnyColors lerp(ThemeExtension<BonnyColors>? other, double t) {
    if (other is! BonnyColors) return this;
    return BonnyColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      secondarySurface: Color.lerp(
        secondarySurface,
        other.secondarySurface,
        t,
      )!,
      cardTint: Color.lerp(cardTint, other.cardTint, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      inverseText: Color.lerp(inverseText, other.inverseText, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      supportAccent: Color.lerp(supportAccent, other.supportAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      strongWarning: Color.lerp(strongWarning, other.strongWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      heroSecondary: Color.lerp(heroSecondary, other.heroSecondary, t)!,
    );
  }
}

class AppTheme {
  static const lightColors = BonnyColors(
    background: Color(0xFFF7F8FC),
    surface: Color(0xFFFFFFFF),
    secondarySurface: Color(0xFFF1F3F8),
    cardTint: Color(0xFFF4F5FA),
    primaryText: Color(0xFF131722),
    secondaryText: Color(0xFF6B7280),
    mutedText: Color(0xFF9AA3B2),
    inverseText: Color(0xFFFFFFFF),
    primaryAccent: Color(0xFF5E6AD2),
    secondaryAccent: Color(0xFF23C7A8),
    supportAccent: Color(0xFF8B93F8),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    strongWarning: Color(0xFFF97316),
    danger: Color(0xFFF43F5E),
    info: Color(0xFF3B82F6),
    border: Color(0xFFE7EAF1),
    divider: Color(0xFFEDF0F5),
    hero: Color(0xFF12141C),
    heroSecondary: Color(0xFF1A1D27),
  );

  static const darkColors = BonnyColors(
    background: Color(0xFF0D0F14),
    surface: Color(0xFF131722),
    secondarySurface: Color(0xFF1A1F2B),
    cardTint: Color(0xFF171B25),
    primaryText: Color(0xFFF5F7FB),
    secondaryText: Color(0xFFA5ADBA),
    mutedText: Color(0xFF7E8797),
    inverseText: Color(0xFFFFFFFF),
    primaryAccent: Color(0xFF7C88FF),
    secondaryAccent: Color(0xFF32D0B4),
    supportAccent: Color(0xFF8B93F8),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    strongWarning: Color(0xFFF97316),
    danger: Color(0xFFF43F5E),
    info: Color(0xFF3B82F6),
    border: Color(0xFF262C39),
    divider: Color(0xFF1E2430),
    hero: Color(0xFF131722),
    heroSecondary: Color(0xFF1A1F2B),
  );

  static ThemeData get light => _theme(Brightness.light, lightColors);

  static ThemeData get dark => _theme(Brightness.dark, darkColors);

  static ThemeData _theme(Brightness brightness, BonnyColors colors) {
    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: colors.primaryText,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: colors.primaryText,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.primaryText,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.primaryText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.primaryText,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: colors.secondaryText,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.secondaryText,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: colors.mutedText,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primaryAccent,
        onPrimary: colors.inverseText,
        secondary: colors.secondaryAccent,
        onSecondary: colors.primaryText,
        error: colors.danger,
        onError: colors.inverseText,
        surface: colors.surface,
        onSurface: colors.primaryText,
      ),
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[],
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colors.background,
        foregroundColor: colors.primaryText,
        titleTextStyle: textTheme.headlineMedium,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.secondarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primaryAccent, width: 1.4),
        ),
      ),
    ).copyWith(extensions: [colors]);
  }
}

extension BonnyTheme on BuildContext {
  BonnyColors get colors => Theme.of(this).extension<BonnyColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
