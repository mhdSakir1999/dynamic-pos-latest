/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/21/21, 5:44 PM
 * Corrections & New functions: TM.Sakir at 2023-12-07 5pm.
 */

import 'package:checkout/bloc/keyboard_bloc.dart';
import 'package:checkout/models/enum/keyboard_type.dart';
import 'package:checkout/models/keyboard_config.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';

/// All Key Designs in here

// new change: focusNodes are added for gaining focus when the button is pressed, ctrl,alt,arrow keys are seperated from text keys(previously they were functioning like regular text keys)

class TextKey extends StatelessWidget {
  const TextKey(
      {Key? key,
      required this.text,
      this.onTextInput,
      this.flex = 1,
      required this.controller,
      this.mask,
      this.focusNode})
      : super(key: key);
  final String text;
  final String? mask;
  final ValueSetter<String>? onTextInput;
  final int flex;
  final FocusNode? focusNode;

  // The controller connected to the InputField
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().primaryButtonColor,
          child: InkWell(
            onTap: () {
              print(text);

              if (text == 'up') {
                return;
              }
              if (text == 'down') {
                return;
              }
              if (text == 'ESC') {
                Navigator.pop(context);
                return;
              }
              //Bind Key with event trigger
              String keyValue = text;
              //Bind Key with event trigger
              KeyBoardConfig().shift = false;
              keyBoardBloc.setKey(keyType.None);
              if ((keyValue == '*' || keyValue == "-")) {
                //return;
              }
              if (mask != null) {
                //0000-****-****-0000
                String enteredValue = controller?.text ?? '';
                int maskLen = mask!.length;
                int enteredLen = enteredValue.length;

                if (enteredLen < maskLen) {
                  String currentMask = mask![enteredLen];
                  //validate input this mean entered value should be numeric
                  if (currentMask == '0') {
                    int? isNum = int.tryParse(keyValue);
                    if (isNum == null) {
                      return;
                    }
                  }

                  for (int i = enteredLen; i < maskLen; i++) {
                    if (i + 1 < maskLen) {
                      String nextChar = mask![i + 1];

                      if (nextChar != '0') {
                        //fill next char
                        keyValue += nextChar;
                      } else {
                        break;
                      }
                    }
                  }
                  // print('current value: $keyValue, entered len: $enteredLen, next char: $nextChar');
                } else {
                  return;
                }

                // String textFieldValue = controller?.text ?? '';
                // int maskLen = mask!.length;
                // int valLen = textFieldValue.length;
                // if (valLen != maskLen) {
                //   if (mask![valLen] != '0') {
                //     keyValue = mask![valLen];
                //   }
                // } else {
                //   return;
                // }
              }
              // new change by Sakir... whenever we click the text button it typed at last position

              // onTextInput?.call(keyValue);
              // controller!.text += keyValue;
              // controller!.selection = TextSelection.fromPosition(
              //     TextPosition(offset: controller!.text.length));

              //correction:
              onTextInput?.call(keyValue);
              // Get the current position of the cursor
              final int cursorPosition = controller!.selection.baseOffset;

              // Insert the desired text at the cursor position
              controller!.text = controller!.text.substring(0, cursorPosition) +
                  keyValue +
                  controller!.text.substring(cursorPosition);
              if (cursorPosition <= controller!.text.length) {
                controller!.selection = TextSelection.fromPosition(
                    TextPosition(offset: cursorPosition + 1));
              }
              // also passing the focus node to get the focus/cursor available at that position
              focusNode?.requestFocus();
            },
            child: Container(
              child: Center(child: Text(text)),
            ),
          ),
        ),
      ),
    );
  }
}

class TabKey extends StatelessWidget {
  const TabKey({
    Key? key,
    required this.text,
    this.onTextInput,
    this.flex = 1,
    required this.controller,
    this.focusNode,
  }) : super(key: key);
  final String text;
  final ValueSetter<String>? onTextInput;
  final int flex;
  final FocusNode? focusNode;

