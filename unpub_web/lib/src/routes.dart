import 'package:angular_router/angular_router.dart';

import 'home_component.template.dart' as home_template;
import 'list_component.template.dart' as list_template;
import 'detail_component.template.dart' as detail_template;
import 'login_component.template.dart' as login_template;
// import 'not_found_component.template.dart' as not_found_template;

class RoutePaths {
  static final login = RoutePath(path: 'login');
  static final home = RoutePath(path: '');
  static final list = RoutePath(path: 'packages');
  static final detail = RoutePath(path: 'packages/:name');
  static final detailVersion = RoutePath(path: 'packages/:name/versions/:version');
}

class RouteConfig {
  final bool protected;
  final bool redirectIfLoggedIn;

  RouteConfig({this.protected = true, this.redirectIfLoggedIn = false});
}

class Routes {
  static final login = RouteDefinition(
    routePath: RoutePaths.login,
    component: login_template.LoginComponentNgFactory,
    additionalData: RouteConfig(redirectIfLoggedIn: true, protected: false),
  );

  static final home = RouteDefinition(
    routePath: RoutePaths.home,
    component: home_template.HomeComponentNgFactory,
    additionalData: RouteConfig(),
  );

  static final list = RouteDefinition(
    routePath: RoutePaths.list,
    component: list_template.ListComponentNgFactory,
    additionalData: RouteConfig(),
  );

  static final detail = RouteDefinition(
    routePath: RoutePaths.detail,
    component: detail_template.DetailComponentNgFactory,
    additionalData: RouteConfig(),
  );

  static final detailVersion = RouteDefinition(
    routePath: RoutePaths.detailVersion,
    component: detail_template.DetailComponentNgFactory,
    additionalData: RouteConfig(),
  );

  static final all = <RouteDefinition>[
    home,
    list,
    detail,
    detailVersion,
    login,
  ];
}
