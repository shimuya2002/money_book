
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
class SizeConfig {
  static double screenWidth=0;
  static double screenHeight=0;
  static double blockSizeHorizontal=0;
  static double blockSizeVertical=0;

  static double _safeAreaHorizontal=0;
  static double _safeAreaVertical=0;
  static double safeBlockHorizontal=0;
  static double safeBlockVertical=0;

  void init(BuildContext context) {
    var _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
  }
}
