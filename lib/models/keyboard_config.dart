/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/22/21, 9:28 AM
 */

import 'dart:ui';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:supercharged/supercharged.dart';

/// This singleton class contains the all keyboard configs
class KeyBoardConfig {
  static final KeyBoardConfig _singleton = KeyBoardConfig._internal();
  factory KeyBoardConfig() {
    return _singleton;
  }
  KeyBoardConfig._internal();

  // Keyboard CapsLock On Off
  bool capsLock = false;

  // Keyboard Shift On Off
  bool shift = false;

  // Keyboard button main color
  Color primaryButtonColor = "#2a3139".toColor();

  // Keyboard button special color
  Color specialButtonColor = "#2a3139".toColor();

  // Keyboard button special active color
  Color specialButtonActiveColor = "#404040".toColor();

  // Keyboard background main color
  Color primaryBKColor = "#ffffff".toColor();

  //Key List need 2D array
  List buttonlistCaps = [
    [
      'ESC',
      '~',
      '!',
      '@',
      '#',
      '\$',
      '%',
      '^',
      '&',
      '*',
      '(',
      ')',
      '_',
      '+',
      'Del',
      'backspace'
    ],
    [
      'Tab',
      'Q',
      'W',
      'E',
      'R',
      'T',
      'Y',
      'U',
      'I',
      'O',
      'P',
      '{',
      '}',
      '|',
      '?',
      '"'
    ],
    [
      'CapsLock',
      'A',
      'S',
      'D',
      'F',
      'G',
      'H',
      'J',
      'K',
      'L',
      ':',
      '<',
      '>',
      'Enter'
    ],
    ['Shift', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'na', 'up', 'na', 'Shift'],
    ['Ctrl', 'Alt', ' ', 'left', 'down', 'right', 'Alt', 'Ctrl']
  ];

  List buttonlistNo = [
    [
      'ESC',
      '`',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '0',
      '-',
      '=',
      'Del',
      'backspace'
    ],
    [
      'Tab',
      'q',
      'w',
      'e',
      'r',
      't',
      'y',
      'u',
      'i',
      'o',
      'p',
      '[',
      ']',
      '\\',
      '/',
      "'"
    ],
    [
      'CapsLock',
      'a',
      's',
      'd',
      'f',
      'g',
      'h',
      'j',
      'k',
      'l',
      ';',
      ',',
      '.',
      'Enter'
    ],
    ['Shift', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'na', 'up', 'na', 'Shift'],
    ['Ctrl', 'Alt', ' ', 'left', 'down', 'right', 'Alt', 'Ctrl']
  ];
  List numbuttonlist = [
    ['Void', '/', '*', '-'],
    ['7', '8', '9', '+'],
    ['4', '5', '6', 'backspace'],
    ['1', '2', '3', 'Enter'],
    ['0', '00', '.', 'Del'],
  ];

  //POS Keyboard design settings
  Color bkColor = POSConfig().posKeyBoardBackgroundColor.toColor();
  Color gradiant1 = POSConfig().posKeyBoardGradient1.toColor();
  Color gradiant2 = POSConfig().posKeyBoardGradient2.toColor();
  Color gradiant3 = POSConfig().posKeyBoardGradient3.toColor();

  double borderWidth = 1.5;
  double fontSize = 35;
  double posKeyboardHeight = 300;

  //POS Special Key Styles
  Color buttonBorder = POSConfig().posKeyBoardBorderColor.toColor();

  Color enterKey = POSConfig().posKeyBoardEnterColor.toColor();
  Color enterKeyText = POSConfig().posKeyBoardEnterTxtColor.toColor();

  Color voidKey = POSConfig().posKeyBoardVoidColor.toColor();
  Color voidKeyText = POSConfig().posKeyBoardVoidTxtColor.toColor();

  Color exactKey = POSConfig().posKeyBoardExactColor.toColor();
  Color exactKeyText = POSConfig().posKeyBoardExactTxtColor.toColor();

  //POS key List

  List poskeys = [
    ['Void', '7', '8', '9'],
    ['-', '4', '5', '6'],
    ['*', '1', '2', '3'],
    ['0', '00', '.', 'Enter']
  ];
  List poskeys2 = [
    ['Exact', '7', '8', '9'],
    ['-', '4', '5', '6'],
    ['*', '1', '2', '3'],
    ['0', '00', '.', 'Enter']
  ];
  List poskeys3 = [
    ['Clear', '7', '8', '9'],
    ['-', '4', '5', '6'],
    ['*', '1', '2', '3'],
    ['0', '00', '.', 'Enter']
  ];
}
