class AppConfig {
  // static const String _rawApiBaseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'http://127.0.0.1:6019/api',
  // );
  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.mediahouseedge.com/api',
  );

  static String get apiBaseUrl {
    final normalized = _normalize(_rawApiBaseUrl);
    final configuredUri = Uri.tryParse(normalized);
    if (configuredUri == null || !configuredUri.hasAuthority) {
      return normalized;
    }

    final runtimeHost = Uri.base.host.trim();
    if (runtimeHost.isEmpty) return normalized;

    final configuredHost = configuredUri.host.trim();
    final configuredIsLoopback =
        configuredHost == '127.0.0.1' || configuredHost == 'localhost';
    final runtimeIsLoopback =
        runtimeHost == '127.0.0.1' || runtimeHost == 'localhost';

    if (configuredIsLoopback && !runtimeIsLoopback) {
      return configuredUri.replace(host: runtimeHost).toString();
    }

    return normalized;
  }

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static String _normalize(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
