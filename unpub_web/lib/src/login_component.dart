import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:unpub_web/app_service.dart';
import 'routes.dart';
import 'package:unpub_api/models.dart';

@Component(
  selector: 'login',
  templateUrl: 'login_component.html',
  directives: [routerDirectives, coreDirectives],
  exports: [RoutePaths],
)
class LoginComponent implements OnActivate {
  final AppService appService;

  ListApi? data;
  LoginComponent(this.appService);

  @override
  void onActivate(RouterState? previous, RouterState current) async {
    appService.setLoading(true);
    data = await appService.fetchPackages(size: 15);
    appService.setLoading(false);
  }

  getDetailUrl(ListApiPackage package) {
    return RoutePaths.detail.toUrl(parameters: {'name': package.name});
  }
}
