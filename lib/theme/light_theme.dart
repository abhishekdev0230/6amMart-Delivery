// import 'package:flutter/material.dart';
//
// ThemeData light = ThemeData(
//   fontFamily: 'Roboto',
//   primaryColor: const Color(0xFF2A9849),
//   secondaryHeaderColor: const Color(0xFF1ED7AA),
//   disabledColor: const Color(0xFFA0A4A8),
//   brightness: Brightness.light,
//   hintColor: const Color(0xFF9F9F9F),
//   cardColor: Colors.white,
//   textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFF2A9849))),
//   colorScheme: const ColorScheme.light(primary: Color(0xFF2A9849), secondary: Color(0xFF2A9849)).copyWith(error: const Color(0xFFE84D4F)),
//   popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.white),
//   dialogTheme: const DialogTheme(surfaceTintColor: Colors.white),
//   floatingActionButtonTheme: FloatingActionButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
//   bottomAppBarTheme: const BottomAppBarTheme(color: Colors.white, height: 60, padding: EdgeInsets.symmetric(vertical: 5)),
//   dividerTheme: const DividerThemeData(thickness: 0.2, color: Color(0xFFA0A4A8)),
// );


import 'package:flutter/material.dart';
import 'package:sixam_mart_delivery/util/myColore.dart';

ThemeData light = ThemeData(
  fontFamily: 'Roboto',
  primaryColor: AppColors.primaryColor,
  secondaryHeaderColor: AppColors.secondaryColor,
  disabledColor: AppColors.disabledColor,
  brightness: Brightness.light,
  hintColor: AppColors.hintColor,
  cardColor: AppColors.white,

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryColor,
    ),
  ),

  colorScheme: const ColorScheme.light(
    primary: AppColors.primaryColor,
    secondary: AppColors.primaryColor,
  ).copyWith(
    error: AppColors.errorColor,
  ),

  popupMenuTheme: const PopupMenuThemeData(
    color: AppColors.white,
    surfaceTintColor: AppColors.white,
  ),

  // dialogTheme: const DialogTheme(
  //   surfaceTintColor: AppColors.white,
  // ),
  dialogTheme: const DialogThemeData(
    surfaceTintColor: Colors.white10,
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(500),
    ),
  ),

  bottomAppBarTheme: const BottomAppBarTheme(
    color: AppColors.white,
    height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),

  dividerTheme: DividerThemeData(
    thickness: 0.2,
    color: AppColors.divider,
  ),
);
