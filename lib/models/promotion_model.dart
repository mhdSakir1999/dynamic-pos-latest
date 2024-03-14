import 'package:checkout/controllers/promotion_controller.dart';
import 'package:checkout/extension/extensions.dart';

class PromotionListResult {
  List<Promotion>? promotions;
  bool? success;

  PromotionListResult({this.promotions, this.success});

  PromotionListResult.fromJson(Map<String, dynamic> json) {
    if (json['promotions'] != null) {
      promotions = <Promotion>[];
      json['promotions'].forEach((v) {
        promotions!.add(new Promotion.fromJson(v));
      });
    }
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.promotions != null) {
      data['promotions'] = this.promotions!.map((v) => v.toJson()).toList();
    }
    data['success'] = this.success;
    return data;
  }
}

class Promotion {
  String? prOCODE;
  String? prODESC;
  String? prONARRATION;
  late bool prOPRINT;
  String? prOGROUP;
  late bool prOSTATUS;
  late DateTime prOSTDATE;
  late DateTime prOENDATE;
  late DateTime prOSTTIME;
  late DateTime prOENTIME;
  String? prODAYS;
  double? prOSTBILLNET;
  double? prOENBILLNET;
  String? prOCOMPANYS;
  late bool prOBDAY;
  int? prOBDFROM;
  int? prOBDTO;
  late bool prOANNIVERSARY;
  double? prOMINPOINTBAL;
  double? prOCUSLIMIT;
  late bool prOINCLUSIVEITEMS;
  int? prOPRIORITY;
  late bool prOLOYALCUSTOMERS;
  String? pGCODE;
  String? pGDESC;
  late bool pGSTATUS;
  late bool pGOUTLET;
  late bool pGPAYACT;
  late bool pGEXCLACT;
  late bool pGINCLACT;
  late bool pGPSKUBIDACT;
  late bool pGGRPBIDACT;
  late bool pGDISCPERACT;
  late bool pGDISCAMTACT;
  late bool pGFSKUBIDACT;
  late bool pGTICKETACT;
  late bool pGVOUACT;
  late bool pGPOINTACT;
  late bool pGCUSSPECIFIC;
  late bool pGCARD;
  late bool pGINCLACTQTY;
  late bool pGINCLACTVALUE;
  late bool pGINCLACTITEM;
  late bool pGINCLACTCOMBINATION;
  late bool pGEXCLACTQTY;
  late bool pGEXCLACTVALUE;
  late bool pGEXCLACTITEM;
  late bool pGEXCLACTCOMBINATION;
  String? proECUSGROUPS;
  String? proESUPGROUPS;
  String? proEITEMBUNDLEGROUPS;
  String? proEGROUPBUNDLEGROUPS;
  String? proICUSGROUPS;
  String? proISUPGROUPS;
  String? proIITEMBUNDLEGROUPS;
  String? proIGROUPBUNDLEGROUPS;
  late bool proSELECTABLE;
  late PromotionStat status;
  late bool pGEXCLUDEINCLUSIVE;
  late bool pGVALIDQTYCHECKSKU;
  late bool pGDISCAMTAPPLYTOBILL;
  late bool pGTICKETVALUE;
  late bool pGCOUPONREDEMPTION;
  late int proCOUPONTYPE;
  Promotion({
    this.prOCODE,
    this.prODESC,
    this.prONARRATION,
    this.prOGROUP,
    this.prODAYS,
    this.prOSTBILLNET,
    this.prOENBILLNET,
    this.prOCOMPANYS,
    this.prOBDFROM,
    this.prOBDTO,
    this.prOPRIORITY,
    this.pGCODE,
    this.pGDESC,
  });

