// import 'dart:ui';

import 'package:flutter/material.dart';

final themeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.blueGrey.shade900,
      Colors.blueGrey.shade800,
      Colors.blueGrey.shade700,
      Colors.blueGrey.shade600,
    ],
    stops: [
      0.1,
      0.5,
      0.7,
      0.9
    ]);

final themeColor = Colors.blueGrey.shade800;
final fontColor = Colors.black54;
final darkGreyColor = Colors.blueGrey.shade200;
final lightGreyColor = Colors.blueGrey.shade50;
// final darkWhiteColor = Colors.white70;
final whiteColor = Colors.white;
final loadingColor = Colors.grey.shade200;

final myBubbleColor = Colors.blue.shade100;
final yourBubbleColor = Colors.white70;

final exitColor = Colors.red.shade400;

final Widget defaultPic = Icon(
  Icons.account_circle,
  size: 50.0,
  color: darkGreyColor,
);

final Widget defaultIcon = Icon(
  Icons.album,
  size: 50.0,
  color: darkGreyColor,
);
