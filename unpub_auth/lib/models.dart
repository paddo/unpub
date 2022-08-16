import 'dart:convert';

import 'package:unpub_auth/extensions.dart';

enum Provider {
  ms,
  google,
}

enum Action {
  login,
  logout,
  import,
  export,
  getToken,
}

class DeviceCodeResult {
  final Provider provider;
  final String userCode;
  final String deviceCode;
  final String verificationUri;
  final Duration expiresIn;
  final Duration pollInterval;
  final DateTime _validFrom;

  DeviceCodeResult._({
    required this.provider,
    required this.userCode,
    required this.deviceCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.pollInterval,
  }) : _validFrom = DateTime.now();

  factory DeviceCodeResult.fromJson(Provider provider, Map<String, dynamic> json) => DeviceCodeResult._(
        provider: provider,
        userCode: json['user_code'] ?? '',
        deviceCode: json['device_code'] ?? '',
        verificationUri: json[provider == Provider.google ? 'verification_url' : 'verification_uri'] ?? '',
        expiresIn: Duration(seconds: json['expires_in'] ?? 0),
        pollInterval: Duration(seconds: json['interval'] ?? 60),
      );

  DateTime get validTo => _validFrom.add(expiresIn);
}

class Token {
  final Provider? provider;
  final String tokenType;
  final String scope;
  final Duration expiresIn;
  final String accessToken;
  final String refreshToken;
  final String idToken;
  final DateTime validFrom;

  Token._({
    required this.provider,
    required this.tokenType,
    required this.scope,
    required this.expiresIn,
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    DateTime? validFrom,
  }) : validFrom = validFrom ?? DateTime.now();

  factory Token.fromJson(Map<String, dynamic> json, [Provider? provider]) => Token._(
        provider: provider ?? Provider.values.parse(json['provider'] ?? ''),
        tokenType: json['token_type'] ?? '',
        scope: json['scope'] ?? '',
        expiresIn: Duration(seconds: json['expires_in'] ?? 0),
        accessToken: json['access_token'] ?? '',
        refreshToken: json['refresh_token'] ?? '',
        idToken: json['id_token'] ?? '',
        validFrom: json['valid_from'] == null ? null : DateTime.parse(json['valid_from']),
      );

  Token withTokens(String accessToken, String refreshToken, String idToken, Duration expiresIn) => Token._(
        provider: provider,
        tokenType: tokenType,
        scope: scope,
        expiresIn: expiresIn,
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: idToken,
        validFrom: null,
      );

  DateTime get validTo => validFrom.add(expiresIn);

  String toJson() => JsonEncoder.withIndent('    ').convert({
        'provider': provider?.name ?? '',
        'token_type': tokenType,
        'scope': scope,
        'expires_in': expiresIn.inSeconds,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'id_token': idToken,
        'valid_from': validFrom.toIso8601String(),
      });
}

class ErrorResult {
  final String error;
  final String errorDescription;

  bool get isRetryable => error == 'authorization_pending';

  ErrorResult._({
    required this.error,
    required this.errorDescription,
  });

  factory ErrorResult.fromJson(Map<String, dynamic> json) => ErrorResult._(
        error: json['error'] ?? '',
        errorDescription: json['error_description'] ?? '',
      );
}
