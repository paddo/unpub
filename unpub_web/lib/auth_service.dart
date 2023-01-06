import 'package:angular/angular.dart';

@Injectable()
class AuthService {
  User? user;
}

class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}
