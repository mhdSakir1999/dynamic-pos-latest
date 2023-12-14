
class TransferCFCInfoResponse {
  TransferCFCInfoResult? transferCFCInfoResult;

  TransferCFCInfoResponse({this.transferCFCInfoResult});

  TransferCFCInfoResponse.fromJson(Map<String, dynamic> json) {
    print("*********************************************************");
    print(json);
    print("*********************************************************");
    transferCFCInfoResult = json['TransferCFCInfoResult'] != null
        ? new TransferCFCInfoResult.fromJson(json['TransferCFCInfoResult'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.transferCFCInfoResult != null) {
      data['TransferCFCInfoResult'] = this.transferCFCInfoResult!.toJson();
    }
    return data;
  }
}

class TransferCFCInfoResult {
  String? primaryAccountOrCardNo;
  String? processingCode;
  String? transactionDate;
  String? forwardInstIDcode;
  String? merchantCode;
  String? retrievalRefNo;
  String? originatorofResponseCode;
  String? originatorofResponseDescrp;
  String? responseCode;
  String? responseDescrp;
  String? bankTransactionReference;
  String? toAccount;
  String? additionalPara5;

  TransferCFCInfoResult(
      {this.primaryAccountOrCardNo,
        this.processingCode,
        this.transactionDate,
        this.forwardInstIDcode,
        this.merchantCode,
        this.retrievalRefNo,
        this.originatorofResponseCode,
        this.originatorofResponseDescrp,
        this.responseCode,
        this.responseDescrp,
        this.bankTransactionReference,
        this.toAccount,
        this.additionalPara5});

  TransferCFCInfoResult.fromJson(Map<String, dynamic> json) {

    primaryAccountOrCardNo = json['PrimaryAccountOrCardNo'].toString();
    processingCode = json['ProcessingCode'].toString();
    transactionDate = json['TransactionDate'].toString();
    forwardInstIDcode = json['ForwardInstIDcode'].toString();
    merchantCode = json['MerchantCode'].toString();
    retrievalRefNo = json['RetrievalRefNo'].toString();
    originatorofResponseCode = json['OriginatorofResponseCode'].toString();
    originatorofResponseDescrp = json['OriginatorofResponseDescrp'].toString();
    responseCode = json['ResponseCode'].toString();
    responseDescrp = json['ResponseDescrp'].toString();
    bankTransactionReference = json['BankTransactionReference'].toString();
    toAccount = json['ToAccount'].toString();
    additionalPara5 = json['AdditionalPara5'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['PrimaryAccountOrCardNo'] = this.primaryAccountOrCardNo;
    data['ProcessingCode'] = this.processingCode;
    data['TransactionDate'] = this.transactionDate;
    data['ForwardInstIDcode'] = this.forwardInstIDcode;
    data['MerchantCode'] = this.merchantCode;
    data['RetrievalRefNo'] = this.retrievalRefNo;
    data['OriginatorofResponseCode'] = this.originatorofResponseCode;
    data['OriginatorofResponseDescrp'] = this.originatorofResponseDescrp;
    data['ResponseCode'] = this.responseCode;
    data['ResponseDescrp'] = this.responseDescrp;
    data['BankTransactionReference'] = this.bankTransactionReference;
    data['ToAccount'] = this.toAccount;
    data['AdditionalPara5'] = this.additionalPara5;
    return data;
  }
}