  Promotion.fromJson(Map<String, dynamic> json) {
    prOCODE = json['prO_CODE'];
    prODESC = json['prO_DESC'];
    prONARRATION = json['prO_NARRATION'];
    prOPRINT = intToBool(json['prO_PRINT']);
    prOGROUP = json['prO_GROUP'];
    prOSTATUS = intToBool(json['prO_STATUS']);
    prOSTDATE = json['prO_STDATE'].toString().parseDateTime();
    prOENDATE = json['prO_ENDATE'].toString().parseDateTime();
    prOSTTIME = json['prO_STTIME'].toString().parseDateTime();
    prOENTIME = json['prO_ENTIME'].toString().parseDateTime();
    prODAYS = json['prO_DAYS']?.toString();
    prOSTBILLNET = json['prO_ST_BILLNET']?.toString().parseDouble();
    prOENBILLNET = json['prO_EN_BILLNET']?.toString().parseDouble();
    prOCOMPANYS = json['prO_COMPANYS'];
    prOBDAY = intToBool(json['prO_BDAY']);
    prOBDFROM = json['prO_BDFROM'];
    prOBDTO = json['prO_BDTO'];
    prOANNIVERSARY = intToBool(json['prO_ANNIVERSARY']);
    prOMINPOINTBAL = json['prO_MINPOINTBAL'].toString().parseDouble();
    prOCUSLIMIT = json['prO_CUSLIMIT']?.toString().parseDouble();
    prOINCLUSIVEITEMS = intToBool(json['prO_INCLUSIVEITEMS']);
    prOPRIORITY = json['prO_PRIORITY'];
    prOLOYALCUSTOMERS = intToBool(json['prO_LOYALCUSTOMERS']);
    pGCODE = json['pG_CODE'];
    pGDESC = json['pG_DESC'];
    pGSTATUS = intToBool(json['pG_STATUS']);
    pGOUTLET = intToBool(json['pG_OUTLET']);
    pGPAYACT = intToBool(json['pG_PAY_ACT']);
    pGEXCLACT = intToBool(json['pG_EXCL_ACT']);
    pGINCLACT = intToBool(json['pG_INCL_ACT']);
    pGPSKUBIDACT = intToBool(json['pG_PSKUBID_ACT']);
    pGGRPBIDACT = intToBool(json['pG_GRPBID_ACT']);
    pGDISCPERACT = intToBool(json['pG_DISCPER_ACT']);
    pGDISCAMTACT = intToBool(json['pG_DISCAMT_ACT']);
    pGFSKUBIDACT = intToBool(json['pG_FSKUBID_ACT']);

    pGINCLACTQTY = intToBool(json['pG_INCL_ACT_QTY']);
    pGINCLACTVALUE = intToBool(json['pG_INCL_ACT_VALUE']);
    pGINCLACTITEM = intToBool(json['pG_INCL_ACT_ITEM']);
    pGINCLACTCOMBINATION = intToBool(json['pG_INCL_ACT_COMBINATION']);
    pGEXCLACTQTY = intToBool(json['pG_EXCL_ACT_QTY']);
    pGEXCLACTVALUE = intToBool(json['pG_EXCL_ACT_VALUE']);
    pGEXCLACTITEM = intToBool(json['pG_EXCL_ACT_ITEM']);
    pGEXCLACTCOMBINATION = intToBool(json['pG_EXCL_ACT_COMBINATION']);
    proSELECTABLE = intToBool(json['PRO_SELECTABLE']);
    pGTICKETACT = intToBool(json['pG_TICKET_ACT']);
    pGVOUACT = intToBool(json['pG_VOU_ACT']);
    pGPOINTACT = intToBool(json['pG_POINT_ACT']);
    pGCUSSPECIFIC = intToBool(json['pG_CUS_SPECIFIC']);
    pGCARD = intToBool(json['pG_CARD']);
    proECUSGROUPS = json['proE_CUSGROUPS'];
    proESUPGROUPS = json['proE_SUPGROUPS'];
    proEITEMBUNDLEGROUPS = json['proE_ITEMBUNDLEGROUPS'];
    proEGROUPBUNDLEGROUPS = json['proE_GROUPBUNDLEGROUPS'];
    proICUSGROUPS = json['proI_CUSGROUPS'];
    proISUPGROUPS = json['proI_SUPGROUPS'];
    proIITEMBUNDLEGROUPS = json['proI_ITEMBUNDLEGROUPS'];
    proIGROUPBUNDLEGROUPS = json['proI_GROUPBUNDLEGROUPS'];
    pGEXCLUDEINCLUSIVE = intToBool(json['pG_EXCLUDE_INCLUSIVE']);
    pGVALIDQTYCHECKSKU = intToBool(json['pG_VALIDQTY_CHECK_SKU']);
    pGDISCAMTAPPLYTOBILL = intToBool(json['pG_DISCAMT_APPLY_TO_BILL']);
    pGTICKETVALUE = intToBool(json['pG_TICKET_VALUE']);
    pGCOUPONREDEMPTION = intToBool(json['pG_COUPON_REDEMPTION']);
    proCOUPONTYPE = (json['prO_COUPON_TYPE']);
  }

