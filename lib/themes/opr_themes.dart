import 'package:flutter/material.dart';
import 'package:mobile/themes/opr_colors.dart';

enum OPRThemeKeys { LIGHT, DARK }

class OPRThemes {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: Colors.blue,
    brightness: Brightness.light,
    accentColor: OPRColors.accentLight,
    canvasColor: Colors.transparent,
    bottomAppBarColor: OPRColors.bottomNavBackgroundLight,
    unselectedWidgetColor: OPRColors.unselectedLight,
    backgroundColor: OPRColors.backgroundColorLight,
    dividerColor: OPRColors.dividerColorLight,
    textTheme: TextTheme(
      headline: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500, color: OPRColors.primaryTextColorLight),
      caption: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: OPRColors.primaryTextColorLight),
      title: TextStyle(
          fontSize: 16.0,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          color: OPRColors.primaryTextColorLight),
      display1: TextStyle(
          fontSize: 16.0,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          color: OPRColors.secondaryTextColorLight),
      display2: TextStyle(
          fontSize: 16.0,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w500,
          color: OPRColors.textButtonCaptionLight),
      subhead: TextStyle(
          fontSize: 14.0,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          color: OPRColors.secondaryTextColorLight),
      subtitle: TextStyle(
          fontSize: 12.0,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          color: OPRColors.secondaryTextColorLight),
      button: TextStyle(
          fontSize: 16.0, fontStyle: FontStyle.normal, fontWeight: FontWeight.w500, color: OPRColors.accentLight),
    ),
    fontFamily: 'IBMPlexSans',
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: Colors.grey,
    brightness: Brightness.dark,
    accentColor: OPRColors.accentDark,
    canvasColor: Colors.transparent,
    bottomAppBarColor: OPRColors.bottomNavBackgroundDark,
    unselectedWidgetColor: OPRColors.unselectedDark,
    backgroundColor: OPRColors.backgroundColorDark,
    dividerColor: OPRColors.dividerColorDark,
    textTheme: TextTheme(
      headline: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500, color: OPRColors.primaryTextColorDark),
      caption: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: OPRColors.primaryTextColorDark),
      title: TextStyle(
          fontSize: 16.0,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          color: OPRColors.primaryTextColorDark),
      display1: TextStyle(
          fontSize: 16.0,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          color: OPRColors.secondaryTextColorDark),
      display2: TextStyle(
          fontSize: 16.0,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w500,
          color: OPRColors.textButtonCaptionDark),
      subhead: TextStyle(
          fontSize: 14.0,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          color: OPRColors.secondaryTextColorDark),
      subtitle: TextStyle(
          fontSize: 12.0,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          color: OPRColors.secondaryTextColorDark),
      button: TextStyle(
          fontSize: 16.0, fontStyle: FontStyle.normal, fontWeight: FontWeight.normal, color: OPRColors.accentDark),
    ),
    fontFamily: 'IBMPlexSans',
  );

  static final OPRThemeData oprLightTheme = OPRThemeData(lightTheme);
  static final OPRThemeData oprDarkTheme = OPRThemeData(darkTheme);

  static OPRThemeData getThemeFromKey(OPRThemeKeys themeKey) {
    switch (themeKey) {
      case OPRThemeKeys.LIGHT:
        return oprLightTheme;
      case OPRThemeKeys.DARK:
        return oprDarkTheme;
      default:
        return oprLightTheme;
    }
  }
}

class OPRThemeData {
  final ThemeData baseTheme;
  final Color ratingStarColor;
  final Color unselectedBottomBarItemColor;
  final Color mapButtonBackgroundColor;

  factory OPRThemeData(ThemeData baseTheme) {
    final bool isDark = baseTheme.brightness == Brightness.dark;
    final ratingStarColor = isDark ? OPRColors.ratingStarColorDark : OPRColors.ratingStarColorLight;
    final unselectedBottomBarItemColor = isDark ? OPRColors.unselectedBottomBarItemDark : OPRColors.unselectedBottomBarItemLight;
    final mapButtonBackgroundColor = isDark ? OPRColors.mapButtonBackgroundDark : OPRColors.mapButtonBackgroundLight;

    return OPRThemeData.raw(
      baseTheme: baseTheme,
      ratingStarColor: ratingStarColor,
      unselectedBottomBarItemColor: unselectedBottomBarItemColor,
      mapButtonBackgroundColor: mapButtonBackgroundColor,
    );
  }

  const OPRThemeData.raw({
    @required this.baseTheme,
    @required this.ratingStarColor,
    @required this.unselectedBottomBarItemColor,
    @required this.mapButtonBackgroundColor,
  })  : assert(baseTheme != null),
        assert(ratingStarColor != null),
        assert(unselectedBottomBarItemColor != null),
        assert(mapButtonBackgroundColor != null);
}
