import 'package:flutter/material.dart';
import 'package:mychat/const.dart';

class Loading extends StatelessWidget {
  const Loading();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
        ),
      ),
    );
  }
}