  // The controller connected to the InputField
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().specialButtonColor,
          child: InkWell(
            onTap: () {
              onTextInput?.call(text);
              controller!.text += '   ';
              controller!.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller!.text.length));
              focusNode?.requestFocus();
            },
            child: Container(
              child: Center(child: Text(text)),
            ),
          ),
        ),
      ),
    );
  }
}

class BackspaceKey extends StatelessWidget {
  const BackspaceKey(
      {Key? key,
      this.onBackspace,
      this.flex = 1,
      required this.controller,
      this.focusNode})
      : super(key: key);
  final VoidCallback? onBackspace;
  final int flex;
  final FocusNode? focusNode;

  // The controller connected to the InputField
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().specialButtonColor,
          child: InkWell(
            onLongPress: () {
              controller?.clear();
              focusNode?.requestFocus();
            },
            onTap: () {
              onBackspace?.call();
              if (controller!.text.isNotEmpty) {
                var currentPosition = controller!.selection.baseOffset;
                controller!.text =
                    controller!.text.substring(0, currentPosition - 1) +
                        controller!.text.substring(currentPosition);
                controller!.selection = TextSelection.fromPosition(
                    TextPosition(offset: currentPosition - 1));
              }

              focusNode?.requestFocus();
            },
            child: Container(
              child: Center(
                child: Icon(
                  Icons.backspace_outlined,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//new button: declare right arrow button as new button (previously it considered as a text button) and adding propriate function
class RightArrowKey extends StatelessWidget {
  const RightArrowKey(
      {Key? key,
      required this.text,
      this.onRightPress,
      this.flex = 1,
      required this.controller,
      this.focusNode})
      : super(key: key);
  final String text;
  final VoidCallback? onRightPress;
  final int flex;
  final FocusNode? focusNode;

  // The controller connected to the InputField
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().specialButtonColor,
          child: InkWell(
            onLongPress: () {
              focusNode?.requestFocus();
            },
            onTap: () {
              onRightPress?.call();
              if (controller!.text.isNotEmpty) {
                var position = controller!.selection.baseOffset;
                if (position < controller!.text.length) {
                  // Move the cursor one position to the right
                  controller!.selection = TextSelection.fromPosition(
                      TextPosition(offset: position + 1));
                }
              }
              focusNode?.requestFocus();
            },
            child: Container(
              child: Center(child: Text(text)),
            ),
          ),
        ),
      ),
    );
  }
}

//new button: declare left arrow button as new button (previously it considered as a text button) and adding propriate function
class LeftArrowKey extends StatelessWidget {
  const LeftArrowKey(
      {Key? key,
      required this.text,
      this.onLeftPress,
      this.flex = 1,
      required this.controller,
      this.focusNode})
      : super(key: key);
  final String text;
  final VoidCallback? onLeftPress;
  final int flex;
  final FocusNode? focusNode;

  // The controller connected to the InputField
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().specialButtonColor,
          child: InkWell(
            onLongPress: () {
              focusNode?.requestFocus();
            },
            onTap: () {
              onLeftPress?.call();
              if (controller!.text.isNotEmpty) {
                var position = controller!.selection.baseOffset;
                if (position <= controller!.text.length) {
                  // Move the cursor one position to the left
                  controller!.selection = TextSelection.fromPosition(
                      TextPosition(offset: position - 1));
                }
              }
              focusNode?.requestFocus();
            },
            child: Container(
              child: Center(child: Text(text)),
            ),
          ),
        ),
      ),
    );
  }
}

//new function: deleting right side texts
class DelKey extends StatelessWidget {
  const DelKey({
    Key? key,
    this.onDeletePress,
    this.flex = 1,
    required this.controller,
    this.focusNode,
  }) : super(key: key);
  final VoidCallback? onDeletePress;
  final int flex;
  final FocusNode? focusNode;

