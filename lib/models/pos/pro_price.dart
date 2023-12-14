import 'package:checkout/models/pos/pro_tax.dart';


import 'product_price_changes.dart';
import 'package:checkout/extension/extensions.dart';
class ProPriceResults {
  bool? success;
  List<ProductPriceChanges>? price;
  List<ProPrice> proPrice=[];
  List<ProTax> proTax=[];
  String? message;

  ProPriceResults({this.success, this.price,required this.proPrice, this.message});

  ProPriceResults.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['price'] != null) {
      price = <ProductPriceChanges>[];
      json['price'].forEach((v) {
        price!.add(new ProductPriceChanges.fromJson(v));
      });
    }
    if (json['pro_price'] != null) {
      proPrice = <ProPrice>[];
      json['pro_price'].forEach((v) {
        proPrice.add(new ProPrice.fromJson(v));
      });
    }
    if (json['pro_tax'] != null) {
      proTax = <ProTax>[];
      json['pro_tax'].forEach((v) {
        proTax.add(new ProTax.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.price != null) {
      data['price'] = this.price!.map((v) => v.toJson()).toList();
    }
    data['pro_price'] = this.proPrice.map((v) => v.toJson()).toList();
    data['message'] = this.message;
    return data;
  }
}


class ProPrice {
  double? pplUQTYS;
  double? pplUQTYE;
  double? pplUDISCPER;
  double? pplUDISCAMT;
  double? pplUFIXPRICE;
  bool? prMFIXED;
  String? prMCODE;
  String? prMDESC;
  bool? allowDiscount;
  bool? allowLoyalty;
  ProPrice(
      {this.pplUQTYS,
        this.pplUQTYE,
        this.pplUDISCPER,
        this.pplUDISCAMT,
        this.pplUFIXPRICE,
        this.prMFIXED,
        this.prMCODE,
        this.prMDESC,this.allowLoyalty,this.allowDiscount});

  ProPrice.fromJson(Map<String, dynamic> json) {
    pplUQTYS = json['pplU_QTY_S']?.toString().parseDouble()??0;
    pplUQTYE = json['pplU_QTY_E']?.toString().parseDouble()??0;
    pplUDISCPER = json['pplU_DISCPER']?.toString().parseDouble()??0;
    pplUDISCAMT = json['pplU_DISCAMT']?.toString().parseDouble()??0;
    pplUFIXPRICE = json['pplU_FIXPRICE']?.toString().parseDouble()??0;
    prMFIXED = json['prM_FIXED']?.toString().parseBool()??false;
    prMCODE = json['prM_CODE'];
    prMDESC = json['prM_DESC'];
    allowDiscount = json['prM_ALLOW_DISCOUNT'];
    allowLoyalty = json['prM_ALLOW_LOYALTYPOINTS'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pplU_QTY_S'] = this.pplUQTYS;
    data['pplU_QTY_E'] = this.pplUQTYE;
    data['pplU_DISCPER'] = this.pplUDISCPER;
    data['pplU_DISCAMT'] = this.pplUDISCAMT;
    data['pplU_FIXPRICE'] = this.pplUFIXPRICE;
    data['prM_FIXED'] = this.prMFIXED;
    data['prM_CODE'] = this.prMCODE;
    data['prM_DESC'] = this.prMDESC;
    return data;
  }
}
