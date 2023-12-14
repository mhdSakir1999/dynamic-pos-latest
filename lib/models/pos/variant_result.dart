import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/pos_config.dart';

class LocationWiseVariantStockResult {
  bool? success;
  List<ProVariant>? stocks;
  String? message;

  LocationWiseVariantStockResult({this.success, this.stocks, this.message});

  LocationWiseVariantStockResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    if (json['stocks'] != null) {
      stocks = <ProVariant>[];
      json['stocks'].forEach((v) {
        stocks!.add(new ProVariant.fromJson(v));
      });
    }
    message = json['message'];
  }
}

class ProVariant {
  late String ipLUCODE;
  late String ipLUPRODUCTCODE;
  late String ipLUDESC;
  String? v1;
  String? v2;
  late String loCDESC;
  double? ipLUSIH;
  String? plUPICTURE;

  ProVariant(
      {required this.ipLUCODE,
      required this.ipLUPRODUCTCODE,
      required this.ipLUDESC,
      this.v1,
      this.v2,
      required this.loCDESC,
      this.ipLUSIH,
      this.plUPICTURE});

  ProVariant.fromJson(Map<String, dynamic> json) {
    ipLUCODE = json['iplU_CODE'];
    ipLUPRODUCTCODE = json['iplU_PRODUCTCODE'];
    ipLUDESC = json['iplU_DESC'];
    v1 = json['v1']?.toString() ?? '';
    v2 = json['v2']?.toString() ?? '';
    loCDESC = json['loC_DESC'];
    ipLUSIH = json['iplU_SIH']?.toString().parseDouble();
    String tempImage = json['plU_PICTURE']?.toString() ?? "";
    if (tempImage.isEmpty) {
      tempImage = "images/product/default.png";
    } else {
      tempImage = 'images/product/$tempImage';
    }
    tempImage = POSConfig().posImageServer + tempImage;
    plUPICTURE = tempImage;
  }
}
