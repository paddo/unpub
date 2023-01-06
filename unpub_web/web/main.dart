import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/app_component.template.dart' as ng;
import 'package:unpub_web/app_router_hook.dart';
import 'package:unpub_web/app_service.dart';
import 'package:unpub_web/auth_service.dart';
import 'main.template.dart' as self;

@GenerateInjector([
  ClassProvider(AuthService),
  ClassProvider(RouterHook, useClass: AppRouterHook),
  ClassProvider(AppService),
  ...routerProviders,
])
final InjectorFactory injector = self.injector$Injector;

void main() {
  runApp(ng.AppComponentNgFactory, createInjector: injector);
}
