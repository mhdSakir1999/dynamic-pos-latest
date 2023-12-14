/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/12/21, 7:12 PM
 */

import 'dart:convert';

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/models/loyalty/customer_list_result.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'loyalty_controller.dart';

WebSocketChannel? dualScreenChannel;

class DualScreenController {
  String url = POSConfig().webSocketUrl;
  static String uuid = '';

  Future<void> setView(String view) async {
    // final res= await ApiClient.call("dual_screen", ApiMethod.POST,local: true,errorToast: false,
    //     formData: FormData.fromMap({'view': view}));
    // print('ssssssssssssssssssssssssssssssssssssssss');
  }

  Future<void> sendLankaQr(double amount) async {
    final Map<String, dynamic> data = <String, dynamic>{
      "type": "lankaqr",
      "data": {
        "type": "lankaqr",
        "com_code": POSConfig().comCode,
        "loc_code": POSConfig().locCode,
        "terminal": POSConfig().terminalId,
        "inv_no": cartBloc.cartSummary?.invoiceNo ?? '',
        "amount": amount,
      }
    };
    dualScreenChannel?.sink.add(json.encode(data));
  }

  Future<void> setLandingScreen() async {
    // final setup = await SetUpController().getSetupData(POSConfig().server);
    final setup = POSConfig().setup;
    String user = userBloc.currentUser?.uSERHEDPICTURE ?? "";
    if (user.isNotEmpty) {
      user = '${POSConfig().posImageServer}images/user/$user';
    } else {
      user = '';
    }

    final Map<String, dynamic> data = <String, dynamic>{
      "type": "landing",
      "uuid": uuid,
      "video": POSConfig().local + "videos/video.mp4",
      "cashier": getCashier(),
      "data": {
        "title":
            "Welcome to ${POSConfig().comName} - ${POSConfig().setupLocationName}",
        "subtitle": "I'm ${getCashier()} and happy to serve you today!",
        "scroll_message": setup?.scrolL_MESSAGE ?? '',
        "thank_you_message": setup?.thanK_YOU_MESSAGE ?? '',
        "location": POSConfig().setupLocationName,
        'image': user
      }
    };
    dualScreenChannel?.sink.add(json.encode(data));

    //new change-- added for log checkup
    LogWriter().saveLogsToFile('WEB_SOCKET_', [json.encode(data).toString()]);
    dualScreenChannel?.stream.handleError((error) {
      print('WebSocket error: $error');
      LogWriter().saveLogsToFile(
          'WEB_SOCKET_', [data.toString(), 'WebSocket error: $error']);
    });
    LogWriter().saveLogsToFile('WEB_SOCKET_', [
      data.toString(),
      'channel closed: ${dualScreenChannel?.closeCode}+${dualScreenChannel?.closeReason}'
          'channel data: ${data.toString()}'
    ]);
  }

  Future<void> setCustomer(CustomerResult customer) async {
    final loyaltyRes =
        await LoyaltyController().getLoyaltySummary(customer.cMCODE ?? "");
    final Map<String, dynamic> data = <String, dynamic>{
      "type": "loyalty",
      "uuid": uuid,
      "video": POSConfig().local + "videos/video.mp4",
      "cashier": getCashier(),
      "data": {
        "code": customer.cMCODE ?? '',
        "name": customer.cMNAME ?? '',
        "active": customer.cMACTIVE ?? false,
        "points": loyaltyRes?.pOINTSUMMARY ?? 0,
        "image": POSConfig().loyaltyServerImage + (customer.cMPICTURE ?? ''),
        "group": customer.cMGROUP ?? '',
      }
    };
    dualScreenChannel?.sink.add(json.encode(data));
  }

  void sendLastProduct(CartModel? model) {
    final items = cartBloc.cartSummary?.items ?? 0;
    final qty = cartBloc.cartSummary?.qty ?? 0;
    final invNo = cartBloc.cartSummary?.invoiceNo ?? '';
    final total = cartBloc.cartSummary?.subTotal ?? 0;

    if (model == null) {
      return;
    }

    final Map<String, dynamic> data = <String, dynamic>{
      "type": "invoice",
      "video": POSConfig().local + "videos/video.mp4",
      "uuid": uuid,
      "cashier": getCashier(),
      "data": {
        'summary': {
          'items': items,
          'qty': qty.toDouble(),
          'inv_no': invNo,
          'total': total.toStringAsFixed(2)
        },
        'product': {
          'code': model.scanBarcode,
          'desc': model.posDesc,
          'selling': model.selling.toStringAsFixed(2),
          'line_amount': model.amount.toStringAsFixed(2),
          'qty': model.unitQty.toStringAsFixed(2),
          'image': model.image ?? '',
          'void': model.itemVoid?.toString() ?? '',
          'discount': getDiscount(model)
        },
        'products': _getProductList()
      }
    };
    dualScreenChannel?.sink.add(json.encode(data));
  }

