import 'dart:html' as html;
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:unpub_web/app_router_hook.dart';
import 'package:unpub_web/auth_service.dart';
import 'package:unpub_web/src/routes.dart';
import 'app_service.dart';

@Component(
  selector: 'my-app',
  styleUrls: ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: [routerDirectives, coreDirectives, formDirectives],
  exports: [RoutePaths, Routes, AppRouterHook],
  providers: [ClassProvider(AppService), ClassProvider(AuthService)],
)
class AppComponent {
  final AppService appService;
  final AuthService authService;
  final Router _router;
  bool authenticated = false;

  AppComponent(this.appService, this.authService, this._router) {
    // TODO: check if user is logged in
  }

  submit() async {
    if (appService.keyword == '') {
      return html.window.alert('keyword empty');
    }
    await _router.navigate(RoutePaths.list.toUrl(), NavigationParams(queryParameters: {'q': appService.keyword}));
  }

  String get homeUrl => RoutePaths.home.toUrl();
  bool get loading => appService.loading;
}
