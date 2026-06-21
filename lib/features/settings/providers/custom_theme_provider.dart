//
//
// //TODO:这是一个自定义主题提供者，用于管理应用程序的主题设置。目的是将各种样式代码汇聚到一起，也算是解耦了吧……
// //TODO:未来可能会添加更多的主题选项和自定义功能，定义一个接口？把这东西存到 isar 中？？？？？
// class CustomThemeProvider {
//   static const String lightTheme = 'light';
//   static const String darkTheme = 'dark';
//   static const String systemTheme = 'system';
//
//   static const List<String> themes = [
//     lightTheme,
//     darkTheme,
//     systemTheme,
//   ];
//
//   static String currentTheme = lightTheme;
//
//   static void setTheme(String theme) {
//     if (themes.contains(theme)) {
//       currentTheme = theme;
//     } else {
//       throw ArgumentError('Invalid theme: $theme');
//     }
//   }
// }
