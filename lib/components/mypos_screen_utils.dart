/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/27/21, 3:43 PM
 */

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final double screenWidth = ScreenUtil().screenWidth;

bool get isMobile => (!kIsWeb) && (Platform.isIOS || Platform.isAndroid);
// bool get isMobile =>false;

enum ScreenSize { lg, md }

ScreenSize getScreenSize() {
  if (screenWidth > 992) return ScreenSize.lg;
  return ScreenSize.md;
}

double getFontSize() {
  switch (getScreenSize()) {
    case ScreenSize.lg:
      return 1.sp;
    case ScreenSize.md:
      return 3.5.sp;
  }
}

double getRadius() {
  switch (getScreenSize()) {
    case ScreenSize.lg:
      return 1.r;
    case ScreenSize.md:
      return 1.75.r;
  }
}

double getLandingButtonSize() {
  switch (getScreenSize()) {
    case ScreenSize.lg:
      return 140.w;
    case ScreenSize.md:
      return screenWidth * 0.75;
  }
}

class HideWidgetOnScreenSize extends StatelessWidget {
  const HideWidgetOnScreenSize(
      {Key? key, required this.child, this.lg = false, this.md = false})
      : super(key: key);
  final Widget child;
  final bool lg;
  final bool md;
  @override
  Widget build(BuildContext context) {
    final ScreenSize screenSize = getScreenSize();
    switch (screenSize) {
      case ScreenSize.lg:
        if (lg) return child;
        break;
      case ScreenSize.md:
        if (md) return child;
        break;
    }
    return const SizedBox.shrink();
  }
}
