import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

import 'package:readhub_flutter/utils/FetchProgress.dart';

@immutable
class FetchProgressPlaceholder extends StatelessWidget {
  const FetchProgressPlaceholder({
    @required this.progress,
    @required this.action,
    this.padding = const EdgeInsets.all(8.0),
    this.alignment = Alignment.center,
    this.completed = const Text('已到最后'),
    this.placeholder = const SizedBox(),
  });

  final FetchProgress progress;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final Widget completed;
  final Widget placeholder;
  final VoidCallback action;

  Widget _buildStatus(BuildContext context) {
    switch (progress.status) {
      case FetchStatus.busy:
        return new CircularProgressIndicator();
      case FetchStatus.exception:
        return new Text(progress.exception.toString());
      default:
        action();
        return placeholder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget status = _buildStatus(context);
    final Widget widget = new Align(
      alignment: alignment,
      child: new Padding(padding: padding, child: status),
    );
    if (progress.status == FetchStatus.exception) {
      return new GestureDetector(
        onTap: action,
        child: widget,
      );
    }
    return widget;
  }
}
