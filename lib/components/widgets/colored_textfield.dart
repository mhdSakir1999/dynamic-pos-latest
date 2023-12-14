/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/22/21, 4:37 PM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// This widget return the fill the text field with given color
class ColoredTextField extends StatefulWidget {
  final TextEditingController controller;
  final Color filledColor;
  final TextInputType keyboardType;
  final bool autoFocus;
  final bool readOnly;
  final FocusNode? focusNode;
  final VoidCallback onEditingCompleted;

  ColoredTextField(
      {Key? key,
      required this.controller,
      required this.filledColor,
      required this.onEditingCompleted,
      required this.keyboardType,
      this.readOnly = false,
      this.focusNode,
      this.autoFocus = false})
      : super(key: key);
  @override
  _ColoredTextFieldState createState() => _ColoredTextFieldState();
}

class _ColoredTextFieldState extends State<ColoredTextField> {
  @override
  Widget build(BuildContext context) {
    final config = POSConfig();
    final inputBorderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(config.rounderBorderRadiusBottomLeft),
      bottomRight: Radius.circular(config.rounderBorderRadiusBottomRight),
      topRight: Radius.circular(config.rounderBorderRadiusTopRight),
      topLeft: Radius.circular(config.rounderBorderRadiusTopLeft),
    );
    return TextField(
      readOnly: widget.readOnly,
      controller: widget.controller,
      cursorColor: CurrentTheme.primaryLightColor,
      textAlign: TextAlign.center,
      keyboardType: widget.keyboardType,
      textInputAction: TextInputAction.done,
      style: TextStyle(fontSize: 36.sp, color: Colors.white),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
      ],
      autofocus: widget.autoFocus,
      focusNode: widget.focusNode,
      onEditingComplete: widget.onEditingCompleted,
      decoration: InputDecoration(
          filled: true,
          fillColor: widget.filledColor,
          border: OutlineInputBorder(
              borderRadius: inputBorderRadius,
              borderSide: BorderSide(color: widget.filledColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: inputBorderRadius,
              borderSide: BorderSide(color: widget.filledColor)),
          enabledBorder: OutlineInputBorder(
              borderRadius: inputBorderRadius,
              borderSide: BorderSide(color: widget.filledColor))),
    );
  }

  @override
  void dispose() {
    widget.controller.dispose();
    widget.focusNode?.dispose();
    super.dispose();
  }
}
