import 'dart:async';

import 'package:flutter/material.dart';

class WorldClock extends StatefulWidget {
  const WorldClock({Key key, this.child, this.tick = const Duration(seconds: 30)}) : super(key: key);

  final Duration tick;
  final Widget child;

  static DateTime timeOf(BuildContext context) {
    _InheritedWordClock clock = context.inheritFromWidgetOfExactType(_InheritedWordClock);
    return clock.now;
  }

  @override
  _WorldClockState createState() => new _WorldClockState();
}

class _InheritedWordClock extends InheritedWidget {
  const _InheritedWordClock({Key key, Widget child, this.now}) : super(key: key, child: child);

  final DateTime now;

  @override
  bool updateShouldNotify(_InheritedWordClock oldWidget) => now != oldWidget.now;
}

class _WorldClockState extends State<WorldClock> with SingleTickerProviderStateMixin {
  DateTime now;
  Timer timer;

  @override
  void initState() {
    super.initState();
    now = new DateTime.now();
    timer = new Timer.periodic(widget.tick, tick);
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  void didUpdateWidget(WorldClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tick != oldWidget.tick) {
      timer.cancel();
      timer = new Timer.periodic(widget.tick, tick);
    }
  }

  void tick(Timer _timer) {
    if (!mounted) {
      return;
    }
    setState(() {
      now = new DateTime.now();
    });
  }


  @override
  Widget build(BuildContext context) {
    return new _InheritedWordClock(child: widget.child, now: now);
  }
}
