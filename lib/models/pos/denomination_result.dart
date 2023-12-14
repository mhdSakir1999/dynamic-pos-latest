import 'package:checkout/extension/extensions.dart';

class DenominationResult {
  bool? success;
  List<DenominationHed>? denominationHed;
  String? message;

  DenominationResult({this.success, this.denominationHed, this.message});

  DenominationResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool();
    if (json['denomination_hed'] != null) {
      denominationHed = [];
      json['denomination_hed'].forEach((v) {
        denominationHed?.add(new DenominationHed.fromJson(v));
      });
    }
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.denominationHed != null) {
      data['denomination_hed'] =
          this.denominationHed?.map((v) => v.toJson()).toList();
    }
    data['message'] = this.message;
    return data;
  }
}

class DenominationHed {
  String? code;
  String? detailCode;
  String? description;
  List<Denominations>? denominations;

  DenominationHed(
      {this.code, this.detailCode, this.description, this.denominations});

  DenominationHed.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    detailCode = json['detail_code'];
    description = json['description'];
    if (json['denominations'] != null) {
      denominations = [];
      json['denominations'].forEach((v) {
        denominations?.add(new Denominations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    data['detail_code'] = this.detailCode;
    data['description'] = this.description;
    if (this.denominations != null) {
      data['denominations'] =
          this.denominations?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Denominations {
  String? deNCODE;
  String? deNDENOCODE;
  double? deNDENVALUE;

  Denominations({this.deNCODE, this.deNDENOCODE, this.deNDENVALUE});

  Denominations.fromJson(Map<String, dynamic> json) {
    deNCODE = json['deN_CODE'];
    deNDENOCODE = json['deN_DENOCODE'];
    deNDENVALUE = json['deN_DENVALUE']?.toString().parseDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['deN_CODE'] = this.deNCODE;
    data['deN_DENOCODE'] = this.deNDENOCODE;
    data['deN_DENVALUE'] = this.deNDENVALUE;
    return data;
  }
}
