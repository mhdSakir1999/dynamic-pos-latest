/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/9/21, 5:03 PM
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/components/current_theme.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PayButton extends StatelessWidget {
  final String code;
  final String desc;
  final VoidCallback? onPressed;
  final Color? color;

  const PayButton(
      {Key? key,
      required this.code,
      required this.desc,
      required this.onPressed,
      this.color})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final config = POSConfig();
    print('payButton');
    return Container(
      margin: EdgeInsets.all(POSConfig().paymentDynamicButtonPadding),
      height: config.paymentDynamicButtonHeight.h,
      child: MaterialButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(config.rounderBorderRadiusBottomLeft),
          bottomRight: Radius.circular(config.rounderBorderRadiusBottomRight),
          topRight: Radius.circular(config.rounderBorderRadiusTopRight),
          topLeft: Radius.circular(config.rounderBorderRadiusTopLeft),
        )),
        color: color ?? CurrentTheme.primaryColor,
        child: Row(
          children: [
            SizedBox(
              width: 15.w,
            ),
            Text(
              desc,
              style: TextStyle(
                fontSize: 24.sp,
                color: CurrentTheme.primaryLightColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            Container(
                width: config.paymentDynamicButtonHeight * 0.8.h,
                height: config.paymentDynamicButtonHeight * 0.8.h,
                child: CachedNetworkImage(
                  imageUrl:
                      "${POSConfig().posImageServer}images/pay_modes/${code.toLowerCase()}.png",
                  httpHeaders: {'Access-Control-Allow-Origin': '*'},
                  errorWidget: (context, url, error) {
                    return SizedBox.shrink();
                  },
                )),
            SizedBox(
              width: 15.w,
            ),
          ],
        ),
        // style: ElevatedButton.styleFrom(
        //     primary: posButton.buttonNormalColor.toColor()),
        onPressed: onPressed,
      ),
    );
  }
}
