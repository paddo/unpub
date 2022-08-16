import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:unpub_auth/env.dart';
import 'package:unpub_auth/extensions.dart';
import 'package:unpub_auth/models.dart';
import 'package:path/path.dart' as p;

Future<void> run({required Action action, String? importExportFile}) async {
  switch (action) {
    case Action.login:
      await _loginWithDeviceCode();
      break;
    case Action.logout:
      await _revokeToken();
      break;
    case Action.import:
      await _importFile(importExportFile!);
      break;
    case Action.export:
      await _exportFile(importExportFile!);
      break;
    case Action.getToken:
    default:
      await _getToken();
      break;
  }
}

Future<HttpClientResponse> _request(String uri, String postArgs) async {
  final bodyBytes = utf8.encode(postArgs);
  final request = await HttpClient().postUrl(Uri.parse(uri))
    ..headers.contentType = ContentType.parse('application/x-www-form-urlencoded')
    ..headers.set('Content-Length', bodyBytes.length.toString())
    ..headers.set('Accept', 'application/json');

  request.add(bodyBytes);
  final response = await request.close();
  return response;
}

Future<T> _decodeResponse<T>(HttpClientResponse response, T Function(Map<String, dynamic> json) factory) async {
  final body = await response.transform(utf8.decoder).join();
  final json = jsonDecode(body);
  return factory(json);
}

Future<void> _revokeToken() async {
  final env = Env.instance;
  // optionally, we can actually revoke the token here
  if (env.revokeUri.isNotEmpty && File(env.credentialsFilePath).existsSync()) {
    final refreshToken = Token.fromJson(File(env.credentialsFilePath).readAsStringSync().decodeJson()).refreshToken;
    if (refreshToken.isNotEmpty) await _request(env.revokeUri, env.revokePostArgs(refreshToken));
  }

  await File(Env.instance.credentialsFilePath).delete();
  print('${Env.instance.credentialsFilePath} has been deleted.');
}

Future<void> _getToken() async {
  final env = Env.instance;
  // load the token, update it from provider, then save it back to the file, return the new access token.
  final file = File(env.credentialsFilePath);
  if (!file.existsSync()) {
    print('${env.credentialsFilePath} does not exist. You must call login first.');
    exit(1);
  }

  final token = Token.fromJson(File(env.credentialsFilePath).readAsStringSync().decodeJson());
  final response = await _request(env.tokenUri, env.refreshTokenPostArgs(token.refreshToken));

  if (response.statusCode != 200) {
    print('Failed to get token. You may need to call login first.');
    final result = await _decodeResponse(response, (json) => ErrorResult.fromJson(json));
    print('Error:\n${result.errorDescription}');
    exit(1);
  }

  final result = await _decodeResponse(response, (json) => Token.fromJson(json));
  final newToken = token.withTokens(result.accessToken, result.refreshToken, result.idToken, result.expiresIn);
  file.writeAsStringSync(newToken.toJson());

  print(newToken.accessToken);
}

Future<void> _loginWithDeviceCode() async {
  final env = Env.instance;
  final response = await _request(env.deviceCodeUri, env.deviceCodePostArgs);

  if (response.statusCode != 200) {
    print('Failed to get device code.\n${response.reasonPhrase}');
    exit(1);
  }

  final result = await _decodeResponse(response, (json) => DeviceCodeResult.fromJson(env.provider, json));
  print('To sign in, use a web browser to open the page ${result.verificationUri} and enter the code ${result.userCode}.');
  while (true) {
    await Future.delayed(result.pollInterval);
    _pollForToken(result.deviceCode).toString();
  }
}

Future<void> _pollForToken(String deviceCode) async {
  final env = Env.instance;
  final response = await _request(env.tokenUri, env.pollPostArgs(deviceCode));
  if (response.statusCode != 200) {
    final result = await _decodeResponse(response, (json) => ErrorResult.fromJson(json));
    if (result.error == 'authorization_pending') {
      // still pending, wait for next poll.
      stdout.write('.');
      return;
    }

    // fell through to an actual error - exit/fail.
    print('\nError:\n${result.errorDescription}');
    exit(1);
  }

  // we authenticated if we got this far, save creds to file.
  final result = await _decodeResponse(response, (json) => Token.fromJson(json, env.provider));
  final file = File(Env.instance.credentialsFilePath);
  file.writeAsStringSync(result.toJson());

  print('\nAccess Token retrieved and saved to:\n${Env.instance.credentialsFilePath}');
  exit(0);
}

Future<void> _importFile(String path) async {
  // we are not checking the file for integrity, simply copying into the correct location.
  final src = File(path);
  if (!src.existsSync()) {
    print('File not found: $path');
    exit(1);
  }

  await src.copy(Env.instance.credentialsFilePath);
}

Future<void> _exportFile(String path) async {
  final credsPath = Env.instance.credentialsFilePath;
  final src = File(credsPath);
  if (!src.existsSync()) {
    print('File not found: $path');
    exit(1);
  }

  // if we are exporting to a directory, we want to create a file with the same name as the original, in the new location
  final dest = File(path);
  if (dest.statSync().type == FileSystemEntityType.directory) path = p.join(path, p.basename(credsPath));
  await src.copy(path);
}
