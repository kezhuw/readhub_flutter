import 'package:meta/meta.dart';

import 'package:quiver/core.dart';

enum FetchStatus {
  none,
  busy,
  exception,
  completed,
}

@immutable
class FetchProgress {
  const FetchProgress._fetchProgress({@required this.status, this.exception});

  final FetchStatus status;
  final dynamic exception;

  static const none = const FetchProgress._fetchProgress(status: FetchStatus.none);
  static const busy = const FetchProgress._fetchProgress(status: FetchStatus.busy);
  static const completed = const FetchProgress._fetchProgress(status: FetchStatus.completed);

  const FetchProgress.error(this.exception) : status = FetchStatus.none;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType is! FetchProgress) {
      return false;
    }
    FetchProgress typedOther = other;
    return status == typedOther.status && exception == typedOther.exception;
  }

  @override
  int get hashCode => exception == null ? hash2(runtimeType, status) : hash3(runtimeType, status, exception);
}
