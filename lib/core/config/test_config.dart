import 'app_config.dart';

class TestConfig implements AppConfig {
  @override
  String get envName => 'TEST';

  @override
  String get apiBaseUrl => 'https://test.api.mydida.local';

  @override
  bool get enableLogging => true;

  @override
  bool get enablePerformanceMonitor => true;

  @override
  String get dbName => 'mydida_test';
}
