import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AdminFont {
  lato('Lato'),
  beVietnamPro('Be Vietnam Pro'),
  plusJakartaSans('Plus Jakarta Sans'),
  manrope('Manrope'),
  ibmPlexSans('IBM Plex Sans'),
  sourceSerif4('Source Serif 4');

  const AdminFont(this.family);
  final String family;

  TextStyle style({Color? color, FontWeight? fontWeight, double? fontSize}) =>
      GoogleFonts.getFont(
        family,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      );

  TextTheme textTheme() => GoogleFonts.getTextTheme(family);
}
