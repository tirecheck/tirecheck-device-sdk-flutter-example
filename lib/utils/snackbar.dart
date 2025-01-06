import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ABC {
  a,
  b,
  c,
}

class Snackbar {
  static final snackBarKeyA = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyB = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyC = GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> _getSnackbarKey(ABC abc) {
    switch (abc) {
      case ABC.a:
        return snackBarKeyA;
      case ABC.b:
        return snackBarKeyB;
      case ABC.c:
        return snackBarKeyC;
    }
  }

  static void show(ABC abc, String msg,
      {required bool success, Duration? duration}) {
    final snackBar = SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.blue : Colors.red,
      duration: duration ?? const Duration(seconds: 4),
    );
    final scaffoldMessengerState = _getSnackbarKey(abc).currentState;
    scaffoldMessengerState?.removeCurrentSnackBar();
    scaffoldMessengerState?.showSnackBar(snackBar);
  }
}

String prettyException(String prefix, dynamic e) {
  if (e is PlatformException) {
    return "$prefix ${e.message}";
  }
  return "$prefix ${e.toString()}";
}
