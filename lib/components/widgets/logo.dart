/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/21/21, 11:28 AM
 */

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// This widget gives shop logo or mypos logo on availability

class POSLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = 220.r;
    // if (POSConfig().demoPOS) return MyPOSLogo();
    return Container(width: size, height: size, child: ShopLogo());
  }
}

/// This is the shop logo
class ShopLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hero(
        tag: "shop_logo",
        child: Image.asset(
          "assets/images/my_sky.png",
          fit: BoxFit.contain,
        ));
  }
}

/// This widget gives myPOS logo
class MyPOSLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hero(
        tag: "mypos_logo",
        child: Image.asset(
          "assets/images/mypos_logo.png",
          fit: BoxFit.contain,
        ));
  }
}

class PoweredByLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.r,
      child: Hero(
          tag: "mypos_logo",
          child: Image.asset("assets/images/powered.png", fit: BoxFit.contain)),
    );
  }
}

class LogoWithPoweredBy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
          width: 200.h,
          child: Image.asset("assets/images/logo.gif",
              fit: BoxFit.contain)),
    );
  }
}
