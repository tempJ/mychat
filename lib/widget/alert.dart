import 'package:flutter/material.dart';
import 'package:mychat/const.dart';

class ShowAlert extends StatelessWidget {
  ShowAlert(this.msg);
  final String msg;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(msg),
      actions: <Widget>[
        TextButton(
          child: Text("OK"),
          style: TextButton.styleFrom(
              textStyle: TextStyle(
            color: fontColor,
            fontWeight: FontWeight.normal,
          )),
          onPressed: () => Navigator.pop(context, 0),
        )
      ],
    );
  }
}
