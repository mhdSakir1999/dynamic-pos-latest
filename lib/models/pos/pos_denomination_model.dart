/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/6/21, 5:57 PM
 */

class POSDenominationModel {
  String code;
  String detailCode;
  double totalValue;
  String description;
  late List<POSDenominationDetail> denominations;
  POSDenominationModel(
      this.code, this.detailCode, this.description, this.totalValue);

  Map<String, dynamic> toMap() {
    return {
      'code': this.code,
      'detail_code': this.detailCode,
      'total_value': this.totalValue,
      'description': this.description,
    };
  }
}

class POSDenominationDetail {
  String? mainCode;
  String? denominationCode;
  int? count;
  double? value;

  POSDenominationDetail(
      this.mainCode, this.denominationCode, this.count, this.value);

  Map<String, dynamic> toMap() {
    return {
      'main_code': this.mainCode,
      'denomination_code': this.denominationCode,
      'd_count': this.count,
      'd_value': this.value,
    };
  }

  POSDenominationDetail.fromMap(Map json) {
    // return new POSDenominationDetail(mainCode = 'CSH',
    //     denominationCode = json[''], count = json[''], value = json['']);
    this.mainCode = 'CSH';
    this.denominationCode = json['DE_DENCODE'] ?? 'N/A';
    this.count = int.tryParse(json['DE_DENCODE'] ?? '0');
    this.value = (json['DE_DENPHYAMT'] ?? 0) / (count == 0 ? 1 : count);
  }
}
