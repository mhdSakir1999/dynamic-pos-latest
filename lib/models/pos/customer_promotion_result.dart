class CustomerPromotionResult {
  bool? success;
  List<CustomerPromotion>? promotions;

  CustomerPromotionResult({this.success, this.promotions});

  CustomerPromotionResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['promotions'] != null) {
      promotions = <CustomerPromotion>[];
      json['promotions'].forEach((v) {
        promotions!.add(new CustomerPromotion.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.promotions != null) {
      data['promotions'] = this.promotions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CustomerPromotion {
  int? prCID;
  String? prCCMCODE;
  String? prCPROMOCODE;
  String? prCDATETIME;
  String? prCINVNO;
  String? prCLOCCODE;
  String? prCSTATION;
  String? prCCASHIER;

  CustomerPromotion(
      {this.prCID,
        this.prCCMCODE,
        this.prCPROMOCODE,
        this.prCDATETIME,
        this.prCINVNO,
        this.prCLOCCODE,
        this.prCSTATION,
        this.prCCASHIER});

  CustomerPromotion.fromJson(Map<String, dynamic> json) {
    prCID = json['prC_ID'];
    prCCMCODE = json['prC_CMCODE'];
    prCPROMOCODE = json['prC_PROMOCODE'];
    prCDATETIME = json['prC_DATETIME'];
    prCINVNO = json['prC_INVNO'];
    prCLOCCODE = json['prC_LOCCODE'];
    prCSTATION = json['prC_STATION'];
    prCCASHIER = json['prC_CASHIER'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['prC_ID'] = this.prCID;
    data['prC_CMCODE'] = this.prCCMCODE;
    data['prC_PROMOCODE'] = this.prCPROMOCODE;
    data['prC_DATETIME'] = this.prCDATETIME;
    data['prC_INVNO'] = this.prCINVNO;
    data['prC_LOCCODE'] = this.prCLOCCODE;
    data['prC_STATION'] = this.prCSTATION;
    data['prC_CASHIER'] = this.prCCASHIER;
    return data;
  }
}
