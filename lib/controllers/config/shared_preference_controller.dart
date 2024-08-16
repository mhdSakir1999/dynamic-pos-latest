/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/29/21, 3:21 PM
 */

import 'dart:convert';
import 'dart:io';

import 'package:checkout/components/api_client.dart';
import 'package:checkout/controllers/activation/activation_controller.dart';
import 'package:checkout/controllers/config/cart_config_controller.dart';
import 'package:checkout/controllers/config/payment_config_controller.dart';
import 'package:checkout/controllers/config/pos_keyboard_config_controller.dart';
import 'package:checkout/controllers/config/square_button_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/controllers/setup_controller.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supercharged/supercharged.dart';

import '../../bloc/notification_bloc.dart';
import '../../components/pos_platform.dart';

class SharedPreferenceController {
  static SharedPreferences? _preferences;

  final String _roundedBorderRadius = "rounded_border_radius";
  final String _toolbarHeight = "toolbar_height";
  final String _containerSize = "container_height";
  final String _primaryColor = "primary_color";
  final String _primaryColorDark = "primary_color_dark";
  final String _primaryColorLight = "primary_color_light";
  final String _primaryColorGrey = "primary_color_muted";
  final String _backgroundColor = "background_color";
  final String _touchKeyBoard = "touch_keyboard";
  final String _promotion = "disable_promotions";
  final String _customerPopup = "customer_popup";
  final String _disableCartImage = "disable_cart_image";
  final String _saveInvoiceLocal = "save_invoice_local";
  final String _terminalId = "terminal_id";
  final String _posServer = "pos_server";
  final String _posLocalServer = "pos_local_server";
  final String _posImageServer = "pos_image_server";
  final String _loyaltyServer = "";
  final String _loyaltyLocalServer = "loyalty_local_server";
  final String _loyaltyImageServer = "loyalty_image_server";
  final String _locCode = "loc_code";
  final String _reportBasedInvoice = "report_based_invoice";
  final String _ecr = "ecr";
  final String _backgroundImage = "background_image";
  final String _gvTutorial = "gv_tutorial";
  int i = 0;
  static init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// new by [TM.Sakir]
  /// closing the previously running api and launching the local pos api
  Future openAPI() async {
    try {
      await Process.run(
          'cmd.exe', ['/c', 'taskkill /F /IM Dynamic_POS_REST_API.exe']);
      LogWriter().saveLogsToFile('ERROR_Log_', ['Closing previous api...']);
    } catch (e) {
      await LogWriter().saveLogsToFile(
          'ERROR_Log_', ['Error Closing previous api: ${e.toString()}']);
      print('Error: $e');
    }
    try {
      await Process.run('cmd.exe', ['/c', 'taskkill /F /IM CrystalReport.exe']);
      LogWriter().saveLogsToFile('ERROR_Log_', ['Closing previous api...']);
    } catch (e) {
      await LogWriter().saveLogsToFile(
          'ERROR_Log_', ['Error Closing previous api: ${e.toString()}']);
      print('Error: $e');
    }
    await dotenv.load(fileName: "assets/.env");
    try {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.info, "Starting Local POS API..."));
      String? localAPIPath = dotenv.env['LOCAL_API_PATH'];
      //  var exec = "${localAPIPath!} dotnet run --urls http://0.0.0.0:71";
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.info, "path: $localAPIPath"));

      // var command = Process.run(
      //     'cmd.exe', ['/c', 'cd $localAPIPath && Dynamic_POS_REST_API.exe'],
      //     runInShell: true);
      Process.run(
        'Dynamic_POS_REST_API.exe',
        [],
        runInShell: true,
        workingDirectory: localAPIPath,
      );
    } catch (e) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Error on starting Local POS API: $e"));
    }
  }

  Future saveConfig(POSConfig posConfig) async {
    //save square button configs
    SquareButtonController squareButtonController =
        SquareButtonController(_preferences!);
    squareButtonController
        .setSquareButtonTopLeftRadius(posConfig.rounderBorderRadiusTopLeft);
    squareButtonController
        .setSquareButtonTopRightRadius(posConfig.rounderBorderRadiusTopRight);
    squareButtonController.setSquareButtonBottomLeftRadius(
        posConfig.rounderBorderRadiusBottomLeft);
    squareButtonController.setSquareButtonBottomRightRadius(
        posConfig.rounderBorderRadiusBottomRight);

    //cart configs
    CartConfigController cartConfigController =
        CartConfigController(_preferences!);
    cartConfigController.setCardIdLength(posConfig.cardIdLength);
    cartConfigController.setCardNameLength(posConfig.cardNameLength);
    cartConfigController.setCardPriceLength(posConfig.cardPriceLength);
    cartConfigController.setCardQtyLength(posConfig.cardQtyLength);
    cartConfigController.setCardTotalLength(posConfig.cardTotalLength);
    cartConfigController.setCardFontSizeLength(posConfig.cardFontSize);

    cartConfigController.setButtonHeight(posConfig.cartDynamicButtonHeight);
    cartConfigController.setButtonWidth(posConfig.cartDynamicButtonWidth);
    cartConfigController
        .setButtonSpaceBetween(posConfig.cartDynamicButtonPadding);
    cartConfigController.setButtonFontSize(posConfig.cartDynamicButtonFontSize);
    cartConfigController.setLHSMode(posConfig.defaultCheckoutLSH);
    cartConfigController.setTableView(posConfig.checkoutTableView);
    cartConfigController.setTableView(posConfig.checkoutTableView);
    cartConfigController
        .setDataTableFontSize(posConfig.checkoutDataTableFontSize);
    cartConfigController.setCartBatch(posConfig.cartBatchItem);

    PaymentConfigController paymentConfigController =
        PaymentConfigController(_preferences!);
    paymentConfigController
        .setButtonHeight(posConfig.paymentDynamicButtonHeight);
    paymentConfigController.setButtonWidth(posConfig.paymentDynamicButtonWidth);
    paymentConfigController
        .setButtonSpaceBetween(posConfig.paymentDynamicButtonPadding);
    paymentConfigController
        .setButtonFontSize(posConfig.paymentDynamicButtonFontSize);

    setLocCode(posConfig.locCode);

    setRoundedBorderRadius(posConfig.rounderBorderRadius2);
    setToolbarHeight(posConfig.topAppBarSize);
    setContainerWidth(posConfig.containerSize);
    setPrimaryColor(posConfig.primaryColor);
    setPrimaryColorDark(posConfig.primaryDarkColor);
    setPrimaryColorGrey(posConfig.primaryDarkGrayColor);
    setPrimaryColorLight(posConfig.primaryLightColor);
    setBackgroundColor(posConfig.backgroundColor);
    setTouchKeyboard(posConfig.touchKeyboardEnabled);
    setPromotionFlag(posConfig.disablePromotions);
    setCustomerPopup(posConfig.auto_cust_popup);
    setCartImageDisable(posConfig.disableCartImageLoad);
    setSaveInvoiceLocal(posConfig.saveInvoiceLocal);
    setTerminalId(posConfig.terminalId);
    print(posConfig.terminalId);
    // setPOSServer(posConfig.server);
    // setPOSLocalServer(posConfig.local);
    setPOSImageServer(posConfig.posImageServer);
    setLoyaltyServer(posConfig.loyaltyServerCentral);
    // setLoyaltyLocalServer(posConfig.loyaltyServerLocal);
    // setLoyaltyImageServer(posConfig.loyaltyServerLocal);
    setReportBasedInvoice(posConfig.reportBasedInvoice);
    setGvTutorial(posConfig.showedGiftVoucherTutorials);
    if (posConfig.locCode.isNotEmpty &&
        POSConfig().locCode != posConfig.locCode)
      setLoyaltyImageServer(posConfig.locCode);

    //set pos keyboard color
    POSKeyboardConfigController posKeyboardConfigController =
        POSKeyboardConfigController(_preferences!);
    posKeyboardConfigController
        .setBackgroundColor(POSConfig().posKeyBoardBackgroundColor);
    posKeyboardConfigController
        .setBorderColor(POSConfig().posKeyBoardBorderColor);

    posKeyboardConfigController
        .setGradient1Color(POSConfig().posKeyBoardGradient1);
    posKeyboardConfigController
        .setGradient2Color(POSConfig().posKeyBoardGradient2);
    posKeyboardConfigController
        .setGradient3Color(POSConfig().posKeyBoardGradient3);

    posKeyboardConfigController
        .setEnterKeyColor(POSConfig().posKeyBoardEnterColor);
    posKeyboardConfigController
        .setEnterKeyTxtColor(POSConfig().posKeyBoardEnterTxtColor);

    posKeyboardConfigController
        .setVoidKeyColor(POSConfig().posKeyBoardVoidColor);
    posKeyboardConfigController
        .setVoidKeyTxtColor(POSConfig().posKeyBoardVoidTxtColor);

    posKeyboardConfigController
        .setExactKeyColor(POSConfig().posKeyBoardExactColor);
    posKeyboardConfigController
        .setExactKeyTxtColor(POSConfig().posKeyBoardExactTxtColor);
    saveConfigLocal();
  }

  /// This function save the border radius
  Future setRoundedBorderRadius(double radius) async {
    return _preferences!.setDouble(_roundedBorderRadius, radius);
  }

  /// This method will save the tool bar height
  Future setToolbarHeight(double height) async {
    return _preferences!.setDouble(_toolbarHeight, height);
  }

  /// This method will save the container width size
  Future setContainerWidth(double height) async {
    return _preferences!.setDouble(_containerSize, height);
  }

  /// This method will save the primaryColor as String
  Future setPrimaryColor(String color) async {
    return _preferences!.setString(_primaryColor, color);
  }

  Future setPrimaryColorDark(String color) async {
    return _preferences!.setString(_primaryColorDark, color);
  }

  Future setPrimaryColorLight(String color) async {
    return _preferences!.setString(_primaryColorLight, color);
  }

  Future setPrimaryColorGrey(String color) async {
    return _preferences!.setString(_primaryColorGrey, color);
  }

  Future setBackgroundColor(String color) async {
    return _preferences!.setString(_backgroundColor, color);
  }

  Future setTouchKeyboard(bool enabled) async {
    return _preferences!.setBool(_touchKeyBoard, enabled);
  }

  Future setPromotionFlag(bool enabled) async {
    return _preferences!.setBool(_promotion, enabled);
  }

  Future setCustomerPopup(bool enabled) async {
    return _preferences!.setBool(_customerPopup, enabled);
  }

  Future setCartImageDisable(bool enabled) async {
    return _preferences!.setBool(_disableCartImage, enabled);
  }

  Future setSaveInvoiceLocal(bool enabled) async {
    return _preferences!.setBool(_saveInvoiceLocal, enabled);
  }

  Future setGvTutorial(bool showed) async {
    return _preferences!.setBool(_gvTutorial, showed);
  }

  Future setTerminalId(String value) async {
    return _preferences!.setString(_terminalId, value);
  }

  Future setPOSServer(String value) async {
    return _preferences!.setString(_posServer, value);
  }

  Future setPOSLocalServer(String value) async {
    return _preferences!.setString(_posLocalServer, value);
  }

  Future setPOSImageServer(String value) async {
    return _preferences!.setString(_posImageServer, value);
  }

  Future setLoyaltyServer(String value) async {
    return _preferences!.setString(_loyaltyServer, value);
  }

  Future setLoyaltyLocalServer(String value) async {
    return _preferences!.setString(_loyaltyLocalServer, value);
  }

  Future setLoyaltyImageServer(String value) async {
    return _preferences!.setString(_loyaltyImageServer, value);
  }

  Future setLocCode(String value) async {
    return _preferences!.setString(_locCode, value);
  }

  Future setBackgroundImage(String value) async {
    return _preferences!.setString(_backgroundImage, value);
  }

  Future setReportBasedInvoice(bool value) async {
    return _preferences!.setBool(_reportBasedInvoice, value);
  }

  Future setECR(bool value) async {
    return _preferences!.setBool(_ecr, value);
  }

  Future<POSConfig> getConfig(bool getSetup) async {
    var pos = POSConfig();
    try {
      //load from .env
      print('inside reading config');
      await dotenv.load(fileName: "assets/.env");
      print('reading config completed');
      POSConfig().server = dotenv.env['SERVER'] ?? '';
      print('SERVER: ${POSConfig().server}');
      POSConfig().allowLocalMode =
          dotenv.env['ALLOW_LOCAL_MODE'] == 'true' ?? false;
      print('ALLOW_LOCAL_MODE: ${POSConfig().allowLocalMode}');
      POSConfig().allow_sync_bills =
          dotenv.env['ALLOW_AUTO_INVOICE_SYNC'] == 'true' ?? true;
      print('ALLOW_AUTO_BILL_SYNC: ${POSConfig().allow_sync_bills}');
      POSConfig().local = dotenv.env['LOCAL'] ?? '';
      print('LOCAL: ${POSConfig().local}');
      POSConfig().posImageServer = dotenv.env['POS_IMAGE'] ?? '';
      print('POS_IMAGE: ${POSConfig().posImageServer}');
      POSConfig().loyaltyServerOutlet = dotenv.env['LOYALTY'] ?? '';
      print('LOYALTY: ${POSConfig().loyaltyServerOutlet}');
      POSConfig().loyaltyServerImage = dotenv.env['LOYALTY_IMAGE'] ?? '';
      print('LOYALTY_IMAGE: ${POSConfig().loyaltyServerImage}');
      POSConfig().webSocketUrl = dotenv.env['WEB_SOCKET'] ?? '';
      print('WEB_SOCKET: ${POSConfig().webSocketUrl}');
      POSConfig().saas = dotenv.env['SAAS'] == 'true' ?? false;
      print('SAAS: ${POSConfig().saas}');
      // POSConfig().auto_cust_popup =
      //     dotenv.env['AUTO_CUSTOMER_POPUP'] == 'true' ?? false;
      // print('cust_popup: ${POSConfig().auto_cust_popup}');
      POSConfig().password = dotenv.env['PASSWORD'] ?? '';
      print('PASSWORD: ${POSConfig().password}');
      POSConfig().dualScreenWebsite = dotenv.env['DUAL_SCREEN'] ?? '';
      print('DUAL_SCREEN: ${POSConfig().dualScreenWebsite}');
      POSConfig.crystalPath = dotenv.env['CRYSTAL_REPORT_PATH'] ?? '';
      print('DUAL_SCREEN: ${POSConfig().dualScreenWebsite}');
      POSConfig().enablePollDisplay =
          dotenv.env['ENABLE_POLL_DISPLAY'] ?? 'false';
      print('ENABLE_POLL_DISPLAY: ${POSConfig().enablePollDisplay}');
      POSConfig().pollDisplayPort = dotenv.env['POLL_DISPLAY_PORT'] ?? 'COM3';
      print('POLL_DISPLAY_PORT: ${POSConfig().pollDisplayPort}');
      POSConfig().pollDisplayPortBaudRate =
          (dotenv.env['BAUD_RATE'] ?? '9600').toInt()!;
      print('POLL_DISPLAY_PORT: ${POSConfig().pollDisplayPort}');
      if (POSPlatform().isDesktop()) {
        POSConfig().screen_width =
            double.parse(dotenv.env['SCREEN_WIDTH'] ?? '1024');
        print('SCREEN_WIDTH: ${POSConfig().screen_width}');
        POSConfig().screen_height =
            double.parse(dotenv.env['SCREEN_HEIGHT'] ?? '768');
        print('SCREEN_HEIGHT: ${POSConfig().screen_height}');
        POSConfig().default_size =
            dotenv.env['DEFAULT_SIZE'] == 'true' ?? false;
      }
      POSConfig().singleSwipeActive =
          (int.parse(dotenv.env['CARD_SWIPE'] ?? '0') == 1 ? true : false);
      print('SINGLE_SWIPE_ACTIVE: ${POSConfig().singleSwipeActive}');
      POSConfig.localPrintPath =
          dotenv.env['LOCAL_PRINT_TEMPLATES_PATH'] ?? 'C:/checkout/LOCAL_PRINT';
      print('LOCAL_PRINT_TEMPLATES_PATH: ${POSConfig.localPrintPath}');
      POSConfig.printerName = dotenv.env['PRINTER_NAME'] ?? 'POS-80C';
      print('PRINTER_NAME: ${POSConfig.printerName}');
      POSConfig.font_a_length = int.parse(dotenv.env['FONT_A_LENGTH'] ?? '42');
      print('FONT_A_LENGTH: ${POSConfig.font_a_length}');
      POSConfig.font_b_length = int.parse(dotenv.env['FONT_B_LENGTH'] ?? '56');
      print('FONT_B_LENGTH: ${POSConfig.font_b_length}');
      POSConfig().isOrderCounter = dotenv.env['ORDER_COUNTER'] == 'true';

      print('loading config from .env completed');
      await LogWriter().saveLogsToFile('ERROR_LOG_', [
        'loading config from .env completed',
        'SERVER: ${POSConfig().server}',
        'LOCAL: ${POSConfig().local}',
        'POS_IMAGE: ${POSConfig().posImageServer}',
        'LOYALTY: ${POSConfig().loyaltyServerOutlet}',
        'LOYALTY_IMAGE: ${POSConfig().loyaltyServerImage}',
        'WEB_SOCKET: ${POSConfig().webSocketUrl}',
        'SAAS: ${POSConfig().saas}',
        'PASSWORD: ${POSConfig().password}',
        'DUAL_SCREEN: ${POSConfig().dualScreenWebsite}',
        'ENABLE_POLL_DISPLAY: ${POSConfig().enablePollDisplay}',
        'SCREEN_WIDTH: ${POSConfig().screen_width}',
        'SCREEN_HEIGHT: ${POSConfig().screen_height}',
        'SINGLE_SWIPE_ACTIVE: ${POSConfig().singleSwipeActive}',
        'LOCAL_PRINT_TEMPLATES_PATH: ${POSConfig.localPrintPath}',
        'PRINTER_NAME: ${POSConfig.printerName}',
        'FONT_A_LENGTH: ${POSConfig.font_a_length}',
        'FONT_B_LENGTH: ${POSConfig.font_b_length}'
      ]);
      print('after load settings ' + POSConfig().webSocketUrl);
    } catch (e) {
      await LogWriter().saveLogsToFile('ERROR_LOG_', [
        'Exception on ENV Reading : ${e.toString()} \nCheck your env and ensure all the variables are there...'
      ]);
    }
    var jsonData;
    try {
      String data = await rootBundle.loadString('assets/appData.json');
      jsonData = jsonDecode(data);
      POSConfig().currencyCode = jsonData['currency_code'];
    } catch (e) {
      jsonData = null;
      LogWriter().saveLogsToFile('ERROR_LOG_', [
        'initial conversion failed (appData.json read/conversion) : ' +
            e.toString()
      ]);
    }
    try {
      SquareButtonController squareButtonController =
          SquareButtonController(_preferences!);
      CartConfigController cartConfigController =
          CartConfigController(_preferences!);

      POSConfig defaultPOSConfig = POSConfig();

      PaymentConfigController paymentConfigController =
          PaymentConfigController(_preferences!);

      POSKeyboardConfigController posKeyboardConfigController =
          POSKeyboardConfigController(_preferences!);
      pos = POSConfig()
        ..rounderBorderRadiusTopLeft =
            await squareButtonController.getSquareButtonTopLeftRadius() ??
                defaultPOSConfig.rounderBorderRadiusTopLeft
        ..rounderBorderRadiusTopRight =
            await squareButtonController.getSquareButtonTopRightRadius() ??
                defaultPOSConfig.rounderBorderRadiusTopRight
        ..rounderBorderRadiusBottomLeft =
            await squareButtonController.getSquareButtonBottomLeftRadius() ??
                defaultPOSConfig.rounderBorderRadiusBottomLeft
        ..rounderBorderRadiusBottomRight =
            await squareButtonController.getSquareButtonBottomRightRadius() ??
                defaultPOSConfig.rounderBorderRadiusBottomRight
        ..rounderBorderRadius2 =
            _preferences!.getDouble(_roundedBorderRadius) ??
                defaultPOSConfig.rounderBorderRadius2
        ..topAppBarSize = _preferences!.getDouble(_toolbarHeight) ??
            defaultPOSConfig.topAppBarSize
        ..containerSize = _preferences!.getDouble(_containerSize) ??
            defaultPOSConfig.containerSize
        ..primaryColor = _preferences!.getString(_primaryColor) ??
            defaultPOSConfig.primaryColor
        ..backgroundColor = _preferences!.getString(_backgroundColor) ??
            defaultPOSConfig.backgroundColor
        ..primaryDarkGrayColor = _preferences!.getString(_primaryColorGrey) ??
            defaultPOSConfig.primaryDarkGrayColor
        ..primaryLightColor = _preferences!.getString(_primaryColorLight) ??
            defaultPOSConfig.primaryLightColor
        ..primaryDarkColor = _preferences!.getString(_primaryColorDark) ??
            defaultPOSConfig.primaryDarkColor
        ..touchKeyboardEnabled = _preferences!.getBool(_touchKeyBoard) ??
            defaultPOSConfig.touchKeyboardEnabled
        ..disablePromotions = _preferences!.getBool(_promotion) ??
            defaultPOSConfig.disablePromotions
        ..auto_cust_popup = _preferences!.getBool(_customerPopup) ??
            defaultPOSConfig.auto_cust_popup
        ..disableCartImageLoad = _preferences!.getBool(_disableCartImage) ??
            defaultPOSConfig.disableCartImageLoad
        ..saveInvoiceLocal = _preferences?.getBool(_saveInvoiceLocal) ??
            defaultPOSConfig.saveInvoiceLocal
        ..terminalId =
            _preferences!.getString(_terminalId) ?? defaultPOSConfig.terminalId
        ..backgroundImage = _preferences!.getString(_backgroundImage) ??
            defaultPOSConfig.backgroundImage
        ..ecr = _preferences!.getBool(_ecr) ?? defaultPOSConfig.ecr
        // ..server = _preferences!.getString(_posServer) ?? defaultPOSConfig.server
        //
        // ..local =
        //     _preferences!.getString(_posLocalServer) ?? defaultPOSConfig.local
        // ..posImageServer = _preferences!.getString(_posImageServer) ?? defaultPOSConfig.posImageServer
        // ..loyaltyServer = _preferences!.getString(_loyaltyServer) ?? defaultPOSConfig.loyaltyServer
        // ..loyaltyServerLocal = _preferences!.getString(_loyaltyLocalServer) ?? defaultPOSConfig.loyaltyServerLocal
        // ..loyaltyServerImage = _preferences!.getString(_loyaltyImageServer) ?? defaultPOSConfig.loyaltyServerImage
        ..reportBasedInvoice = _preferences!.getBool(_reportBasedInvoice) ??
            defaultPOSConfig.reportBasedInvoice
        ..cardIdLength = cartConfigController.getCardIdLength() ??
            defaultPOSConfig.cardIdLength
        ..cardNameLength = cartConfigController.getCardNameLength() ??
            defaultPOSConfig.cardNameLength
        ..cardPriceLength = cartConfigController.getCardPriceLength() ??
            defaultPOSConfig.cardPriceLength
        ..cardQtyLength = cartConfigController.getCardQtyLength() ??
            defaultPOSConfig.cardQtyLength
        ..cardTotalLength = cartConfigController.getCardTotalLength() ??
            defaultPOSConfig.cardTotalLength
        ..cardFontSize = cartConfigController.getCardFontSizeLength() ??
            defaultPOSConfig.cardFontSize
        ..cartDynamicButtonWidth = cartConfigController.getButtonWidth() ??
            defaultPOSConfig.cartDynamicButtonWidth
        ..cartDynamicButtonHeight = cartConfigController.getButtonHeight() ??
            defaultPOSConfig.cartDynamicButtonHeight
        ..cartDynamicButtonFontSize =
            cartConfigController.getButtonFontSize() ??
                defaultPOSConfig.cartDynamicButtonFontSize
        ..cartDynamicButtonPadding = cartConfigController.getButtonSpace() ??
            defaultPOSConfig.cartDynamicButtonPadding
        ..defaultCheckoutLSH = cartConfigController.getLhsMod() ??
            defaultPOSConfig.defaultCheckoutLSH
        ..checkoutTableView = cartConfigController.getTableView() ??
            defaultPOSConfig.checkoutTableView
        ..cartBatchItem = cartConfigController.getCartBatch() ??
            defaultPOSConfig.cartBatchItem
        ..checkoutDataTableFontSize = cartConfigController.getTableFontSize() ??
            defaultPOSConfig.checkoutDataTableFontSize
        ..paymentDynamicButtonWidth =
            paymentConfigController.getButtonWidth() ??
                defaultPOSConfig.paymentDynamicButtonWidth
        ..paymentDynamicButtonHeight =
            paymentConfigController.getButtonHeight() ??
                defaultPOSConfig.paymentDynamicButtonHeight
        ..paymentDynamicButtonFontSize =
            paymentConfigController.getButtonFontSize() ??
                defaultPOSConfig.paymentDynamicButtonFontSize
        ..paymentDynamicButtonPadding =
            paymentConfigController.getButtonSpace() ??
                defaultPOSConfig.paymentDynamicButtonPadding
        ..posKeyBoardBackgroundColor =
            posKeyboardConfigController.getBackgroundColor() ??
                defaultPOSConfig.posKeyBoardBackgroundColor
        ..posKeyBoardGradient1 =
            posKeyboardConfigController.getGradient1Color() ??
                defaultPOSConfig.posKeyBoardGradient1
        ..posKeyBoardGradient2 =
            posKeyboardConfigController.getGradient2Color() ??
                defaultPOSConfig.posKeyBoardGradient2
        ..posKeyBoardGradient3 =
            posKeyboardConfigController.getGradient3Color() ??
                defaultPOSConfig.posKeyBoardGradient3
        ..posKeyBoardBorderColor =
            posKeyboardConfigController.getBorderColor() ??
                defaultPOSConfig.posKeyBoardBorderColor
        ..posKeyBoardEnterColor =
            posKeyboardConfigController.getEnterKeyColor() ??
                defaultPOSConfig.posKeyBoardEnterColor
        ..posKeyBoardEnterTxtColor =
            posKeyboardConfigController.getEnterKeyTxtColor() ??
                defaultPOSConfig.posKeyBoardEnterTxtColor
        ..posKeyBoardVoidColor =
            posKeyboardConfigController.getVoidKeyColor() ??
                defaultPOSConfig.posKeyBoardVoidColor
        ..posKeyBoardVoidTxtColor =
            posKeyboardConfigController.getVoidKeyTxtColor() ??
                defaultPOSConfig.posKeyBoardVoidTxtColor
        ..posKeyBoardExactColor =
            posKeyboardConfigController.getExactKeyColor() ??
                defaultPOSConfig.posKeyBoardExactColor
        ..posKeyBoardExactTxtColor =
            posKeyboardConfigController.getExactKeyTxtColor() ??
                defaultPOSConfig.posKeyBoardExactTxtColor
        ..showedGiftVoucherTutorials =
            _preferences!.getBool(_gvTutorial) ?? false
        ..locCode = _preferences!.getString(_locCode) ?? '';
      if (getSetup) {
        pos.locCode = _preferences!.getString(_locCode) ?? '';
        final setup = await SetUpController().getSetupData(pos.server);
        LogWriter().saveLogsToFile(
            'API_LOG_', ['setupData: ${setup?.toJson().toString()}']);
        if (setup != null) {
          LogWriter().saveLogsToFile(
              'API_LOG_', ['setupData: ${setup.toJson().toString()}']);
          pos.setup = setup;
          String clientId = setup.clientLicense ?? '';
          notificationBloc.getAnnouncements();
          POSConfig().posImageServer =
              '${POSConfig().posImageServer}$clientId/';
          POSConfig().loyaltyServerImage =
              '${POSConfig().loyaltyServerImage}$clientId/images/Customer/';
          pos.clientLicense = await ActivationController().getClientLicense();
          pos.locCode = (_preferences!.getString(_locCode) ?? '').isEmpty
              ? setup.setuPLOCATION ?? ""
              : _preferences!.getString(_locCode)!;
          pos.comCode = setup.setuPCOMPANY ?? "";
          pos.comName = setup.setuPCOMNAME ?? "";
          pos.setupLocation =
              dotenv.env['SETUP_LOCATION'] ?? setup.setuPLOCATION ?? "";
          pos.setupLocationName = setup.loCDESC ?? "";
          pos.otpEnabled = setup.otpEnabled ?? false;
          String centralLoyaltyServer = setup.loyaltyServerCentral ?? '';
          String loyaltyServerOutlet = dotenv.env['LOYALTY'] ?? '';

          //Only for the debug mode
          if (!kReleaseMode) centralLoyaltyServer = loyaltyServerOutlet;
          //------------------------

          if (centralLoyaltyServer.isEmpty) {
            pos.loyaltyServerCentral = loyaltyServerOutlet;
          } else {
            pos.loyaltyServerCentral = centralLoyaltyServer;
            pos.hasCentralLoyaltyServer =
                centralLoyaltyServer != loyaltyServerOutlet;
          }
          pos.loyaltyServerOutlet = loyaltyServerOutlet;
        }
      }
    } catch (_) {
      _preferences?.clear();
      if (i < 5) {
        i++;
        await SharedPreferenceController().getConfigLocal();
        await getConfig(getSetup);
      }
    }

    return pos;
  }

  Future<void> saveConfigLocal() async {
    try {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      List<String> sharedPreferencesKeys = sharedPreferences.getKeys().toList();
      Map<String, dynamic> data = Map();
      for (var key in sharedPreferencesKeys) {
        if (key == 'temp_cart' ||
            key == 'temp_cart' ||
            key == 'cart_summary' ||
            key == 'temp_payments' ||
            key == 'payment_reference' ||
            key == 'invoice_no' ||
            key == 'withdrawal') {
          continue;
        }
        data[key] = sharedPreferences.get(key);
      }
      await ApiClient.call('backup/save_config', ApiMethod.POST,
          local: true,
          formData: FormData.fromMap({'data': jsonEncode(data)}),
          authorize: false);
    } catch (e) {
      await LogWriter().saveLogsToFile('ERROR_LOG_', [e.toString()]);
    }
  }

  Future<void> getConfigLocal() async {
    try {
      final res = await ApiClient.call('backup/get_config', ApiMethod.POST,
          local: true, authorize: false);
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();

      if (res?.statusCode == 200 &&
          res?.data != null &&
          res?.data['success'].toString() == 'true') {
        Map<String, dynamic> data = jsonDecode(res!.data['config']);
        data.keys.forEach((e) {
          dynamic value = data[e];
          switch (value.runtimeType.toString()) {
            case 'double':
              sharedPreferences.setDouble(e, value);
              break;
            case 'bool':
              sharedPreferences.setBool(e, value);
              break;
            case 'int':
              sharedPreferences.setInt(e, value);
              break;
            case 'String':
              sharedPreferences.setString(e, value);
          }
        });
      } else {
        await LogWriter().saveLogsToFile('ERROR_LOG_', [
          res.toString(),
          res?.data.toString() ?? '',
          res?.statusCode.toString() ?? ''
        ]);
      }
    } catch (e) {
      await LogWriter().saveLogsToFile('ERROR_LOG_', [e.toString()]);
    }
  }
}
