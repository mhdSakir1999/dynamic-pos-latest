/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/7/21, 6:34 PM
 */
import 'package:checkout/extension/extensions.dart';

class SetUpResult {
  bool? success;
  Setup? setup;
  String? message;

  SetUpResult({this.success, this.setup, this.message});

  SetUpResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    setup = json['setup'] != null ? new Setup.fromJson(json['setup']) : null;
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.setup != null) {
      data['setup'] = this.setup?.toJson();
    }
    data['message'] = this.message;
    return data;
  }
}

class Setup {
  String? setuPLOCATION;
  String? setuPCOMNAME;
  String? setuPCOMPANY;
  String? loyaltyServerCentral;
  String? loCDESC;
  String? scrolL_MESSAGE;
  String? thanK_YOU_MESSAGE;
  String? backendUrl;
  String? myAlertPort;
  String? myAlertUrl;
  bool? otpEnabled;
  String? setuPSCALESYMBOL;
  int? setuPSCALEDIGIT;
  String? loyaltyProvider;
  String? loyaltyProviderUrl;
  String? loyaltyProviderUser;
  String? loyaltyProviderPassword;
  String? utilityBillUrl;
  DateTime? setupEndDate;
  String? clientLicense;
  String? centralPOSServer;
  int qtyDecimalPoints = 2;
  int amountDecimalPoints = 3;
  int? eodValidationDuration;
  bool? validatePosIp;
  double? maxQtyLimit;
  double? billReprintCount;
  double? fixedFloat;
  bool? validatePOSGroups;
  bool? addPromoDiscAsItem;
  String? passwordPolicy;
  String? passwordPolicyDesc;
  bool? autoRoundOff;
  double? autoRoundoffTo;
  late DateTime serverTime;
  double? maxCashLimit;
  int? itemReturnDayLimit;

  Setup({
    this.setuPLOCATION,
    this.setuPCOMNAME,
    this.setuPCOMPANY,
    this.loCDESC,
    this.otpEnabled,
    this.setuPSCALESYMBOL,
    this.setuPSCALEDIGIT,
    this.itemReturnDayLimit,
  });

  Setup.fromJson(Map<String, dynamic> json) {
    setuPLOCATION = json['setuP_LOCATION'];
    setuPCOMNAME = json['setuP_COMNAME'];
    setuPCOMPANY = json['setuP_COMPANY'];
    loyaltyServerCentral = json['setuP_LOYALATYSERVERCENTRAL'];
    loCDESC = json['loC_DESC'];
    scrolL_MESSAGE = json['scrolL_MESSAGE'];
    thanK_YOU_MESSAGE = json['thanK_YOU_MESSAGE'];
    backendUrl = json['setuP_BACKENDURL'];
    myAlertPort = json['setuP_MYALERTPORT'];
    myAlertUrl = json['setuP_MYALERTURL'];
    loyaltyProvider = json['setuP_EXTLOYALTY_PROVIDER'];
    loyaltyProviderUrl = json['setuP_EXTLOYALTY_URL'];
    loyaltyProviderPassword = json['setuP_EXTLOYALTY_PASSWORD'];
    loyaltyProviderUser = json['setuP_EXTLOYALTY_USER'];
    utilityBillUrl = json['setuP_UTILITYBILLURL'];
    otpEnabled = json['otP_ENABLED']?.toString().parseBool() ?? false;
    setupEndDate =
        json['setuP_ENDDATE']?.toString().parseDateTime() ?? DateTime.now();
    clientLicense = json['setuP_CLIENTSECRET']?.toString();
    centralPOSServer = json['setuP_CENTRALPOSSERVER']?.toString();
    // centralPOSServer = kReleaseMode
    //     ? json['setuP_CENTRALPOSSERVER']?.toString()
    //     : POSConfig().local.replaceAll('71/api/', '71');
    validatePosIp = json['seuP_VALIDATEPOSIP']?.toString().parseBool() ?? false;
    qtyDecimalPoints =
        json['setuP_DECIMALPLACE_QTY']?.toString().parseDouble().toInt() ?? 3;
    amountDecimalPoints =
        json['setuP_DECIMALPLACE_AMOUNT']?.toString().parseDouble().toInt() ??
            2;
    eodValidationDuration =
        json['setuP_EODVALIDATIONTIME']?.toString().parseDouble().toInt() ?? -1;
    setuPSCALESYMBOL = json['setuP_SCALE_SYMBOL'];
    setuPSCALEDIGIT =
        json['setuP_SCALE_DIGIT']?.toString().parseDouble().toInt();
    serverTime = json['timE_SERVER'].toString().parseDateTime();
    maxQtyLimit = json['setuP_MAX_QTY_LIMIT']?.toString().parseDouble() ?? 0;
    billReprintCount =
        json['setuP_INVREPRINT_COUNT']?.toString().parseDouble() ?? 0;
    fixedFloat = json['setuP_FIXED_FLOAT']?.toString().parseDouble() ?? 0;
    validatePOSGroups =
        json['setuP_VALIDATE_POS_GROUP']?.toString().parseBool() ?? false;
    addPromoDiscAsItem =
        json['setuP_ADD_PROMODISC_AS_ITEM']?.toString().parseBool() ?? false;
    passwordPolicy = json['setuP_USER_PASSWORD_POLICY'];
    passwordPolicyDesc = json['setuP_USER_PASSWORD_POLICYDESC'];
    autoRoundOff = json['setuP_AUTO_ROUNDOFF']?.toString().parseBool() ?? false;
    autoRoundoffTo =
        json['setuP_AUTO_ROUNDOFF_TO']?.toString().parseDouble() ?? 0;

    // i am using try-catch because qc team using old api which doesnt sending json['setuP_MAX_CASH_LIMIT']
    try {
      maxCashLimit =
          json['setuP_MAX_CASH_LIMIT']?.toString().parseDouble() ?? 0;
    } catch (e) {
      maxCashLimit = 0;
    }
    itemReturnDayLimit = json?['setuP_RETURN_DAYS'] ?? 0;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['setuP_LOCATION'] = this.setuPLOCATION;
    data['setuP_COMNAME'] = this.setuPCOMNAME;
    data['setuP_COMPANY'] = this.setuPCOMPANY;
    data['loC_DESC'] = this.loCDESC;
    data['setuP_SCALE_SYMBOL'] = this.setuPSCALESYMBOL;
    data['setuP_SCALE_DIGIT'] = this.setuPSCALEDIGIT;
    return data;
  }
}
