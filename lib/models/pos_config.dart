/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/21/21, 11:31 AM
 */

import 'package:checkout/models/pos/client_license_results.dart';
import 'package:checkout/models/pos/pos_denomination_model.dart';
import 'package:flutter/material.dart';

import 'pos/setup_result.dart';

/// This singleton class contains the all pos configs
class POSConfig {
  static final POSConfig _singleton = POSConfig._internal();

  factory POSConfig() {
    return _singleton;
  }

  POSConfig._internal();

  //identify the pos is in demo mode or production mode
  bool demoPOS = false;
  bool saas = false;
  bool localMode = false;
  bool ecr = true;
  bool bypassEodValidation = false;
  Setup? setup;
  ClientLicense? clientLicense;
  bool allowLocalMode = true;
  bool allow_sync_bills = true;
  bool auto_cust_popup = true;

  bool trainingMode = false;

  //can display the virtual keyboard
  bool touchKeyboardEnabled = true;

  String terminalId = "001";
  String setupLocation = "";
  String locCode = "";
  String comCode = "";
  String comName = "";
  String setupLocationName = "";
  String backgroundImage = "";
  String licenseMessage = "";
  Color licenseMessageColor = Colors.red;
  bool expired = false;

  // String server = "http://localhost:4971/api/";
  // String local = "http://localhost:4971/api/";
  // String server = "http://localhost:4971/api/";
  // String posImageServer = "http://34.124.156.165:5003/";

  // String server = "http://34.124.156.165:71/api/";
  //  String local = "http://34.124.156.165:71/api/";
  // String posImageServer = "http://34.124.156.165:5003/";

  String server = "";
  String local = "";
  String posImageServer = "";
  String webSocketUrl = "";
  String password = "";
  String dualScreenWebsite = "";
  String enablePollDisplay = "";
  String pollDisplayPort = '';
  int pollDisplayPortBaudRate = 9600;
  double screen_width = 0;
  double screen_height = 0;
  bool default_size = false;
  bool singleSwipeActive = false;
  String currencyCode = 'Rs.';

  // String loyaltyServerLocal = "http://10.1.1.70:72/api/";
  // String loyaltyServer = "http://10.1.1.70:72/api/";
  //
  String loyaltyServerCentral = "";
  bool hasCentralLoyaltyServer = false;
  String loyaltyServerOutlet = "";
  String loyaltyServerImage = "";

  // this is the square/rounded button radius
  double rounderBorderRadiusTopRight = 15.0;
  double rounderBorderRadiusTopLeft = 0.0;
  double rounderBorderRadiusBottomLeft = 15.0;
  double rounderBorderRadiusBottomRight = 0.0;

  // this is the rounded button radius for other
  double rounderBorderRadius2 = 8.0;

  //This is the primary color
  String primaryColor = "5B9BD5";

  // this light color used all over the project.
  String primaryLightColor = "f5f5f5f5";

  // this dark color used all over the project.
  String primaryDarkColor = "000000";
  //this is the background color
  String backgroundColor = "3661AD";

  // this is the container size of the app.
  double containerSize = 555;

  // this is the top margin of the app.
  double topMargin = 15;

  // this gray color used as the app's default dark gray colr.
  String primaryDarkGrayColor = "757575";

  // cart card lengths
  double cardIdLength = 150;
  double cardNameLength = 0; //if this is 0 total width will assigned
  double cardPriceLength = 150;
  double cardQtyLength = 120;
  double cardTotalLength = 180;
  double cardFontSize = 26;

  // cart dynamic button width
  double cartDynamicButtonWidth = 150;
  double cartDynamicButtonHeight = 70;
  double cartDynamicButtonPadding = 4;
  double cartDynamicButtonFontSize = 11;

  //This is the default lhs and rhs sides of the checkoutScreen
  bool defaultCheckoutLSH = true;
  bool checkoutTableView = false;
  // this will display the item list as batch or single
  bool cartBatchItem = false;
  double checkoutDataTableFontSize = 14;

  // cart dynamic button width
  double paymentDynamicButtonWidth = 275;
  double paymentDynamicButtonHeight = 70;
  double paymentDynamicButtonPadding = 3;
  double paymentDynamicButtonFontSize = 11;

  //  this is the top app bar size
  double topAppBarSize = 70;

  bool requiredNic = true;
  bool requiredEmail = true;
  bool requiredDob = true;
  bool requiredAddress = true;
  bool requiredGender = true;
  // check otp function is enabled or not
  bool otpEnabled = false;

  // invoice based on report or text file
  bool reportBasedInvoice = false;
  bool showedGiftVoucherTutorials = false;

  //set keyboard config colors
  String posKeyBoardBackgroundColor = "3964b3";
  String posKeyBoardGradient1 = "2d518f";
  String posKeyBoardGradient2 = "3964b3";
  String posKeyBoardGradient3 = "2d518f";
  String posKeyBoardBorderColor = "fe0000";
  String posKeyBoardEnterColor = "deeaf6";
  String posKeyBoardEnterTxtColor = "fe0000";
  String posKeyBoardVoidColor = "fe0000";
  String posKeyBoardVoidTxtColor = "deeaf6";
  String posKeyBoardExactColor = "ffcc00";
  String posKeyBoardExactTxtColor = "deeaf6";

  //it is for store the validation otp when customer creation
  static String validateOTP = '';

  static String crystalPath = '';

  //Necessary for local printing
  static String printerName = 'POS-80C';
  static int font_a_length = 42;
  static int font_b_length = 56;
  static String localPrintPath =
      'C:/checkout/LOCAL_PRINT'; //Contains all xml templates and images related to local printing
  static String localPrintData =
      ''; // This is used to temperorily catch the data and using it in the test print function (any)
  static List<POSDenominationDetail> denominationDet =
      []; // This is used to temperorily catch the data and using it in the test print function (manager sign off)
  static List<POSDenominationModel> denominations =
      []; // This is used to temperorily catch the data and using it in the test print function (manager sign off)
}
