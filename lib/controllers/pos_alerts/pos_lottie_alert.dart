/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/4/21, 4:38 PM
 */

import 'package:checkout/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class POSFLottieAlert extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextAlign? subtitleAlign;
  final String lottiePath;
  final List<Widget> actions;
  final Widget? content;
  final bool showLottie;
  final bool extraWidth;

  const POSFLottieAlert(
      {Key? key,
      required this.title,
      required this.subtitle,
      this.subtitleAlign,
      required this.actions,
      required this.lottiePath,
      this.content,
      this.showLottie = true,
      this.extraWidth = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: CurrentTheme.headline5!.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Container(
        width: extraWidth
            ? ScreenUtil().screenWidth * 0.40
            : ScreenUtil().screenWidth * 0.25,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subtitle,
              textAlign: subtitleAlign ?? TextAlign.center,
              style: CurrentTheme.headline6!
                  .copyWith(fontWeight: FontWeight.normal),
            ),
            showLottie
                ? Container(
                    height: 200.h,
                    child: Lottie.asset(lottiePath, fit: BoxFit.fill))
                : const SizedBox.shrink(),
            // showLottie
            //     ? SizedBox(
            //         height: 150.h,
            //         child: OverflowBox(
            //           minHeight: 250.h,
            //           maxHeight: 250.h,
            //           child: Lottie.asset(lottiePath, fit: BoxFit.fill),
            //         ),
            //       )
            //     : SizedBox.shrink(),
            content ?? Container()
          ],
        ),
      ),
      actions: actions,
    );
  }
}