  bool intToBool(dynamic value) {
    return value.toString().parseBool();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['prO_CODE'] = this.prOCODE;
    data['prO_DESC'] = this.prODESC;
    data['prO_NARRATION'] = this.prONARRATION;
    data['prO_PRINT'] = this.prOPRINT;
    data['prO_GROUP'] = this.prOGROUP;
    data['prO_STATUS'] = this.prOSTATUS;
    data['prO_STDATE'] = this.prOSTDATE;
    data['prO_ENDATE'] = this.prOENDATE;
    data['prO_STTIME'] = this.prOSTTIME;
    data['prO_ENTIME'] = this.prOENTIME;
    data['prO_DAYS'] = this.prODAYS;
    data['prO_ST_BILLNET'] = this.prOSTBILLNET;
    data['prO_EN_BILLNET'] = this.prOENBILLNET;
    data['prO_COMPANYS'] = this.prOCOMPANYS;
    data['prO_BDAY'] = this.prOBDAY;
    data['prO_BDFROM'] = this.prOBDFROM;
    data['prO_BDTO'] = this.prOBDTO;
    data['prO_ANNIVERSARY'] = this.prOANNIVERSARY;
    data['prO_MINPOINTBAL'] = this.prOMINPOINTBAL;
    data['prO_CUSLIMIT'] = this.prOCUSLIMIT;
    data['prO_INCLUSIVEITEMS'] = this.prOINCLUSIVEITEMS;
    data['prO_PRIORITY'] = this.prOPRIORITY;
    data['prO_LOYALCUSTOMERS'] = this.prOLOYALCUSTOMERS;
    data['pG_CODE'] = this.pGCODE;
    data['pG_DESC'] = this.pGDESC;
    data['pG_STATUS'] = this.pGSTATUS;
    data['pG_OUTLET'] = this.pGOUTLET;
    data['pG_PAY_ACT'] = this.pGPAYACT;
    data['pG_EXCL_ACT'] = this.pGEXCLACT;
    data['pG_INCL_ACT'] = this.pGINCLACT;
    data['pG_PSKUBID_ACT'] = this.pGPSKUBIDACT;
    data['pG_GRPBID_ACT'] = this.pGGRPBIDACT;
    data['pG_DISCPER_ACT'] = this.pGDISCPERACT;
    data['pG_DISCAMT_ACT'] = this.pGDISCAMTACT;
    data['pG_FSKUBID_ACT'] = this.pGFSKUBIDACT;
    data['pG_TICKET_ACT'] = this.pGTICKETACT;
    data['pG_VOU_ACT'] = this.pGVOUACT;
    data['pG_POINT_ACT'] = this.pGPOINTACT;
    data['pG_CUS_SPECIFIC'] = this.pGCUSSPECIFIC;
    data['pG_CARD'] = this.pGCARD;
    return data;
  }
}
