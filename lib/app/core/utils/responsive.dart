import 'package:flutter/material.dart';

class Responsive {
  // Largura e altura da tela
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Escala proporcional baseada em design de referência (375px = iPhone padrão)
  static double sp(BuildContext context, double size) {
    return size * (width(context) / 375);
  }

  // Padding proporcional horizontal (% da largura)
  static double hp(BuildContext context, double percent) {
    return width(context) * (percent / 100);
  }

  // Padding proporcional vertical (% da altura)
  static double vp(BuildContext context, double percent) {
    return height(context) * (percent / 100);
  }

  // Verifica o tipo de dispositivo
  static bool isMobile(BuildContext context) => width(context) < 600;
  static bool isTablet(BuildContext context) =>
      width(context) >= 600 && width(context) < 900;
  static bool isDesktop(BuildContext context) => width(context) >= 900;
}
