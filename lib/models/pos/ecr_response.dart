/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/25/22, 12:53 PM
 */

class EcrResponse {
  bool? success;
  EcrCard? ecrCard;

  EcrResponse({this.success, this.ecrCard});

  EcrResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    ecrCard = json['ecr_card'] != null
        ? new EcrCard.fromJson(json['ecr_card'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.ecrCard != null) {
      data['ecr_card'] = this.ecrCard!.toJson();
    }
    return data;
  }
}

class EcrCard {
  bool? success;
  String? strTxnInvoiceNum;
  String? strTxnReference;
  String? strTxnApproved;
  String? strTxnCardtype;
  String? strTxnCardBin;
  String? strTxnCardLastDigits;
  String? strTxnCardHolderName;
  String? strTxnTerminal;
  String? strTxnMerchent;
  String? strTxnResponseCode;
  String? strBinRef;
  String? strIssuedBank;
  String? strErrorCode;
  String? strErrorDesc;
  String? strAcknowledgement;

  EcrCard(
      {this.success,
      this.strTxnInvoiceNum,
      this.strTxnReference,
      this.strTxnApproved,
      this.strTxnCardtype,
      this.strTxnCardBin,
      this.strTxnCardLastDigits,
      this.strTxnCardHolderName,
      this.strTxnTerminal,
      this.strTxnMerchent,
      this.strTxnResponseCode,
      this.strBinRef,
      this.strIssuedBank,
      this.strErrorCode,
      this.strErrorDesc,
      this.strAcknowledgement});

  EcrCard.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    strTxnInvoiceNum = json['strTxnInvoiceNum'];
    strTxnReference = json['strTxnReference'];
    strTxnApproved = json['strTxnApproved'];
    strTxnCardtype = json['strTxnCardtype'];
    strTxnCardBin = json['strTxnCardBin'];
    strTxnCardLastDigits = json['strTxnCardLastDigits'];
    strTxnCardHolderName = json['strTxnCardHolderName'];
    strTxnTerminal = json['strTxnTerminal'];
    strTxnMerchent = json['strTxnMerchent'];
    strTxnResponseCode = json['strTxnResponseCode'];
    strBinRef = json['strBinRef'];
    strIssuedBank = json['strIssuedBank'];
    strErrorCode = json['strErrorCode'];
    strErrorDesc = json['strErrorDesc'];
    strAcknowledgement = json['strAcknowledgement'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['strTxnInvoiceNum'] = this.strTxnInvoiceNum;
    data['strTxnReference'] = this.strTxnReference;
    data['strTxnApproved'] = this.strTxnApproved;
    data['strTxnCardtype'] = this.strTxnCardtype;
    data['strTxnCardBin'] = this.strTxnCardBin;
    data['strTxnCardLastDigits'] = this.strTxnCardLastDigits;
    data['strTxnCardHolderName'] = this.strTxnCardHolderName;
    data['strTxnTerminal'] = this.strTxnTerminal;
    data['strTxnMerchent'] = this.strTxnMerchent;
    data['strTxnResponseCode'] = this.strTxnResponseCode;
    data['strBinRef'] = this.strBinRef;
    data['strIssuedBank'] = this.strIssuedBank;
    data['strErrorCode'] = this.strErrorCode;
    data['strErrorDesc'] = this.strErrorDesc;
    data['strAcknowledgement'] = this.strAcknowledgement;
    return data;
  }
}

class EcrErrorResponse {
  bool? success;
  String? message;
  String? error;

  EcrErrorResponse({this.success, this.message, this.error});

  EcrErrorResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    error = json['error'];
  }
}
