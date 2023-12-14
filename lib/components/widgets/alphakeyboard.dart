/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/20/21, 3:47 PM
 * Further Development/Corrections: TM.Sakir at 2023-12-07
 */

import 'package:checkout/bloc/keyboard_bloc.dart';
import 'package:checkout/components/widgets/textkey.dart';
import 'package:checkout/models/enum/keyboard_type.dart';
import 'package:checkout/models/keyboard_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

///Keyboard Main class contain keyboard build and value hold
class AlphaKeyboard extends StatelessWidget {
  AlphaKeyboard(
      {Key? key,
      this.onTextInput,
      this.onBackspace,
      this.onEnter,
      this.capsLock,
      this.shift,
      this.controller,
      this.mask,
      this.obscureText,
      this.onRightArrow,
      this.onLeftArrow,
      this.onDelete})
      : super(key: key);
  final ValueSetter<String>? onTextInput;
  final VoidCallback? onBackspace;
  final VoidCallback? onRightArrow;
  final VoidCallback? onLeftArrow;
  final VoidCallback? onDelete;

  final VoidCallback? onEnter;
  final ValueChanged? capsLock;
  final ValueChanged? shift;
  final String? mask;
  final bool? obscureText;
  // The controller connected to the InputField
  final TextEditingController? controller;
  void _textInputHandler(String text) => onTextInput?.call(text);
  void _backspaceHandler() => onBackspace?.call();
  void _deleteHandler() => onDelete?.call();
  void _rightArrowHandler() => onRightArrow?.call();
  void _leftArrowHandler() => onLeftArrow?.call();
  void _enterHandler() => onEnter?.call();
  void _capsLockHandler(bool setval) => capsLock?.call(setval);
  void _shiftLockHandler(bool setval) => shift?.call(setval);
  final FocusNode focusNode = FocusNode();

  @override
  // Keyboard Build
  Widget build(BuildContext context) {
    focusNode.requestFocus();
    // Load keylist from config class 2D Array
    return StreamBuilder(
        stream: keyBoardBloc.currentPressKeyStream,
        builder: (context, AsyncSnapshot<keyType> snapshot) {
          //snapshot.hasData
          //snapshot.data == keyType.Enter

          /*bool capsOn = false;
        bool shiftOn = false;
        if(snapshot.hasData) {
          capsOn = snapshot.data == keyType.CapsLock;
          shiftOn = snapshot.data == keyType.Shift;
        }*/
          //|| (shiftOn && KeyBoardConfig().shift)
          List buttonlist = (KeyBoardConfig().capsLock)
              ? (KeyBoardConfig().shift
                  ? KeyBoardConfig().buttonlistNo
                  : KeyBoardConfig().buttonlistCaps)
              : (KeyBoardConfig().shift
                  ? KeyBoardConfig().buttonlistCaps
                  : KeyBoardConfig().buttonlistNo);

          final inputBorder = OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: KeyBoardConfig().primaryButtonColor));
          var maskFormatter = new MaskTextInputFormatter(
              mask: mask, filter: {"0": RegExp(r'[0-9]')});

          return Container(
            height: 400.r,
            color: KeyBoardConfig().primaryBKColor,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    focusNode: focusNode,
                    autofocus: true,
                    obscureText: obscureText ?? false,
                    controller: controller,
                    decoration: InputDecoration(
                      filled: true,
                      border: inputBorder,
                      focusedBorder: inputBorder,
                      enabledBorder: inputBorder,
                    ),
                    inputFormatters: [maskFormatter],
                    onEditingComplete: onEnter,
                  ),
                ),
                Expanded(
                  child: Column(
                      //Get 1D Array from 2D Array
                      children: buttonlist.map<Widget>((e) {
                    return (
                        // Call Key Distributor Method With Single Dimension Array
                        buildRowOne(e));
                  }).toList() // <-- Column
                      ),
                ),
              ],
            ),
          );
        });
  }

  //Button Distributor need Single dimension array
  Expanded buildRowOne(List buttonNames) {
    return Expanded(
        child: Row(
            //Get Value from Array
            children: buttonNames.map<Widget>((e) {
      // Call Related Button according to Value
      switch (e) {
        case ' ':
          return TextKey(
            controller: controller,
            text: ' ',
            flex: 7,
            onTextInput: _textInputHandler,
            mask: mask,
          );
        case 'Enter':
          return EnterKey(
            flex: 2,
            onEnter: _enterHandler,
          );
        case 'CapsLock':
          return CapsKey(
              capsPress: true,
              flex: 2,
              capsLock: _capsLockHandler,
              focusNode: focusNode);
        case 'Tab':
          return TabKey(
              controller: controller,
              text: e,
              flex: 2,
              onTextInput: _textInputHandler,
              focusNode: focusNode);
        case 'Shift':
          return ShiftKey(
              shiftPress: true,
              flex: 2,
              shift: _shiftLockHandler,
              focusNode: focusNode);
        case 'backspace':
          return BackspaceKey(
            controller: controller,
            flex: 2,
            onBackspace: _backspaceHandler,
            focusNode: focusNode,
          );
        case 'right':
          return RightArrowKey(
            text: e,
            controller: controller,
            onRightPress: _rightArrowHandler,
            focusNode: focusNode,
          );
        case 'left':
          return LeftArrowKey(
            text: e,
            controller: controller,
            onLeftPress: _leftArrowHandler,
            focusNode: focusNode,
          );
        case 'Ctrl':
          return CtrlKey(
              text: e,
              controller: controller,
              onCtrlPress: null,
              focusNode: focusNode);
        case 'Alt':
          return AltKey(
              text: e,
              controller: controller,
              onAltPress: null,
              focusNode: focusNode);
        case 'Del':
          return DelKey(
              controller: controller,
              flex: 1,
              onDeletePress: _deleteHandler,
              focusNode: focusNode);
        case 'na':
          return NullKey();
        default:
          return TextKey(
            controller: controller,
            text: e,
            onTextInput: _textInputHandler,
            mask: mask,
            focusNode: focusNode,
          );
      }
    }).toList()));
  }
}
