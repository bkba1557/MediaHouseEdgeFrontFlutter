class AppConfig {
  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.8.230:6019/api',
  );
  // static const String _rawApiBaseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'https://mediahouseedgebackexpress-js.onrender.com/api',
  // );

  static String get apiBaseUrl {
    if (_rawApiBaseUrl.endsWith('/')) {
      return _rawApiBaseUrl.substring(0, _rawApiBaseUrl.length - 1);
    }
    return _rawApiBaseUrl;
  }
}

