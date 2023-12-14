class PromotionSkuResult {
  List<PromotionSku>? promotionSku;
  bool? success;

  PromotionSkuResult({this.promotionSku, this.success});

  PromotionSkuResult.fromJson(Map<String, dynamic> json) {
    if (json['promotion_sku'] != null) {
      promotionSku = <PromotionSku>[];
      json['promotion_sku'].forEach((v) {
        promotionSku!.add(new PromotionSku.fromJson(v));
      });
    }
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.promotionSku != null) {
      data['promotion_sku'] =
          this.promotionSku!.map((v) => v.toJson()).toList();
    }
    data['success'] = this.success;
    return data;
  }
}

class PromotionSku {
  String? pskUCODE;
  String? pskUDESC;
  String? pskUPLUCODE;

  PromotionSku({this.pskUCODE, this.pskUDESC, this.pskUPLUCODE});

  PromotionSku.fromJson(Map<String, dynamic> json) {
    pskUCODE = json['pskU_CODE'];
    pskUDESC = json['pskU_DESC'];
    pskUPLUCODE = json['pskU_PLUCODE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pskU_CODE'] = this.pskUCODE;
    data['pskU_DESC'] = this.pskUDESC;
    data['pskU_PLUCODE'] = this.pskUPLUCODE;
    return data;
  }
}
