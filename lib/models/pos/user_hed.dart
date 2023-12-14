/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/4/21, 1:03 PM
 */
import 'package:checkout/extension/extensions.dart';

class UserHed {
  String? uSERHEDUSERCODE;
  String? uSERHEDTITLE;
  String? uSERHEDPICTURE;
  bool? uSERHEDISSIGNEDON;
  bool? uSERHEDISSIGNEDOFF;
  bool? uSERHEDISMANAGERSIGNEDOFF;
  bool? uSERHEDISTEMPSIGNON;
  bool? uSERHEDACTIVEUSER;
  String? uSERHEDSTATIONID;
  String? uSERDETMENUTAG;
  String? sETUPENDDATE;
  String? uSERHEDSIGNONDATE;
  String? uSERHEDSIGNOFFDATE;
  String? uSERHEDSIGNONTIME;
  String? mobile;
  String? shiftNo;

  UserHed(
      {this.uSERHEDUSERCODE,
      this.uSERHEDTITLE,
      this.uSERHEDPICTURE,
      this.uSERHEDISSIGNEDON,
      this.uSERHEDISSIGNEDOFF,
      this.uSERHEDISMANAGERSIGNEDOFF,
      this.uSERHEDISTEMPSIGNON,
      this.uSERHEDACTIVEUSER,
      this.uSERHEDSTATIONID,
      this.uSERDETMENUTAG,
      this.sETUPENDDATE,
      this.uSERHEDSIGNONDATE,
      this.uSERHEDSIGNONTIME,
      this.uSERHEDSIGNOFFDATE});

  UserHed.fromJson(Map<String, dynamic> json) {
    uSERHEDUSERCODE = json['userheD_USERCODE'];
    uSERHEDTITLE = json['userheD_TITLE'];
    uSERHEDPICTURE = json['userheD_PICTURE'];
    uSERHEDISSIGNEDON =
        json['userheD_ISSIGNEDON']?.toString().parseBool() ?? false;
    uSERHEDISSIGNEDOFF =
        json['userheD_ISSIGNEDOFF']?.toString().parseBool() ?? false;
    uSERHEDISMANAGERSIGNEDOFF =
        json['userheD_ISMANAGERSIGNEDOFF']?.toString().parseBool() ?? false;
    uSERHEDISTEMPSIGNON =
        json['userheD_ISTEMPSIGNON']?.toString().parseBool() ?? false;
    uSERHEDACTIVEUSER =
        json['userheD_ACTIVEUSER']?.toString().parseBool() ?? false;
    uSERHEDSTATIONID = json['userheD_STATIONID'];
    uSERDETMENUTAG = json['userdeT_MENUTAG'];
    sETUPENDDATE = json['setuP_ENDDATE'];
    uSERHEDSIGNONDATE =
        json['userheD_SIGNONDATE'].toString().replaceAll("T", " ");
    uSERHEDSIGNOFFDATE =
        json['userheD_SIGNOFFDATE'].toString().replaceAll("T00:00:00", " ");
    uSERHEDSIGNONTIME = json['userheD_SIGNONTIME'];
    mobile = json['uH_MOBILE'].toString();
    shiftNo = json['userheD_SHIFTNO'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['USERHED_USERCODE'] = this.uSERHEDUSERCODE;
    data['USERHED_TITLE'] = this.uSERHEDTITLE;
    data['USERHED_PICTURE'] = this.uSERHEDPICTURE;
    data['USERHED_ISSIGNEDON'] = this.uSERHEDISSIGNEDON;
    data['USERHED_ISSIGNEDOFF'] = this.uSERHEDISSIGNEDOFF;
    data['USERHED_ISMANAGERSIGNEDOFF'] = this.uSERHEDISMANAGERSIGNEDOFF;
    data['USERHED_ISTEMPSIGNON'] = this.uSERHEDISTEMPSIGNON;
    data['USERHED_ACTIVEUSER'] = this.uSERHEDACTIVEUSER;
    data['USERHED_STATIONID'] = this.uSERHEDSTATIONID;
    data['USERDET_MENUTAG'] = this.uSERDETMENUTAG;
    data['SETUP_ENDDATE'] = this.sETUPENDDATE;
    return data;
  }
}
