import 'dart:async';

import 'package:dynamic_form_builder/form_builder_engine.dart';
import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  final String thisKey;
  final Map<dynamic, dynamic> props;
  final Map<String, dynamic> schema;
  final SecondaryFunc? onSocondaryCall;
  const TimerWidget(
      {super.key,
      required this.thisKey,
      required this.props,
      required this.schema,
      this.onSocondaryCall});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  int startTimeFrom = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    startTimeFrom = int.parse(widget.props['second']['value'] ?? '120');
    _startTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (startTimeFrom == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            startTimeFrom--;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (startTimeFrom) {
      case 0:
        return TextButton(
          onPressed: () {
            widget.onSocondaryCall?.call(null);
            setState(() {
              startTimeFrom =
                  int.parse(widget.props['second']['value'] ?? '120');
            });
            _startTimer();
          },
          child: Text(widget.props['onEndText']['value'] ?? "ارسال مجدد",
              style: const TextStyle(color: Colors.blue)),
        );

      default:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('$startTimeFrom',
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
        );
    }
  }
}
