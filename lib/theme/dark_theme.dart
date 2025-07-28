// import 'package:flutter/material.dart';
//
// ThemeData dark = ThemeData(
//   fontFamily: 'Roboto',
//   primaryColor: const Color(0xFF54b46b),
//   secondaryHeaderColor: const Color(0xFF009f67),
//   disabledColor: const Color(0xFF6f7275),
//   brightness: Brightness.dark,
//   hintColor: const Color(0xFFbebebe),
//   cardColor: Colors.black,
//   textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFF54b46b))),
//   colorScheme: const ColorScheme.dark(primary: Color(0xFF54b46b), secondary: Color(0xFF54b46b)).copyWith(error: const Color(0xFFdd3135)),
//   popupMenuTheme: const PopupMenuThemeData(color: Color(0xFF29292D), surfaceTintColor: Color(0xFF29292D)),
//   dialogTheme: const DialogTheme(surfaceTintColor: Colors.white10),
//   floatingActionButtonTheme: FloatingActionButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
//   bottomAppBarTheme: const BottomAppBarTheme(color: Colors.black, height: 60, padding: EdgeInsets.symmetric(vertical: 5)),
//   dividerTheme: const DividerThemeData(thickness: 0.2, color: Color(0xFFA0A4A8)),
// );


import 'package:flutter/material.dart';
import 'package:sixam_mart_delivery/util/myColore.dart';

ThemeData dark = ThemeData(
  fontFamily: 'Roboto',
  primaryColor: AppColors.primaryColor,
  secondaryHeaderColor: AppColors.secondaryColor,
  disabledColor: AppColors.disabledColor,
  brightness: Brightness.dark,
  hintColor: AppColors.hintColor,
  cardColor: AppColors.black,

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryColor,
    ),
  ),

  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryColor,
    secondary: AppColors.primaryColor,
  ).copyWith(
    error: AppColors.errorColor,
  ),

  popupMenuTheme: const PopupMenuThemeData(
    color: AppColors.darkPopup,
    surfaceTintColor: AppColors.darkPopup,
  ),

  // dialogTheme:  DialogTheme(
  //   surfaceTintColor: Colors.white10,
  // ),
  dialogTheme: const DialogThemeData(
    surfaceTintColor: Colors.white10,
  ),


  floatingActionButtonTheme: FloatingActionButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(500),
    ),
  ),

  bottomAppBarTheme:  BottomAppBarTheme(
    color: AppColors.black,
    height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),

  dividerTheme: const DividerThemeData(
    thickness: 0.2,
    color: AppColors.divider,
  ),
);
