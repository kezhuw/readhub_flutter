import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

import 'package:readhub_flutter/widgets/WorldClock.dart';

String _buildElapsedTimeText({DateTime from, DateTime to}) {
  if (from.add(const Duration(seconds: 60)).isAfter(to)) {
    return '刚刚';
  }
  Duration d = to.difference(from);
  if (d.compareTo(const Duration(hours: 1)) < 0) {
    return '${d.inMinutes} 分钟前';
  } else if (d.compareTo(const Duration(days: 1)) < 0) {
    return '${d.inHours} 小时前';
  } else {
    return '${d.inDays} 天前';
  }
}

@immutable
class ElapsedTimeText extends StatelessWidget {
  const ElapsedTimeText({Key key, @required this.time, this.color}) : super(key: key);

  final DateTime time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return new RepaintBoundary(
      child: new Builder(
        builder: (BuildContext context) {
          DateTime now = WorldClock.timeOf(context);
          String text = _buildElapsedTimeText(from: time, to: now);
          return new Text(text, style: new TextStyle(color: color));
        },
      ),
    );
  }
}

class ElapsedTimeTitle extends StatelessWidget {
  const ElapsedTimeTitle({
    Key key,
    @required this.title,
    this.style,
    @required this.time,
    this.timeStyle,
    this.separator = '  ',
    this.separatorStyle,
  }) : super(key: key);

  final String title;
  final TextStyle style;

  final DateTime time;
  final TextStyle timeStyle;

  final String separator;
  final TextStyle separatorStyle;

  @override
  Widget build(BuildContext context) {
    return new RepaintBoundary(
      child: new Builder(
        builder: (BuildContext context) {
          DateTime now = WorldClock.timeOf(context);
          String elapsed = _buildElapsedTimeText(from: this.time, to: now);
          return new RichText(
            text: new TextSpan(
              text: title,
              style: style,
              children: <TextSpan>[
                new TextSpan(text: separator, style: separatorStyle ?? style),
                new TextSpan(text: elapsed, style: timeStyle ?? style),
              ],
            )
          );
        }
      ),
    );
  }
}
