import 'app_config.dart';

class DevConfig implements AppConfig {
  @override
  String get envName => 'DEV';

  @override
  String get apiBaseUrl => 'https://dev.api.mydida.local';

  @override
  bool get enableLogging => true;

  @override
  bool get enablePerformanceMonitor => true;

  @override
  String get dbName => 'mydida_dev';
}
