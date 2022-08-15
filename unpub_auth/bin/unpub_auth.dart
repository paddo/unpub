import 'dart:io';

import 'package:console/console.dart';
import 'package:unpub_auth/env.dart';
import 'package:unpub_auth/extensions.dart';
import 'package:unpub_auth/models.dart';
import 'package:unpub_auth/unpub_auth.dart';

void main(List<String> args) async {
  // args:
  // unpub_auth login|logout|get|import|export <file>

  if (args.isEmpty) exitPrintUsage('Wrong number of arguments');

  final action = Action.values.parse(args[0] == 'get' ? 'getToken' : args[0]);
  if (action == null) exitPrintUsage('action is invalid');

  if (action == Action.import || action == Action.export) {
    if (args.length < 2) exitPrintUsage('You must provide a file path');
  }

  await run(action: action!, importExportFile: args.length > 1 ? args[1] : null);
  exit(0);
}

void exitPrintUsage(String? error) {
  stdout.write(format('''
An auth tool for unpub. 
{@gold}======================={@end}

The tool presently works for microsoft or google auth, though other providers may be easily added. 
It uses the device code flow to get an initial auth token.

There's two situations where the unpub_auth can be used.

{@yellow}1. Login locally, and publish pub packages locally.{@end}
  {@blue}step 1.{@end} Call {@cyan}'unpub_auth login'{@end} when you first use it, and it will save credentials locally.
  {@blue}step 2.{@end} Before calling 'dart pub publish' or 'flutter pub publish', call {@cyan}'unpub_auth get | dart pub token add <self-hosted-pub-server>'{@end}
  
{@yellow}2. Login locally, and publish pub packages from CI/CD.{@end}
{@yellow}   On CI/CD host device, you cannot call 'unpub_auth login', so you can use 'unpub_auth import' to import the credentials file.{@end}
  {@blue}step 1.{@end} In local device, call {@cyan}'unpub_auth login'{@end} when you first use it, and it will save credentials locally.
  {@blue}step 2.{@end} Copy the credentials file which was generated in step 1 to CI/CD device. Use {@cyan}'unpub_auth export <credentials-file-path>'{@end} to get a copy.
  {@blue}step 3.{@end} In CI/CD device, call {@cyan}'unpub_auth import <credentials-file-path>'{@end}, so the CI/CD will have the same credentials file.
  {@blue}step 4.{@end} In CI/CD device, before calling 'dart pub publish' or 'flutter pub publish', call {@cyan}'unpub_auth get | dart pub token add <self-hosted-pub-server>'{@end}

Usage: {@green}unpub_auth {@cyan}<command> {@blue}[arguments]{@end}

{@yellow}Available commands:
  {@green}login{@end}           Initial login. {@red}This must be run first.{@end}
  {@green}get{@end}             Refresh and get a new accessToken. Can be piped into {@cyan}'dart pub token add <self-hosted-pub-server>'.
  {@green}logout{@end}          Delete local credentials file, and revoke token if provider supports it.
  {@green}import {@cyan}<path>{@end}   Import credentials file from {@cyan}path{@end}.
  {@green}export {@cyan}<path>{@end}   Export credentials file to {@cyan}path{@end}.

{table}

''', replace: {'table': Env.instance.table}));

  exit(error != null ? 1 : 0);
}
