/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/22/21, 4:46 PM
 */

import 'package:checkout/components/widgets/textkey.dart';
import 'package:checkout/models/keyboard_config.dart';
import 'package:flutter/material.dart';

///Keyboard Main class contain keyboard build and value hold
class NumericKeyBoard extends StatelessWidget {
  NumericKeyBoard({
    Key? key,
    this.onTextInput,
    this.onBackspace,
    this.onEnter,
    this.controller,
  }) : super(key: key);
  final ValueSetter<String>? onTextInput;
  final VoidCallback? onBackspace;
  final VoidCallback? onEnter;
  // The controller connected to the InputField
  final TextEditingController? controller;
  void _textInputHandler(String text) => onTextInput?.call(text);
  void _backspaceHandler() => onBackspace?.call();
  void _enterHandler() => onEnter?.call();
  @override

  // Keyboard Build
  Widget build(BuildContext context) {
    // Load keylist from config class 2D Array
    List buttonlist = KeyBoardConfig().numbuttonlist;
    return Container(
      height: 160,
      color: KeyBoardConfig().primaryBKColor,
      child: Column(
          //Get 1D Array from 2D Array
          children: buttonlist.map<Widget>((e) {
        return (
            // Call Key Distributor Method With Single Dimension Array
            buildRowOne(e));
      }).toList() // <-- Column
          ),
    );
  }

  //Button Distributor need Single dimension array
  Expanded buildRowOne(List buttonNames) {
    return Expanded(
        child: Row(
            //Get Value from Array
            children: buttonNames.map<Widget>((e) {
      // Call Related Button according to Value
      switch (e) {
        case 'Enter':
          return EnterKey(
            flex: 1,
            onEnter: _enterHandler,
          );
        case 'backspace':
          return BackspaceKey(
            controller: controller,
            flex: 1,
            onBackspace: _backspaceHandler,
          );
        case 'Del':
          return DelKey(
            controller: controller,
            flex: 1,
            onDeletePress: _backspaceHandler,
          );
        case 'na':
          return NullKey();
        default:
          return TextKey(
            controller: controller,
            text: e,
            onTextInput: _textInputHandler,
          );
      }
    }).toList()));
  }
}
