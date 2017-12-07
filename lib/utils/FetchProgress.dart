import 'package:meta/meta.dart';

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
}
