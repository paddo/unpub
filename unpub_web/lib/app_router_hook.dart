import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/auth_service.dart';
import 'package:unpub_web/src/routes.dart';

@Injectable()
class AppRouterHook extends RouterHook {
  final AuthService _authService;
  final Injector _injector;

  AppRouterHook(this._authService, this._injector);

  // Lazily inject `Router` to avoid cyclic dependency.
  Router? _router;
  Router get router => _router ??= _injector.provideType(Router);

  @override
  Future<bool> canActivate(Object componentInstance, RouterState? oldState, RouterState newState) async {
    print('app router hook');
    final config = newState.routePath.additionalData as RouteConfig?;
    if (config == null) return true;

    if (config.protected && _authService.user == null) {
      router.navigate('login', NavigationParams(replace: true));
      return false;
    }

    if (config.redirectIfLoggedIn && _authService.user != null) {
      router.navigate('', NavigationParams(replace: true));
      return false;
    }

    return true;
  }
}