  void sendPayment(double paid, double billTotal, double saving) {
    final items = cartBloc.cartSummary?.items ?? 0;
    final qty = cartBloc.cartSummary?.qty ?? 0;
    final invNo = cartBloc.cartSummary?.invoiceNo ?? '';
    final total = cartBloc.cartSummary?.subTotal ?? 0;
    final taxExc = cartBloc.cartSummary?.taxExc ?? 0;
    final due = billTotal;
    double change = 0;
    if (paid > billTotal) {
      change = paid - billTotal;
    }

    final Map<String, dynamic> data = <String, dynamic>{
      "type": "payment",
      "video": POSConfig().local + "videos/video.mp4",
      "uuid": uuid,
      "cashier": getCashier(),
      "data": {
        'summary': {
          'items': items,
          'qty': qty.toDouble(),
          'inv_no': invNo,
          'total': (total + taxExc).thousandsSeparator()
        },
        'payment': {
          'paid': paid,
          'due': due,
          'change': change,
          'saving': saving,
          'link': ''
        },
        'products': _getProductList()
      }
    };
    dualScreenChannel?.sink.add(json.encode(data));
  }

  void completeInvoice(double paid, double due, double change, double saving) {
    final items = cartBloc.cartSummary?.items ?? 0;
    final qty = cartBloc.cartSummary?.qty ?? 0;
    final invNo = cartBloc.cartSummary?.invoiceNo ?? '';
    final total = cartBloc.cartSummary?.subTotal ?? 0;
    final Map<String, dynamic> data = <String, dynamic>{
      "type": "bill_close",
      "video": POSConfig().local + "videos/video.mp4",
      "cashier": getCashier(),
      "uuid": uuid,
      "data": {
        'summary': {
          'items': items,
          'qty': qty.toDouble(),
          'inv_no': invNo,
          'total': total.toDouble()
        },
        'payment': {
          'paid': paid,
          'due': due,
          'change': change,
          'saving': saving,
        }
      }
    };
    dualScreenChannel?.sink.add(json.encode(data));
    Future.delayed(const Duration(seconds: 10), () {
      setLandingScreen();
    });
  }

  String getCashier() {
    return (userBloc.currentUser?.uSERHEDTITLE ?? '').toUpperCase();
  }

  List<Map<String, String>> _getProductList() {
    return cartBloc.currentCart?.values
            .map((value) => {
                  'code': value.proCode,
                  'desc': value.posDesc,
                  'selling': value.selling.toStringAsFixed(2),
                  'line_amount': value.amount.toStringAsFixed(2),
                  'qty': value.unitQty.toStringAsFixed(2),
                  'image': value.image ?? '',
                  'void': value.itemVoid?.toString() ?? '',
                  'discount': getDiscount(value)
                })
            .toList() ??
        [];
  }

  String getDiscount(CartModel value) {
    String discountText = "";
    if ((value.discPer ?? 0) != 0) {
      discountText = value.discPer?.toStringAsFixed(2) ?? '0.00';
      discountText = discountText + ' %';
    }
    if ((value.billDiscPer ?? 0) != 0) {
      discountText = value.billDiscPer?.toStringAsFixed(2) ?? '0.00';
      discountText = discountText + ' %';
    }
    if ((value.promoDiscPre ?? 0) != 0) {
      discountText = value.promoDiscPre?.toStringAsFixed(2) ?? '0.00';
      discountText = discountText + ' %';
    }
    if ((value.discAmt ?? 0) != 0) {
      discountText = value.discAmt?.toStringAsFixed(2) ?? '0.00';
    }
    if ((value.billDiscAmt ?? 0) != 0) {
      discountText = value.billDiscAmt?.toStringAsFixed(2) ?? '0.00';
    }
    if ((value.promoDiscAmt ?? 0) != 0) {
      discountText =
          value.promoDiscAmt?.toStringAsFixed(2) ?? '0.00' + ' Discount';
    }

    if (discountText != '') discountText = 'Discount : ' + discountText;
    return discountText;
  }
}
