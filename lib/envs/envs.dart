import 'package:meta/meta.dart';

@immutable
class Environment {
  const Environment._({
    @required this.apiAddress,
  }) : assert(apiAddress != null);

  final String apiAddress;
}

Environment _production = const Environment._(apiAddress: "https://api.readhub.me");

Environment resolveEnvironment(String env) {
  switch (env) {
    case "production":
      return _production;
    default:
      throw 'undefined environment "$env"';
  }
}
