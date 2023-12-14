/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/14/21, 5:14 PM
 */

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GoBackIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Image.asset("assets/images/go_back.png"),
    );
  }
}

class GoBackIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
 

  GoBackIconButton({Key? key, this.onPressed}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // _focusNode.requestFocus();
    return IconButton(
      icon: GoBackIcon(),
      onPressed: onPressed ?? () => Navigator.pop(context),
      iconSize: 30.r,
    );
  }
}
