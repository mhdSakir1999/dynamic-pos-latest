/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/15/21, 8:57 AM
 */

import 'package:checkout/models/pos/pro_price.dart';
import 'package:checkout/models/pos/pro_tax.dart';
import 'package:checkout/models/pos/product_price_changes.dart';
import 'package:checkout/models/pos_config.dart';

import 'package:checkout/extension/extensions.dart';

/// This product result will be return by products?code=00000009&location=001 end point
class ProductResult {
  bool? success;
  List<Product>? product;
  // Product? product;
  List<ProductPriceChanges>? prices;
  List<ProPrice>? proPrices;
  List<ProTax>? proTax;
  List<Product>? emptyBottles;
  String? status;

  ProductResult({this.success, this.product, this.status, this.emptyBottles});

  ProductResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    // product =
    //     json['product'] != null ? new Product.fromJson(json['product']) : null;
    final List<dynamic> products = json['product'] ?? [];
    product = products.take(20).map((e) => Product.fromJson(e)).toList();
    status = json['status'];
    if (json['prices'] != null) {
      prices = <ProductPriceChanges>[];
      json['prices'].forEach((v) {
        prices!.add(new ProductPriceChanges.fromJson(v));
      });
    }
    if (json['pro_price'] != null) {
      proPrices = <ProPrice>[];
      json['pro_price'].forEach((v) {
        proPrices!.add(new ProPrice.fromJson(v));
      });
    }
    if (json['pro_tax'] != null) {
      proTax = <ProTax>[];
      json['pro_tax'].forEach((v) {
        proTax!.add(new ProTax.fromJson(v));
      });
    }
    if (json['return_pros'] != null && json['return_pros'] != []) {
      emptyBottles = List.generate(json['return_pros'].length,
              (index) => Product.fromJson(json['return_pros'][index])) ??
          [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.product != null) {
      // data['product'] = this.product?.toJson();
      data['product'] = this.product?.map((e) => e.toJson());
    }
    data['status'] = this.status;
    return data;
  }
}

class Product {
  String? sCANCODE;
  String? pLUCODE;
  String? pLUPOSDESC;
  String? pLUSTOCKCODE;
  String? pluUnit;
  bool? pLUACTIVE;
  bool? pLUNODISC;
  bool? pluOpen;
  bool? pluDecimal;
  bool? allowMinus;
  bool? exchangable;
  double? sELLINGPRICE;
  double? sIH;
  int? caseSize;
  double? cost;
  double? avgCost;
  double? maxDiscAmt;
  double? maxDiscPer;
  String? department;
  String? subDepartment;
  String? image;
  String? maxVolumeGroup;
  String? maxVolumeGroupLvl;
  double? volume;
  double? maxVolume;
  bool? posActive;
  String? vendorPLU;
  String? returnBottleCode;
  bool? varientEnable;
  bool? batchEnable;
  bool? isEmptyBottle;

  Product(
      {this.sCANCODE,
      this.pLUCODE,
      this.pLUPOSDESC,
      this.pLUSTOCKCODE,
      this.pLUACTIVE,
      this.pLUNODISC,
      this.sELLINGPRICE,
      this.caseSize,
      this.pluDecimal,
      this.sIH,
      this.returnBottleCode,
      this.varientEnable,
      this.isEmptyBottle = false});

  Product.fromJson(Map<String, dynamic> json) {
    String tempImage = json['imagE_PATH']?.toString() ?? "";
    if (tempImage.isEmpty) {
      tempImage = "images/product/default.png";
    } else {
      tempImage = 'images/product/$tempImage';
    }
    tempImage = POSConfig().posImageServer + tempImage;
    sCANCODE = json['scaN_CODE'];
    pLUCODE = json['plU_CODE'];
    image = tempImage;
    pLUPOSDESC = json['plU_POSDESC'];
    pLUSTOCKCODE = json['plU_STOCKCODE'];
    department = json['plU_DEPARTMENT'];
    subDepartment = json['plU_SUB_DEPARTMENT'];
    pluUnit = json['plU_UNIT'];
    pLUACTIVE = json['plU_ACTIVE']?.toString().parseBool() ?? false;
    pLUNODISC = json['plU_NODISC']?.toString().parseBool() ?? false;
    pluOpen = json['plU_OPEN']?.toString().parseBool() ?? false;
    pluDecimal = json['plU_DECIMAL']?.toString().parseBool() ?? false;
    allowMinus = json['plU_MINUSALLOW']?.toString().parseBool() ?? false;
    exchangable = json['plU_EXCHANGABLE']?.toString().parseBool() ?? false;
    sELLINGPRICE = json['sellinG_PRICE']?.toString().parseDouble() ?? 0;
    sIH = json['sih']?.toString().parseDouble() ?? 0;
    caseSize = json['casE_SIZE']?.toString().parseDouble().toInt() ?? 0;
    cost = json['plU_COST']?.toString().parseDouble() ?? 0;
    avgCost = json['plU_AVGCOST']?.toString().parseDouble() ?? 0;
    maxDiscAmt = json['plU_MAXDISCAMT']?.toString().parseDouble() ?? 0;
    maxDiscPer = json['plU_MAXDISCPER']?.toString().parseDouble() ?? 0;
    volume = json['plU_VOLUME']?.toString().parseDouble() ?? 0;
    maxVolume = json['plU_MAXVOLUME']?.toString().parseDouble() ?? 0;
    maxVolumeGroupLvl = json['plU_MAXVOLUME_GRPLV']?.toString();
    maxVolumeGroup = json['plU_MAXVOLUME_GRP']?.toString();
    posActive = json['plU_POSACTIVE']?.toString().parseBool() ?? false;
    vendorPLU = json['plU_VENDORPLU'] ?? '';
    returnBottleCode = json['plU_RETURN'];
    varientEnable = json['plU_VARIANTANABLE'];
    batchEnable = json['plU_BATCHENABLE'];
    isEmptyBottle = json['plU_EMPTY'] == 1 ? true : false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['SCAN_CODE'] = this.sCANCODE;
    data['PLU_CODE'] = this.pLUCODE;
    data['PLU_POSDESC'] = this.pLUPOSDESC;
    data['PLU_STOCKCODE'] = this.pLUSTOCKCODE;
    data['PLU_ACTIVE'] = this.pLUACTIVE;
    data['PLU_NODISC'] = this.pLUNODISC;
    data['SELLING_PRICE'] = this.sELLINGPRICE?.toString().parseDouble() ?? 0;
    data['SIH'] = this.sIH?.toString().parseDouble() ?? 0;
    return data;
  }
}
