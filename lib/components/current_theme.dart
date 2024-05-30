/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/21/21, 11:05 AM
 */

import 'package:flutter/material.dart';

class CurrentTheme {
  static ThemeData? themeData;
  static Color? primaryColor;
  static Color? accentColor;
  static Color? backgroundColor;
  static Color? primaryLightColor;
  static Color? primaryDarkColor;
  static TextStyle? headline1;
  static TextStyle? headline2;
  static TextStyle? headline3;
  static TextStyle? headline4;
  static TextStyle? headline5;
  static TextStyle? headline6;
  static TextStyle? bodyText1;
  static TextStyle? bodyText2;
  static TextStyle? button;
  static TextStyle? caption;
  static TextStyle? overline;
  static TextStyle? subtitle1;
  static TextStyle? subtitle2;
  void init(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    themeData = theme;
    primaryColor = theme.primaryColor;
    accentColor = theme.colorScheme.secondary;
    backgroundColor = theme.colorScheme.surface;
    primaryLightColor = theme.primaryColorLight;
    primaryDarkColor = theme.primaryColorDark;
    headline1 = textTheme.displayLarge;
    headline2 = textTheme.displayMedium;
    headline3 = textTheme.displaySmall;
    headline4 = textTheme.headlineMedium;
    headline5 = textTheme.headlineSmall;
    headline6 = textTheme.titleLarge;
    bodyText1 = textTheme.bodyLarge;
    bodyText2 = textTheme.bodyMedium;
    button = textTheme.labelLarge;
    caption = textTheme.bodySmall;
    overline = textTheme.labelSmall;
    subtitle1 = textTheme.titleMedium;
    subtitle2 = textTheme.titleSmall;
  }
}