  // The controller connected to the InputField
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().specialButtonColor,
          child: InkWell(
            onTap: () {
              // onDeletePress?.call();
              // if (controller!.text.isNotEmpty) {
              //   controller!.text = controller!.text.substring(
              //       0, controller!.text.length - controller!.text.length);
              //   controller!.selection = TextSelection.fromPosition(
              //       TextPosition(offset: controller!.text.length));
              // }

              onDeletePress?.call();
              if (controller!.text.isNotEmpty) {
                var currentPosition = controller!.selection.baseOffset;
                controller!.text =
                    controller!.text.substring(0, currentPosition) +
                        controller!.text.substring(currentPosition + 1);
                controller!.selection = TextSelection.fromPosition(
                    TextPosition(offset: currentPosition));
              }

              focusNode?.requestFocus();
            },
            child: Container(
              child: Center(
                child: Text('Del'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CapsKey extends StatelessWidget {
  const CapsKey({
    Key? key,
    this.capsLock,
    this.flex = 1,
    required this.capsPress,
    this.focusNode,
  }) : super(key: key);
  final bool capsPress;
  final ValueChanged<bool>? capsLock;
  final int flex;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().capsLock
              ? KeyBoardConfig().specialButtonActiveColor
              : KeyBoardConfig().specialButtonColor,
          child: InkWell(
            onTap: () {
              KeyBoardConfig().capsLock = !KeyBoardConfig().capsLock;
              //debugPrint(KeyBoardConfig().capsLock.toString());
              capsLock?.call(capsPress);
              //Bind Key with event trigger
              keyBoardBloc.setKey(keyType.CapsLock);
              focusNode?.requestFocus();
            },
            child: Container(
              child: Center(
                child: Icon(Icons.keyboard_capslock, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShiftKey extends StatelessWidget {
  const ShiftKey({
    Key? key,
    this.shift,
    this.flex = 1,
    required this.shiftPress,
    this.focusNode,
  }) : super(key: key);
  final bool shiftPress;
  final ValueChanged<bool>? shift;
  final int flex;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().shift
              ? KeyBoardConfig().specialButtonActiveColor
              : KeyBoardConfig().specialButtonColor,
          child: InkWell(
            onTap: () {
              KeyBoardConfig().shift = !KeyBoardConfig().shift;
              shift?.call(shiftPress);
              //Bind Key with event trigger
              keyBoardBloc.setKey(keyType.Shift);
              focusNode?.requestFocus();
            },
            child: Container(
              child: Center(
                child: Text('Shift'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EnterKey extends StatelessWidget {
  const EnterKey({
    Key? key,
    this.onEnter,
    this.flex = 1,
    this.textInputAction,
  }) : super(key: key);
  final VoidCallback? onEnter;
  final int flex;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().specialButtonColor,
          child: InkWell(
            onTap: () {
              onEnter?.call();
              //Bind Key with event trigger
              keyBoardBloc.setKey(keyType.Enter);
            },
            child: Container(
              child: Center(
                child: Text('Enter'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NullKey extends StatelessWidget {
  const NullKey({
    Key? key,
    this.flex = 1,
  }) : super(key: key);
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          color: KeyBoardConfig().primaryBKColor,
          child: Container(
            child: Center(
              child: Text(''),
            ),
          ),
        ),
      ),
    );
  }
}

class CtrlKey extends StatelessWidget {
  const CtrlKey({
    Key? key,
    required this.text,
    this.onCtrlPress,
    this.flex = 1,
    required this.controller,
    this.focusNode,
  }) : super(key: key);
  final String text;
  final VoidCallback? onCtrlPress;
  final int flex;
  final FocusNode? focusNode;

  // The controller connected to the InputField
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().specialButtonColor,
          child: InkWell(
            onTap: () {
              focusNode?.requestFocus();
            },
            child: Container(
              child: Center(child: Text(text)),
            ),
          ),
        ),
      ),
    );
  }
}

class AltKey extends StatelessWidget {
  const AltKey({
    Key? key,
    required this.text,
    this.onAltPress,
    this.flex = 1,
    required this.controller,
    this.focusNode,
  }) : super(key: key);
  final String text;
  final VoidCallback? onAltPress;
  final int flex;
  final FocusNode? focusNode;

  // The controller connected to the InputField
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.0),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          color: KeyBoardConfig().specialButtonColor,
          child: InkWell(
            onTap: () {
              focusNode?.requestFocus();
            },
            child: Container(
              child: Center(child: Text(text)),
            ),
          ),
        ),
      ),
    );
  }
}

//POS Keyboard Keys
BorderRadius pOSKeyBoarder() {
  final config = POSConfig();
  final inputBorderRadius = BorderRadius.only(
    bottomLeft: Radius.circular(config.rounderBorderRadiusBottomLeft * 1.25),
    bottomRight: Radius.circular(config.rounderBorderRadiusBottomRight * 1.25),
    topRight: Radius.circular(config.rounderBorderRadiusTopRight * 1.25),
    topLeft: Radius.circular(config.rounderBorderRadiusTopLeft * 1.25),
  );
  return inputBorderRadius;
}

class NumKey extends StatelessWidget {
  const NumKey({
    Key? key,
    required this.text,
    this.onTextInput,
    this.flex = 1,
    this.controller,
    this.mask,
    required this.disableArithmetic,
    this.focusNode,
  }) : super(key: key);
  final String text;
  final String? mask;
  final bool disableArithmetic;
  final ValueSetter<String>? onTextInput;
  final int flex;
  final FocusNode? focusNode;

  // The controller connected to the InputField
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Material(
          borderRadius: pOSKeyBoarder(),
          color: Colors.grey,
          child: InkWell(
            borderRadius: pOSKeyBoarder(),
            onTap: () {
              String keyValue = text;
              //Bind Key with event trigger
              KeyBoardConfig().shift = false;
              keyBoardBloc.setKey(keyType.None);
              if (disableArithmetic && (keyValue == '*' || keyValue == "-")) {
                return;
              }
              print(mask);
              if (mask != null) {
                //0000-****-****-0000
                String enteredValue = controller?.text ?? '';
                int maskLen = mask!.length;
                int enteredLen = enteredValue.length;

                if (enteredLen < maskLen) {
                  for (int i = enteredLen; i < maskLen; i++) {
                    if (i + 1 < maskLen) {
                      String nextChar = mask![i + 1];

                      if (nextChar != '0') {
                        //fill next char
                        keyValue += nextChar;
                      } else {
                        break;
                      }
                    }
                  }

                  // print('current value: $keyValue, entered len: $enteredLen, next char: $nextChar');
                } else {
                  return;
                }

                // String textFieldValue = controller?.text ?? '';
                // int maskLen = mask!.length;
                // int valLen = textFieldValue.length;
                // if (valLen != maskLen) {
                //   if (mask![valLen] != '0') {
                //     keyValue = mask![valLen];
                //   }
                // } else {
                //   return;
                // }
              }

              onTextInput?.call(keyValue);
              controller!.text += keyValue;
              controller!.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller!.text.length));

              focusNode?.requestFocus();
            },
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: pOSKeyBoarder(),
                  border: Border.all(
                      color: KeyBoardConfig().buttonBorder,
                      width: KeyBoardConfig().borderWidth,
                      style: BorderStyle.solid),
                  gradient: LinearGradient(colors: [
                    KeyBoardConfig().gradiant1,
                    KeyBoardConfig().gradiant2,
                    KeyBoardConfig().gradiant3
                  ])),
              child: Center(
                  child: Text(
                text,
                style: TextStyle(fontSize: KeyBoardConfig().fontSize),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class POSEnterKey extends StatelessWidget {
  const POSEnterKey({
    Key? key,
    required this.text,
    this.onTextInput,
    this.flex = 1,
    this.controller,
    required this.onPressed,
  }) : super(key: key);
  final String text;
  final ValueSetter<String>? onTextInput;
  final int flex;

  // The controller connected to the InputField
  final TextEditingController? controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Material(
          borderRadius: pOSKeyBoarder(),
          color: Colors.grey,
          child: InkWell(
            onTap: () {
              keyBoardBloc.setKey(keyType.POSEnter);
              onPressed();
            },
            borderRadius: pOSKeyBoarder(),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: pOSKeyBoarder(),
                  border: Border.all(
                      color: KeyBoardConfig().buttonBorder,
                      width: KeyBoardConfig().borderWidth,
                      style: BorderStyle.solid),
                  gradient: LinearGradient(colors: [
                    KeyBoardConfig().enterKey,
                    KeyBoardConfig().enterKey,
                    KeyBoardConfig().enterKey
                  ])),
              child: Center(
                  child: Text(
                text,
                style: TextStyle(
                  fontSize: KeyBoardConfig().fontSize,
                  color: KeyBoardConfig().enterKeyText,
                ),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class POSVoidKey extends StatelessWidget {
  const POSVoidKey({
    Key? key,
    required this.text,
    this.onTextInput,
    this.flex = 1,
    this.controller,
    required this.onPressed,
  }) : super(key: key);
  final String text;
  final ValueSetter<String>? onTextInput;
  final int flex;

  // The controller connected to the InputField
  final TextEditingController? controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Material(
          borderRadius: pOSKeyBoarder(),
          color: Colors.grey,
          child: InkWell(
            borderRadius: pOSKeyBoarder(),
            onTap: () {
              keyBoardBloc.setKey(keyType.POSVoid);
              onPressed();
            },
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: pOSKeyBoarder(),
                  border: Border.all(
                      color: KeyBoardConfig().buttonBorder,
                      width: KeyBoardConfig().borderWidth,
                      style: BorderStyle.solid),
                  gradient: LinearGradient(colors: [
                    KeyBoardConfig().voidKey,
                    KeyBoardConfig().voidKey,
                    KeyBoardConfig().voidKey
                  ])),
              child: Center(
                  child: Text(
                text,
                style: TextStyle(
                    fontSize: KeyBoardConfig().fontSize,
                    color: KeyBoardConfig().voidKeyText),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class POSExactKey extends StatelessWidget {
  const POSExactKey({
    Key? key,
    required this.text,
    this.onTextInput,
    this.flex = 1,
    this.controller,
    required this.onPressed,
  }) : super(key: key);
  final String text;
  final ValueSetter<String>? onTextInput;
  final int flex;

  // The controller connected to the InputField
  final TextEditingController? controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Material(
          borderRadius: pOSKeyBoarder(),
          color: Colors.grey,
          child: InkWell(
            borderRadius: pOSKeyBoarder(),
            onTap: () {
              //Bind Key with event trigger
              keyBoardBloc.setKey(keyType.POSExact);
              onPressed();
            },
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: pOSKeyBoarder(),
                  border: Border.all(
                      color: KeyBoardConfig().buttonBorder,
                      width: KeyBoardConfig().borderWidth,
                      style: BorderStyle.solid),
                  gradient: LinearGradient(colors: [
                    KeyBoardConfig().exactKey,
                    KeyBoardConfig().exactKey,
                    KeyBoardConfig().exactKey
                  ])),
              child: Center(
                  child: Text(
                text,
                style: TextStyle(
                    fontSize: KeyBoardConfig().fontSize,
                    color: KeyBoardConfig().exactKeyText),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class POSClearKey extends StatelessWidget {
  const POSClearKey({
    Key? key,
    required this.text,
    this.onTextInput,
    this.flex = 1,
    this.controller,
    required this.onPressed,
  }) : super(key: key);
  final String text;
  final ValueSetter<String>? onTextInput;
  final int flex;
  final VoidCallback onPressed;

  // The controller connected to the InputField
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Material(
          borderRadius: pOSKeyBoarder(),
          color: Colors.grey,
          child: InkWell(
            borderRadius: pOSKeyBoarder(),
            onTap: () {
              //Bind Key with event trigger
              keyBoardBloc.setKey(keyType.POSClear);
              onPressed();
            },
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: pOSKeyBoarder(),
                  border: Border.all(
                      color: KeyBoardConfig().buttonBorder,
                      width: KeyBoardConfig().borderWidth,
                      style: BorderStyle.solid),
                  gradient: LinearGradient(colors: [
                    KeyBoardConfig().exactKey,
                    KeyBoardConfig().exactKey,
                    KeyBoardConfig().exactKey
                  ])),
              child: Center(
                  child: Text(
                text,
                style: TextStyle(
                    fontSize: KeyBoardConfig().fontSize,
                    color: KeyBoardConfig().exactKeyText),
              )),
            ),
          ),
        ),
      ),
    );
  }
}
