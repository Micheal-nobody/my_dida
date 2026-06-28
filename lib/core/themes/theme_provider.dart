import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/color_constants.dart';
import 'package:provider/provider.dart';

/// ThemeProvider to handle dynamic theme changes and notifications
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._theme);
  ColorTheme _theme;

  ColorTheme get theme => _theme;

  void setTheme(ColorTheme newTheme) {
    if (_theme != newTheme) {
      _theme = newTheme;
      notifyListeners();
    }
  }
}

/// Helper extension to easily access the current theme via BuildContext
extension ThemeContext on BuildContext {
  ColorTheme get theme => Provider.of<ColorTheme>(this);
}
