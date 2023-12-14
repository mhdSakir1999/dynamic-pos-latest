/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/18/22, 4:50 PM
 */
class PromotionFreeItems {
  final List<PromotionFreeItemDetails> freeItemBundle;
  double remainingQty;
  final double totalQty;
  final String originalItemCode;
  final String bundleCode;
  final String promotionCode;
  final String promotionDesc;
  PromotionFreeItems(
      this.freeItemBundle,
      this.remainingQty,
      this.totalQty,
      this.originalItemCode,
      this.promotionCode,
      this.promotionDesc,
      this.bundleCode);
}

class PromotionFreeItemDetails {
  final String proCode;
  final String proDesc;
  double scannedQty = 0;

  PromotionFreeItemDetails({required this.proCode, required this.proDesc});

  factory PromotionFreeItemDetails.fromMap(Map<String, dynamic> map) {
    return new PromotionFreeItemDetails(
      proCode: map['pluCode']?.toString() ?? "",
      proDesc: map['pluDesc']?.toString() ?? "",
    );
  }
}

class PromotionFreeGVs {
  double remainingQty;
  final double totalQty;
  final String originalItemCode;
  final String promotionCode;
  final String promotionDesc;
  final double gvValue;
  final String gvName;
  double scannedQty = 0;
  List<String> gvCodes = [];
  PromotionFreeGVs(
      this.gvValue,
      this.remainingQty,
      this.totalQty,
      this.originalItemCode,
      this.promotionCode,
      this.promotionDesc,
      this.gvName);
}

class PromotionFreeTickets {
  final String ticketId;
  final String promotionCode;
  final String promotionDesc;
  final double ticketQty;

  PromotionFreeTickets(
      this.ticketId, this.promotionCode, this.promotionDesc, this.ticketQty);

  Map<String, dynamic> toMap() {
    return {
      'ticketId': this.ticketId,
      'promotionCode': this.promotionCode,
      'promotionDesc': this.promotionDesc,
      'ticketQty': this.ticketQty,
    };
  }
}
