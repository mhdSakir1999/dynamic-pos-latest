import 'package:checkout/extension/extensions.dart';

class PromotionDetailsResult {
  List<PromotionDetailsList>? promotionDetails;
  List<PromotionIncludeExcludeSku>? includeItems;
  List<PromotionIncludeExcludeSku>? excludeItems;
  List<PromotionOfferSKU>? offerItems;
  bool? success;

  PromotionDetailsResult({this.promotionDetails, this.success});

  PromotionDetailsResult.fromJson(Map<String, dynamic> json) {
    if (json['promotion_details'] != null) {
      promotionDetails = <PromotionDetailsList>[];
      json['promotion_details'].forEach((v) {
        promotionDetails!.add(new PromotionDetailsList.fromJson(v));
      });
    }
    //includes
    if (json['promotion_includes'] != null) {
      includeItems = <PromotionIncludeExcludeSku>[];
      json['promotion_includes'].forEach((v) {
        includeItems!.add(new PromotionIncludeExcludeSku.fromJson(v));
      });
    }
    if (json['promotion_excludes'] != null) {
      excludeItems = <PromotionIncludeExcludeSku>[];
      json['promotion_excludes'].forEach((v) {
        excludeItems!.add(new PromotionIncludeExcludeSku.fromJson(v));
      });
    }
    if (json['promotion_offers'] != null) {
      offerItems = <PromotionOfferSKU>[];
      json['promotion_offers'].forEach((v) {
        offerItems!.add(new PromotionOfferSKU.fromJson(v));
      });
    }
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.promotionDetails != null) {
      data['promotion_details'] =
          this.promotionDetails!.map((v) => v.toJson()).toList();
    }
    data['success'] = this.success;
    return data;
  }
}

class PromotionDetailsList {
  String? prOCODE;
  String? pskUPLUCODE;
  String? prODESC;
  double? proDMINQTY;
  double? proDMAXQTY;
  double? proDMINVAL;
  double? proDMAXVAL;
  double? proDDISCPER;
  double? proDDISCAMT;
  String? proDTICKETID;
  double? proDTICKQTY;
  double? proDVOUVALUE;
  double? proDVOUQTY;
  String? proDFREEITEM;
  double? proDFREEQTY;
  double? proDVALIDQTY;
  String? proGROUPBUNDLEGROUPS;
  String? pskUCODE;
  double? ptiCKVALUE;
  double? ptiCKBILLVALUE;
  DateTime? ptiCKREDEFROM;
  DateTime? ptiCKREDETO;
  double? ptiCKREDEEMBILLVALFROM;
  double? ptiCKREDEEMBILLVALTO;

  PromotionDetailsList(
      {this.prOCODE,
      this.pskUPLUCODE,
      this.prODESC,
      this.proDMINQTY,
      this.proDMAXQTY,
      this.proDMINVAL,
      this.proDMAXVAL,
      this.proDDISCPER,
      this.proDDISCAMT,
      this.proDTICKETID,
      this.proDTICKQTY,
      this.proDVOUVALUE,
      this.proDVOUQTY,
      this.proDFREEITEM,
      this.proDFREEQTY,
      this.proDVALIDQTY,
      this.proGROUPBUNDLEGROUPS,
      this.pskUCODE,
      this.ptiCKVALUE,
      this.ptiCKBILLVALUE,
      this.ptiCKREDEFROM,
      this.ptiCKREDETO,
      this.ptiCKREDEEMBILLVALFROM,
      this.ptiCKREDEEMBILLVALTO});

  PromotionDetailsList.fromJson(Map<String, dynamic> json) {
    prOCODE = json['prO_CODE'];
    pskUPLUCODE = json['pskU_PLUCODE'];
    prODESC = json['prO_DESC'];
    pskUCODE = json['pskU_CODE'];
    proDMINQTY = json['proD_MINQTY']?.toString().parseDouble();
    proDMAXQTY = json['proD_MAXQTY']?.toString().parseDouble();
    proDMINVAL = json['proD_MINVAL']?.toString().parseDouble();
    proDMAXVAL = json['proD_MAXVAL']?.toString().parseDouble();
    proDDISCPER = json['proD_DISCPER']?.toString().parseDouble();
    proDDISCAMT = json['proD_DISCAMT']?.toString().parseDouble();
    proDTICKETID = json['proD_TICKETID'];
    proDTICKQTY = json['proD_TICKQTY']?.toString().parseDouble();
    proDVOUVALUE = json['proD_VOUVALUE']?.toString().parseDouble();
    proDVOUQTY = json['proD_VOUQTY']?.toString().parseDouble();
    proDFREEITEM = json['proD_FREEITEM'];
    proGROUPBUNDLEGROUPS = json['proE_GROUPBUNDLEGROUPS'];
    proDFREEQTY = json['proD_FREEQTY']?.toString().parseDouble();
    proDVALIDQTY = json['proD_VALIDQTY']?.toString().parseDouble();
    ptiCKVALUE = json['pticK_VALUE']?.toString().parseDouble();
    ptiCKBILLVALUE = json['pticK_BILL_VALUE']?.toString().parseDouble();
    ptiCKREDEFROM = json['pticK_REDE_FROM'].toString().parseDateTime();
    ptiCKREDETO = json['pticK_REDE_TO'].toString().parseDateTime();
    ptiCKREDEEMBILLVALFROM =
        json['pticK_REDEEM_BILL_VALFROM']?.toString().parseDouble();
    ptiCKREDEEMBILLVALTO =
        json['pticK_REDEEM_BILL_VALTO']?.toString().parseDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['prO_CODE'] = this.prOCODE;
    data['pskU_PLUCODE'] = this.pskUPLUCODE;
    data['prO_DESC'] = this.prODESC;
    data['proD_MINQTY'] = this.proDMINQTY;
    data['proD_MAXQTY'] = this.proDMAXQTY;
    data['proD_MINVAL'] = this.proDMINVAL;
    data['proD_MAXVAL'] = this.proDMAXVAL;
    data['proD_DISCPER'] = this.proDDISCPER;
    data['proD_DISCAMT'] = this.proDDISCAMT;
    data['proD_TICKETID'] = this.proDTICKETID;
    data['proD_TICKQTY'] = this.proDTICKQTY;
    data['proD_VOUVALUE'] = this.proDVOUVALUE;
    data['proD_VOUQTY'] = this.proDVOUQTY;
    data['proD_FREEITEM'] = this.proDFREEITEM;
    data['proD_FREEQTY'] = this.proDFREEQTY;
    data['proD_VALIDQTY'] = this.proDVALIDQTY;
    return data;
  }
}

class PromotionIncludeExcludeSku {
  late String pluCode;
  late String bundleCode;
  PromotionIncludeExcludeSku.fromJson(Map<String, dynamic> json) {
    pluCode = json['pskU_PLUCODE'];
    bundleCode = json['pskU_CODE'];
  }
}

class PromotionOfferSKU {
  late String pluCode;
  late String bundleCode;
  PromotionOfferSKU.fromJson(Map<String, dynamic> json) {
    pluCode = json['pskU_PLUCODE'];
    bundleCode = json['pskU_CODE'];
  }
}
