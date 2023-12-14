/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/2/22, 5:18 PM
 */
import 'dart:convert';

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class UtilityUIResult {
  bool? success;
  List<UtilityUi>? utilityUi;
  String? message;

  UtilityUIResult({this.success, this.utilityUi, this.message});

  UtilityUIResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['utility_ui'] != null) {
      utilityUi = <UtilityUi>[];
      json['utility_ui'].forEach((v) {
        utilityUi!.add(new UtilityUi.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.utilityUi != null) {
      data['utility_ui'] = this.utilityUi!.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class UtilityUi {
  List<UtilityComponents>? components;
  int? ubSID;
  String? ubSTYPE;
  String? ubSDESC;
  String? ubSBUTTON1;
  String? ubSBUTTON2;
  bool? ubSSHOWSECTION;
  int? ubSORDER;

  UtilityUi(
      {this.components,
      this.ubSID,
      this.ubSTYPE,
      this.ubSDESC,
      this.ubSBUTTON1,
      this.ubSBUTTON2,
      this.ubSSHOWSECTION,
      this.ubSORDER});

  UtilityUi.fromJson(Map<String, dynamic> json) {
    if (json['components'] != null) {
      components = <UtilityComponents>[];
      json['components'].forEach((v) {
        components!.add(new UtilityComponents.fromJson(v));
      });
    }
    ubSID = json['ubS_ID'];
    ubSTYPE = json['ubS_TYPE'];
    ubSDESC = json['ubS_DESC'];
    ubSBUTTON1 = json['ubS_BUTTON1'];
    ubSBUTTON2 = json['ubS_BUTTON2'];
    ubSSHOWSECTION = json['ubS_SHOWSECTION'];
    ubSORDER = json['ubS_ORDER'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.components != null) {
      data['components'] = this.components!.map((v) => v.toJson()).toList();
    }
    data['ubS_ID'] = this.ubSID;
    data['ubS_TYPE'] = this.ubSTYPE;
    data['ubS_DESC'] = this.ubSDESC;
    data['ubS_BUTTON1'] = this.ubSBUTTON1;
    data['ubS_BUTTON2'] = this.ubSBUTTON2;
    data['ubS_SHOWSECTION'] = this.ubSSHOWSECTION;
    data['ubS_ORDER'] = this.ubSORDER;
    return data;
  }
}

class UtilityComponents {
  List<UtilityWidget>? widget;

  UtilityComponents({this.widget});

  UtilityComponents.fromJson(Map<String, dynamic> json) {
    if (json['widget'] != null) {
      widget = <UtilityWidget>[];
      json['widget'].forEach((v) {
        widget!.add(new UtilityWidget.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.widget != null) {
      data['widget'] = this.widget!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UtilityWidget {
  String? ubUTYPE;
  String? ubUSECTION;
  String? ubUNAME;
  bool? ubUGROUP;
  String? ubUMASK;
  String? ubUREGEX;
  String? ubUINPUTTYPE;
  String? ubUCOLUMNNAME;
  String? ubUORDERBY;
  String? ubUDATAFROM;
  String? ubUHINT;
  bool? ubUEXCLUDEREQUEST;
  TextEditingController textEditingController = TextEditingController();
  FocusNode focusNode = FocusNode();
  List<UtilityData> utilityData = [];
  UtilityData? selectedData;
  String? originalText;

  UtilityWidget(
      {this.ubUTYPE,
      this.ubUSECTION,
      this.ubUNAME,
      this.ubUGROUP,
      this.ubUMASK,
      this.ubUREGEX,
      this.ubUINPUTTYPE,
      this.ubUCOLUMNNAME,
      this.ubUORDERBY,
      this.ubUDATAFROM,
      this.ubUHINT,
      this.ubUEXCLUDEREQUEST});

  UtilityWidget.fromJson(Map<String, dynamic> json) {
    ubUTYPE = json['ubU_TYPE'];
    ubUSECTION = json['ubU_SECTION'];
    ubUNAME = json['ubU_NAME'];
    ubUGROUP = json['ubU_GROUP'];
    ubUMASK = json['ubU_MASK'];
    ubUREGEX = json['ubU_REGEX'];
    ubUINPUTTYPE = json['ubU_INPUTTYPE'];
    ubUCOLUMNNAME = json['ubU_COLUMNNAME'];
    ubUORDERBY = json['ubU_ORDERBY'].toString();
    ubUDATAFROM = json['ubU_DATAFROM'];
    ubUHINT = json['ubU_HINT'];
    ubUEXCLUDEREQUEST = json['ubU_EXCLUDE_REQUEST'];
    //ComCode
    // InvNo
    // locCode
    // Cashier
    // Date
    // Default
    // TerminalNo
    // Default
    // Default
    // AuditNo
    if (ubUINPUTTYPE == 'HIDDEN') {
      switch (ubUDATAFROM) {
        case "ComCode":
        case "comCode":
          textEditingController.text = POSConfig().comCode;
          break;
        case "InvNo":
          textEditingController.text = Uuid().v4();
          break;
        case "locCode":
        case "LocCode":
          textEditingController.text = POSConfig().locCode;
          break;
        case "Cashier":
          textEditingController.text =
              userBloc.currentUser?.uSERHEDUSERCODE ?? '';
          break;
        case "TerminalNo":
          textEditingController.text = POSConfig().terminalId;
          break;
        case "AuditNo":
          textEditingController.text = Uuid().v4();
          break;
        case "Date":
          DateFormat format = DateFormat(ubUHINT ?? 'yyyy-MM-dd');
          textEditingController.text = format.format(DateTime.now());
          break;
        default:
          textEditingController.text = ubUHINT ?? '';
      }
    }
    String dataFrom = ubUDATAFROM ?? '';

    if (dataFrom.contains("jsonData")) {
      List<dynamic> data = jsonDecode(dataFrom)["jsonData"] ?? [];
      if (data.isNotEmpty) {
        utilityData = data.map((e) => UtilityData.fromMap(e)).toList();
        selectedData = utilityData.first;
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ubU_TYPE'] = this.ubUTYPE;
    data['ubU_SECTION'] = this.ubUSECTION;
    data['ubU_NAME'] = this.ubUNAME;
    data['ubU_GROUP'] = this.ubUGROUP;
    data['ubU_MASK'] = this.ubUMASK;
    data['ubU_REGEX'] = this.ubUREGEX;
    data['ubU_INPUTTYPE'] = this.ubUINPUTTYPE;
    data['ubU_COLUMNNAME'] = this.ubUCOLUMNNAME;
    data['ubU_ORDERBY'] = this.ubUORDERBY;
    data['ubU_DATAFROM'] = this.ubUDATAFROM;
    data['ubU_HINT'] = this.ubUHINT;
    data['ubU_EXCLUDE_REQUEST'] = this.ubUEXCLUDEREQUEST;

    return data;
  }
}

class UtilityData {
  String? id;
  String? name;
  String? pdCode;
  String? phCode;
  String? phDesc;
  String? pdDesc;

  UtilityData.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    pdCode = map['pdCode'];
    phCode = map['phCode'];
    phDesc = map['phDesc'];
    pdDesc = map['pdDesc'];
  }
}
