# Helper responsivo

```dart
import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  static double sp(BuildContext context, double size) {
    return size * (width(context) / 375);
  }

  static double hp(BuildContext context, double percent) {
    return width(context) * (percent / 100);
  }

  static double vp(BuildContext context, double percent) {
    return height(context) * (percent / 100);
  }

  static bool isMobile(BuildContext context) => width(context) < 600;
  static bool isTablet(BuildContext context) => width(context) >= 600 && width(context) < 900;
  static bool isDesktop(BuildContext context) => width(context) >= 900;
}
```

## Aplicacao pratica

- `sp`: tipografia, icones, raios, espacamentos pequenos.
- `hp`: espacamentos e margens horizontais.
- `vp`: espacamentos verticais e respiros.
