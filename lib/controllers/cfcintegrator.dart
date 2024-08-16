import 'dart:convert';

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/api_client.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/utility_bill/utility_bill_api_res.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';

class CfcIntegrator {
  CfcIntegrator();

  Future<String?> makeRequest(String type, String invNo, String desc,
      Map<String, dynamic> formData) async {
    EasyLoading.show(status: "Processing...");
    var headers = {'Content-Type': 'application/json'};
    DateFormat format = DateFormat("yyyy-MM-dd HH:mm:ss");

    Map<String, dynamic> map = {
      "TransferCFCInfo": {"CFCRequest": formData}
    };
    await LogWriter().saveLogsToFile('UTILITY_LOG_', ['CFC Request data: '+ jsonEncode(formData)]);
    print('#########################EDI################################');
    print(map);
    print('############################################################');
    EasyLoading.dismiss();
    var request = http.Request(
        'POST', Uri.parse((POSConfig().setup?.utilityBillUrl ?? '').trim()));

    request.body = json.encode(map);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();
    var body = await response.stream.bytesToString();

    print(body);
    print('############################################################');
    print(response.statusCode);
    print('############################################################');

    EasyLoading.dismiss();

    /// new change by [TM.Sakir] on 2023-10-10 14:01 PM
    /// The response from cfc integrator is in xml format
    if (response.statusCode == 200) {
      TransferCFCInfoResponse? transferInfo;
      try {
        transferInfo = TransferCFCInfoResponse.fromJson(
            jsonDecode(body)["TransferCFCInfoResponse"]);
      } catch (e) {
//         final xml2json = Xml2Json();
//         xml2json.parse(body);
//         print(body);
//         final jsonString = xml2json.toParker();
//         var parsedJson = jsonDecode(jsonString);

//         Map<String, dynamic> desiredJson = {
//           "TransferCFCInfoResponse": {
//             "TransferCFCInfoResult": {
//               "MessageTypeId": parsedJson["NS1:Envelope"]["NS1:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:MessageTypeId"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:MessageTypeId"],
//               "PrimaryAccountOrCardNo": parsedJson["NS1:Envelope"]["NS1:Body"]
//                               ["ns1:TransferCFCInfoResponse"]
//                           ["ns1:TransferCFCInfoResult"]
//                       ["ns1:PrimaryAccountOrCardNo"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                               ["ns1:TransferCFCInfoResponse"]
//                           ["ns1:TransferCFCInfoResult"]
//                       ["ns1:PrimaryAccountOrCardNo"],
//               "ProcessingCode": parsedJson["NS1:Envelope"]["NS1:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:ProcessingCode"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:ProcessingCode"],
//               "TransactionAmount": parsedJson["NS1:Envelope"]["NS1:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:TransactionAmount"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:TransactionAmount"],
//               "TraceAuditNo": parsedJson["NS1:Envelope"]["NS1:Body"]
//                       ["ns1:TransferCFCInfoResponse"]
//                   ["ns1:TransferCFCInfoResult"]["ns1:TraceAuditNo"],
//               "ForwardInstIDcode": parsedJson["NS1:Envelope"]["NS1:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:ForwardInstIDcode"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:ForwardInstIDcode"],
//               "MerchantCode": parsedJson["NS1:Envelope"]["NS1:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:MerchantCode"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:MerchantCode"],
//               "RetrievalRefNo": parsedJson["NS1:Envelope"]["NS1:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:RetrievalRefNo"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:RetrievalRefNo"],
//               "OriginatorofResponseCode": parsedJson["NS1:Envelope"]["NS1:Body"]
//                               ["ns1:TransferCFCInfoResponse"]
//                           ["ns1:TransferCFCInfoResult"]
//                       ["ns1:OriginatorofResponseCode"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                               ["ns1:TransferCFCInfoResponse"]
//                           ["ns1:TransferCFCInfoResult"]
//                       ["ns1:OriginatorofResponseCode"],
//               "OriginatorofResponseDescrp": parsedJson["NS1:Envelope"]
//                               ["NS1:Body"]["ns1:TransferCFCInfoResponse"]
//                           ["ns1:TransferCFCInfoResult"]
//                       ["ns1:OriginatorofResponseDescrp"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                               ["ns1:TransferCFCInfoResponse"]
//                           ["ns1:TransferCFCInfoResult"]
//                       ["ns1:OriginatorofResponseDescrp"],
//               "ResponseCode": parsedJson["NS1:Envelope"]["NS1:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:ResponseCode"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:ResponseCode"],
//               "ResponseDescrp": parsedJson["NS1:Envelope"]["NS1:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:ResponseDescrp"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:ResponseDescrp"],
//               "BankTransactionReference": parsedJson["NS1:Envelope"]["NS1:Body"]
//                               ["ns1:TransferCFCInfoResponse"]
//                           ["ns1:TransferCFCInfoResult"]
//                       ["ns1:BankTransactionReference"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                               ["ns1:TransferCFCInfoResponse"]
//                           ["ns1:TransferCFCInfoResult"]
//                       ["ns1:BankTransactionReference"],
//               "CardAcceptorTermID": parsedJson["NS1:Envelope"]["NS1:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:CardAcceptorTermID"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:CardAcceptorTermID"],
//               "CardAcceptorIDCode": parsedJson["NS1:Envelope"]["NS1:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:CardAcceptorIDCode"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                           ["ns1:TransferCFCInfoResponse"]
//                       ["ns1:TransferCFCInfoResult"]["ns1:CardAcceptorIDCode"],
//               "CardAcceptorNameLocation": parsedJson["NS1:Envelope"]["NS1:Body"]
//                               ["ns1:TransferCFCInfoResponse"]
//                           ["ns1:TransferCFCInfoResult"]
//                       ["ns1:CardAcceptorNameLocation"] ??
//                   parsedJson["soapenv:Envelope"]["soapenv:Body"]
//                               ["ns1:TransferCFCInfoResponse"]
//                           ["ns1:TransferCFCInfoResult"]
//                       ["ns1:CardAcceptorNameLocation"],
//               // "ToAccount": parsedJson["NS1:Envelope"]["NS1:Body"]
//               //             ["ns1:TransferCFCInfoResponse"]
//               //         ["ns1:TransferCFCInfoResult"]["ns1:ToAccount"] ??
//               //     parsedJson["soapenv:Envelope"]["soapenv:Body"]
//               //             ["ns1:TransferCFCInfoResponse"]
//               //         ["ns1:TransferCFCInfoResult"]["ns1:ToAccount"] ??
//               //     ''
//             }
//           }
//         };

//         // The desired JSON object
//         final finalJson = jsonEncode(desiredJson);

// // Convert the data to a JSON-like structure (Dart Map)
//         transferInfo = TransferCFCInfoResponse.fromJson(
//             jsonDecode(finalJson)["TransferCFCInfoResponse"]);
      }
      final cfcRes = transferInfo?.transferCFCInfoResult;
      if (cfcRes != null) {
        String refNo = cfcRes.bankTransactionReference ?? '';
        String toAccount = cfcRes.toAccount ?? '';
        String retrievalRefNo = cfcRes.retrievalRefNo ?? '';
        String primaryAccountNo = cfcRes.primaryAccountOrCardNo ?? '';
        String processingCode = cfcRes.processingCode ?? '';
        String forwardInstIdCode = cfcRes.forwardInstIDcode ?? '';
        String merchantId = cfcRes.merchantCode ?? '';
        String responseDesc = cfcRes.responseDescrp ?? '';
        String responseCode = cfcRes.responseCode ?? '-1';
        String locationCode = POSConfig().setupLocation;
        String comCode = POSConfig().comCode;
        String terminalCode = POSConfig().terminalId;
        String cashier = userBloc.currentUser?.uSERHEDUSERCODE ?? '';
        String date = format.format(DateTime.now());
        String transactionFee = "0";
        String settlementFee = "0";
        String paymentMode = formData['AccountorCash']?.toString() ?? '';
        double transactionAmount =
            (formData['TransactionAmount']?.toString() ?? '0.00').parseDouble();
        await ApiClient.call('UtilityBillSetup', ApiMethod.POST, data: {
          "location": locationCode,
          "comCode": comCode,
          "stationId": terminalCode,
          "cashier": cashier,
          "date": date,
          "type": type,
          "response": body,
          "request": request.body,
          "refNo": refNo,
          "toAccount": toAccount,
          "retrievalRefNo": retrievalRefNo,
          "primaryAccountNo": primaryAccountNo,
          "processingCode": processingCode,
          "forwardInstIdCode": forwardInstIdCode,
          "merchantId": merchantId,
          "responseDesc": responseDesc,
          "responseCode": responseCode,
          "transactionFee": transactionFee.parseDouble(),
          "settlementFee": settlementFee.parseDouble(),
          "paymentMode": paymentMode,
          "invNo": invNo,
          "transactionAmount": transactionAmount,
          "desc": desc
        });

        if (responseCode == "00") {
          EasyLoading.showSuccess(responseDesc);
          return null;
        }

        return responseDesc;
      }
    } else {
      return response.reasonPhrase;
    }
    return "Invalid response";
  }
// Future<String?> makeRequest(String type, Map<String, dynamic> formData) async {
//   EasyLoading.show(status: "Processing...");
//   // var headers = {
//   //   'Content-Type': 'application/json'
//   // };
//   // var request = http.Request('POST', Uri.parse((POSConfig().setup?.utilityBillUrl??'').trim()));
//
//   // print(jsonEncode(map));
//   // request.body = json.encode(map);
//   // request.headers.addAll(headers);
//   //
//   // http.StreamedResponse response = await request.send();
//   //
//   // if (response.statusCode == 200) {
//   //   print(await response.stream.bytesToString());
//   // }
//   // else {
//   //   print(response.reasonPhrase);
//   // }
//
//   DateFormat format = DateFormat("yyyy-MM-dd HH:mm:ss");
//   Map map = {
//     "TransferCFCInfo": {"CFCRequest": formData}
//   };
//   final res =await ApiClient.call("UtilityBillSetup", ApiMethod.POST, data: {
//     "location": POSConfig().setupLocation,
//     "comCode": POSConfig().comCode,
//     "stationId": POSConfig().terminalId,
//     "cashier": userBloc.currentUser?.uSERHEDUSERCODE ?? '',
//     "date": format.format(DateTime.now()),
//     "type": type,
//     "response": "",
//     "request": map
//   });
//   EasyLoading.dismiss();
//
//   print(res?.data);
//
//   if(res?.data["success"] == true) {
//     final data = res?.data["data"];
//     final response = jsonDecode(data["response"]);
//     final cfcResponse =
//         TransferCFCInfoResponse.fromJson(response["TransferCFCInfoResponse"]);
//     print(cfcResponse.transferCFCInfoResult?.responseDescrp);
//     print(cfcResponse.transferCFCInfoResult?.responseCode);
//     if(cfcResponse.transferCFCInfoResult?.responseCode == "00") {
//       EasyLoading.showInfo(cfcResponse.transferCFCInfoResult?.responseDescrp??'');
//       return null;
//     }
//     return cfcResponse.transferCFCInfoResult?.responseDescrp;
//   }else{
//     return 'Invalid Request';
//   }
//
//
// }
}
