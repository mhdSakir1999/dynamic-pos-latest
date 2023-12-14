/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/23/21, 3:11 PM
 */
import 'package:checkout/components/widgets/textkey.dart';
import 'package:checkout/models/keyboard_config.dart';
import 'package:flutter/material.dart';

class POSKeyBoard extends StatelessWidget {

  POSKeyBoard(
      {Key? key,
      this.controller,
      required this.isInvoiceScreen,
      this.clearButton = false,required this.onEnter,required this.onPressed, this.mask, this.disableArithmetic=false, this.color})
      : super(key: key);
  // The controller connected to the InputField
  final TextEditingController? controller;
  final bool isInvoiceScreen;
  final bool clearButton;
  final VoidCallback onEnter;
  final VoidCallback onPressed;
  final String? mask;
  final Color? color;
  final bool disableArithmetic;
  @override
  Widget build(BuildContext context) {
    List buttonlist = clearButton
        ? KeyBoardConfig().poskeys3
        : isInvoiceScreen
            ? KeyBoardConfig().poskeys2
            : KeyBoardConfig().poskeys;
    return Container(
      height: KeyBoardConfig().posKeyboardHeight,
      color:color?? KeyBoardConfig().bkColor,
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
          return POSEnterKey(
            onPressed: onEnter,
            //controller: controller,
            text: e,
            flex: 7,
            //onTextInput: _textInputHandler,
          );
        case 'Void':
          return POSVoidKey(
            onPressed: onPressed,
            //controller: controller,
            text: e,
            flex: 7,
            //onTextInput: _textInputHandler,
          );
        case 'Exact':
          return POSExactKey(
            onPressed: onPressed,
            //controller: controller,
            text: e,
            flex: 7,
            //onTextInput: _textInputHandler,
          );
        case 'Clear':
          return POSClearKey(
            //controller: controller,
            onPressed: onPressed,
            text: e,
            flex: 7,
            //onTextInput: _textInputHandler,
          );
        default:
          return NumKey(
            disableArithmetic: disableArithmetic,
            mask: mask,
            controller: controller,
            text: e,
            flex: 7,
            //onTextInput: _textInputHandler,
          );
      }
    }).toList()));
  }
}
