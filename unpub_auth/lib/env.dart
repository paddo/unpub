import 'dart:io';
import 'dart:math';

import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart' as path;
import 'package:unpub_auth/extensions.dart';
import 'package:unpub_auth/models.dart';

class Env {
  int terminalCols = 80;
  int minTerminalCols = 80;
  final DotEnv _env;
  Env._() : _env = DotEnv(includePlatformEnvironment: true)..load() {
    if (stdout.hasTerminal) {
      terminalCols = stdout.terminalColumns;
      ProcessSignal.sigwinch.watch().listen((_) => terminalCols = max(minTerminalCols, stdout.terminalColumns));
    }
  }
  static final instance = Env._();
  final _envPrefix = 'UP_AUTH_';
  String _get(String key) => _env['$_envPrefix$key'] ?? _env['$_prefix$key'] ?? _env[key] ?? '';

  Provider get provider => Provider.values.parse(_env['UP_AUTH_PROVIDER'] ?? _env['PROVIDER'] ?? '') ?? Provider.google;
  String get _prefix => provider.name.toUpperCase() + '_';

  String get clientId => _get('CLIENT_ID');
  String get scope => _get('SCOPE');
  String get tenantId => _get('TENANT_ID');
  String get clientSecret => _get('CLIENT_SECRET');
  String get deviceCodeUri => _transformEncoded(_get('DEVICE_CODE_URI'));
  String get revokeUri => _transformEncoded(_get('REVOKE_URI'));
  String get tokenUri => _transformEncoded(_get('TOKEN_URI'));
  String get deviceCodePostArgs => _transformEncoded(_get('DEVICE_CODE_POST_ARGS'));

  String pollPostArgs(String deviceCode) => _transformEncoded(_get('POLL_POST_ARGS')).replaceAll('{deviceCode}', deviceCode.urlEncode());
  String revokePostArgs(String refreshToken) => _transformEncoded(_get('REVOKE_POST_ARGS')).replaceAll('{refreshToken}', refreshToken.urlEncode());
  String refreshTokenPostArgs(String refreshToken) =>
      _transformEncoded(_get('REFRESH_TOKEN_POST_ARGS')).replaceAll('{refreshToken}', refreshToken.urlEncode());

  String _transformEncoded(String? value) => (value ?? '')
      .replaceAll('{scope}', scope.urlEncode())
      .replaceAll('{tenantId}', tenantId.urlEncode())
      .replaceAll('{clientId}', clientId.urlEncode())
      .replaceAll('{clientSecret}', clientSecret.urlEncode());

  String get credentialsFilePath => path.join(configDir, 'unpub-credentials.json');

  /// Different location for each platform
  String get _configBaseDir {
    if (Platform.isLinux) return _env['XDG_CONFIG_HOME'] ?? path.join(_env['HOME']!, '.config');
    if (Platform.isWindows) return _env['APPDATA']!;
    if (Platform.isMacOS) return path.join(_env['HOME']!, 'Library', 'Application Support');

    return path.join(_env['HOME'] ?? '', '.config');
  }

  String get configDir => path.join(_configBaseDir, 'unpub-auth');

  // -------------------------------------------------------------------------
  // below here is for outputting the configuration information to the console
  // -------------------------------------------------------------------------

  Map<String, String> get _all => {
        'PROVIDER': provider.name,
        'CLIENT_ID': clientId,
        'SCOPE': scope,
        'TENANT_ID': tenantId,
        'CLIENT_SECRET': clientSecret.isEmpty ? '<hidden: not set>' : '<hidden: set>',
        'DEVICE_CODE_URI': deviceCodeUri,
        'REVOKE_URI': revokeUri,
        'TOKEN_URI': tokenUri,
        'DEVICE_CODE_POST_ARGS': deviceCodePostArgs,
        'POLL_POST_ARGS': pollPostArgs('{deviceCode}'),
        'REVOKE_POST_ARGS': revokePostArgs('{refreshToken}'),
        'REFRESH_TOKEN_POST_ARGS': refreshTokenPostArgs('{refreshToken}'),
      };

  Map<String, String> get _descriptions => {
        'PROVIDER': 'MANDATORY. Which provider to use. Currently supported: google, ms.',
        'CLIENT_ID': 'MANDATORY. Client ID to use for authentication.',
        'SCOPE': 'MANDATORY. Scope to use for authentication.',
        'TENANT_ID': 'Tenant ID. Only needed for ms provider',
        'CLIENT_SECRET': 'Client Secret. Only needed for google provider',
        'DEVICE_CODE_URI': 'MANDATORY. We use device code to get an authorization code. This is the URI to use for that.',
        'REVOKE_URI': 'URI for revoking tokens. Only needed for google provider',
        'TOKEN_URI': 'MANDATORY. URI for getting tokens.',
        'DEVICE_CODE_POST_ARGS': 'MANDATORY. Arguments to use when posting the device code.',
        'POLL_POST_ARGS': 'MANDATORY. Arguments to use when polling for the authorization code.',
        'REVOKE_POST_ARGS': 'Arguments to use when revoking tokens. Only needed for google provider',
        'REFRESH_TOKEN_POST_ARGS': 'MANDATORY. Arguments to use when refreshing tokens.',
      };

  String get table {
    final maxVariableLength = _all.keys.map((key) => key.length).reduce(max) + _envPrefix.length;
    final padding = 10;
    final maxColLength = ((terminalCols - maxVariableLength - padding) / 2).floor();
    final boundaries = <int>[0, maxVariableLength + 3, maxVariableLength + maxColLength + 6, terminalCols - 1];

    return _separator(boundaries) +
        '|' +
        'Available Environment Variables'.padBoth(terminalCols - 2) +
        '|' +
        _separator(boundaries) +
        _row('Variable', 'Description', 'Current Value', boundaries) +
        _separator(boundaries) +
        _all.entries.map((entry) => _row('$_envPrefix${entry.key}', _descriptions[entry.key]!, entry.value, boundaries)).join() +
        _separator(boundaries);
  }

  String _separator(List<int> boundaries) {
    final sb = StringBuffer();
    for (var i = 0; i <= boundaries.last; i++) {
      sb.write(boundaries.contains(i) ? '+' : '-');
    }
    return '$sb\n';
  }

  String _row(String key, String description, String value, List<int> boundaries) {
    final sb = StringBuffer();
    final keyLines = key.wrap(boundaries[1] - 2);
    final descriptionLines = description.wrap(boundaries[2] - boundaries[1] - 2);
    if (clientSecret.isNotEmpty) {
      value = value.replaceAll(clientSecret, '<client secret hidden>');
    }
    final valueLines = value.wrap(boundaries[3] - boundaries[2] - 2);
    final height = [keyLines.length, descriptionLines.length, valueLines.length].reduce(max);

    for (var i = 0; i < height; i++) {
      sb.write('| ');
      sb.write((i < keyLines.length ? keyLines[i] : '').padRight(boundaries[1] - 2));
      sb.write('| ');
      sb.write((i < descriptionLines.length ? descriptionLines[i] : '').padRight(boundaries[2] - boundaries[1] - 2));
      sb.write('| ');
      sb.write((i < valueLines.length ? valueLines[i] : '').padRight(boundaries[3] - boundaries[2] - 2));
      sb.write('|');
      sb.write('\n');
    }
    return '$sb';
  }
}
