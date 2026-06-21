import 'app_config.dart';

class ProdConfig implements AppConfig {
  @override
  String get envName => 'PROD';

  @override
  String get apiBaseUrl => 'https://api.mydida.com';

  @override
  bool get enableLogging => false;

  @override
  bool get enablePerformanceMonitor => false;

  @override
  String get dbName => 'mydida_prod';
}
