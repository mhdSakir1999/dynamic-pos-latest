/// Copyright (c) 2023 myPOS Software Solutions.  All rights reserved.
/// Author: [TM.SAKIR]
/// Created At: 2023-12-18 2.30PM.
/// Manual way to generate printouts from pos -- only supports windows

// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/models/pos/pos_denomination_model.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:supercharged/supercharged.dart';
import 'package:usb_esc_printer_windows/usb_esc_printer_windows.dart'
    as usb_esc_printer_windows;
import 'package:xml/xml.dart' as xml;
import 'package:collection/collection.dart';

class POSManualPrint {
  late Generator generator;
  List<int> bytes = [];
  late Map<String, dynamic> invHed = {}, loc_det = {};
  late List<dynamic> promoSummary = [];
  late Map<String, dynamic>? customer;
  String invNo = '';
  String loc_code = '';
  String date = '';
  String startTime = '';
  num netAmount = 0;
  num allDiscountTotal = 0;
  String cashier = '-';
  String station = '';
  String endTime = '';
  String loc_desc = '';
  String address = '';
  String email = '';
  String phone = '';
  String custName = '';
  String memberId = '';
  List invDet = [];
  int totalProductsLength = 0;
  var alignment = PosAlign.left;
  String xmlContent = '';
  var item;
  List<Map<String, dynamic>> voidedItems = [];
  List uniqueProducts = [];
  num totalQty = 0;
  num totalLineAmount = 0;
  String discount_description = '';
  List invPayment = [];
  List invPayModeHead = [];
  List invPayModeDet = [];
  int totalPayments = 0;
  List<PosColumn> posColList = [];
  String lineNo = '->';

  String proDesc = 'product_description';
  String stockCode = 'stock_code';
  String sellingPrice = '--';
  String qt = '--';
  String lineAmt = '--';
  String payment_desc = '--';
  String payment_refCode = '--';
  num paymentAmount = 0;
  double balancePoints = 0;
  double earnedPoints = 0;
  double redeemedPoints = 0;
  String promoSummaryLineName = '';
  double promoSummaryLineAmount = 0;
  int promo_sum_lineNo = 0;

  String setupAdd1 = '';
  String setupAdd2 = '';
  String setupAdd3 = '';

  String mng_signOffUser = '';
  String mng_signOffDate = '';
  String mng_signOffTime = '';
  String mng_location = '';
  String mng_printedOn = DateFormat("yyyy-MM-dd HH:mm:ss")
      .parse(DateTime.now().toString())
      .toString()
      .split('.')[0];
  String mng_printedUser = '';
  String mng_station = '';
  double mng_shift = 0;
  String mng_startInv = '';
  String mng_endInv = '';
  double mng_invCount = 0;
  double mng_cancelInvCount = 0;
  double mng_refundAmt = 0;
  double mng_totDiscount = 0;
  double mng_holdBills = 0;
  double mng_netAmt = 0;
  double mng_openingBalance = 0;
  double mng_totCashSales = 0;
  double mng_withdrawals = 0;
  double mng_reciepts = 0;
  double mng_calcCashAmt = 0;
  double mng_cshPhysical = 0;
  double mng_cshVariance = 0;

  String cashDenominationDesc = '';
  int deno_count = 0;
  double deno_value = 0;
  double deno_multiply_amt = 0;
  double tot_csh_declaration = 0;

  var signoffPayDetails = [];
  String sod_payType = '';
  double sod_sysAmt = 0;
  double sod_phyAmt = 0;
  double sod_variance = 0;

  String printerName = '';
  int variableMaxLength = 42;

  List<String> printMassages = [];
  String printMessage = '';

  Map<String, List<Map<String, dynamic>>> promoTicketHeadGroupedData = {};
  List promoTicketsData = [];
  var currentPromoTicket;
  var ticketLineDescsList = [];
  var currentTicketLineDescsMap = {};
  List<String> ticketLineContents = [];
  String ticketLineContent = '';
  String serial = '';
  num ticketValue = 0;

  String receipt_remark = '';
  String rwDescription = '';

  bool triggerCashDrawer = false;

  Future<void> printInvoice(
      {required String data,
      var points,
      bool reprint = false,
      bool cancel = false}) async {
    try {
      printerName = POSConfig.printerName;
      File file = File("${POSConfig.localPrintPath}/invoiceTemplate.xml");
      if (await file.exists()) {
        xmlContent = await file.readAsString();
      }

      var document = xml.XmlDocument.parse(xmlContent);
      // Get the root element
      var rootElement = document.rootElement;
      // Get a list of child nodes under the root element
      List<xml.XmlNode> childNodes = rootElement.children;

      var det = jsonDecode(data);
      await LogWriter().saveLogsToFile('ERROR_LOG_',
          ['Starting the printing process...', 'Tables: ${det.toString()}']);
      if (points != null) balancePoints = points;
      var profile = await CapabilityProfile.load(name: 'default');
      generator = Generator(PaperSize.mm80, profile);

      // Inv header table items
      invHed = det['T_TBLINVHEADER'].first;
      invNo = invHed['INVHED_INVNO'];
      loc_code = invHed['INVHED_LOCCODE'];
      date = invHed['INVHED_TXNDATE'].split('T')[0]; // 2023-12-19T00:00:00
      startTime =
          invHed['INVHED_STARTTIME'].split('T')[1] ?? ''; // 1900-01-01T10:06:22
      netAmount = invHed['INVHED_NETAMT'] ?? 0;
      cashier = invHed['INVHED_CASHIER'] ?? '';
      station = invHed['INVHED_STATION'] ?? '';
      endTime = invHed['INVHED_ENDTIME'].split('T')[1] ?? '';

      if (det['U_TBLPRINTMSG'].length != 0) {
        det['U_TBLPRINTMSG']
            .forEach((element) => printMassages.add(element['PR_DESC']));

        printMessage = printMassages.join('\n');
      }

      if (!reprint && !cancel) {
        if (det['T_TBLINVPROMOTICKETS'].length != 0) {
          promoTicketsData = det['T_TBLINVPROMOTICKETS'];
        }

        //promotion related calcs
        if (det['M_TBLPROMOTION_TICKETS_HED'].length != 0) {
          var ticketHed = det['M_TBLPROMOTION_TICKETS_HED'];
          for (var item in ticketHed) {
            final code = item['TICKET_CODE'];
            if (!promoTicketHeadGroupedData.containsKey(code)) {
              promoTicketHeadGroupedData[code] = [];
            }
            promoTicketHeadGroupedData[code]!.add(item);
          }
        }
      }

      // Location table items
      loc_det = det['M_TBLLOCATIONS']
          .firstWhere((element) => element['LOC_CODE'] == loc_code);
      loc_desc = loc_det['LOC_DESC'];
      address = loc_det['LOC_ADD1'] +
              ', ' +
              loc_det['LOC_ADD2'] +
              ', ' +
              loc_det['LOC_ADD3'] ??
          ' ';
      email = loc_det['LOC_EMAIL'] ?? ' ';
      /* web is hardcoded in crystal report */
      phone = loc_det['LOC_PHONE1'] ?? ' ';

      // Customer table items & loyalty
      customer =
          det['M_TBLCUSTOMER'].length != 0 ? det['M_TBLCUSTOMER'].first : null;
      custName =
          invHed['INVHED_MEMBER'].isEmpty ? '' : customer?['CM_FULLNAME'] ?? '';
      memberId = invHed['INVHED_MEMBER'].isEmpty ? '' : invHed['INVHED_MEMBER'];
      earnedPoints = invHed['INVHED_POINTADDED'];
      redeemedPoints = invHed['INVHED_POINTDEDUCT'];

      // Inv Details table items
      invDet = det['T_TBLINVDETAILS'];
      invDet.forEach((element) {
        if (element['INVDET_VOID'] == true) {
          voidedItems.add(element);
        }
      });
      invDet.removeWhere((element) => element['INVDET_VOID'] == true);
      totalProductsLength = invDet.length;

      // Inv Payments table items
      invPayment = det['T_TBLINVPAYMENTS'];
      invPayModeHead = det['M_TBLPAYMODEHEAD'];
      invPayModeDet = det['M_TBLPAYMODEDET'];

      totalPayments = invPayment.length;

      promoSummary = det['T_TBLINVFREEISSUES'] ?? [];

      await LogWriter()
          .saveLogsToFile('ERROR_LOG_', ['Start writing the invoice...']);
      await writeInvoiceBytes(
          childNodes: childNodes, reprint: reprint, cancel: cancel);
      await LogWriter()
          .saveLogsToFile('ERROR_LOG_', ['Finished writing the invoice...']);

      // Cutting the paper
      bytes += generator.cut();

      if (promoTicketsData.isNotEmpty) {
        try {
          File file = File("${POSConfig.localPrintPath}/ticketTemplate.xml");
          if (await file.exists()) {
            xmlContent = await file.readAsString();
          }

          var document = xml.XmlDocument.parse(xmlContent);
          // Get the root element
          var rootElement = document.rootElement;
          // Get a list of child nodes under the root element
          List<xml.XmlNode> ticketchildNodes = rootElement.children;
          for (int t = 0; t < promoTicketsData.length; t++) {
            serial = promoTicketsData[t]['PROMO_SERIAL'];
            ticketValue = promoTicketsData[t]['PROMO_TICKETVALUE'];
            currentPromoTicket = promoTicketsData[t];
            await writeTicketBytes(childNodes: ticketchildNodes);
            bytes += generator.cut();
          }
        } catch (e) {
          print(e);
        }
      }
      if (triggerCashDrawer) {
        bytes += generator.drawer();
      }
      // Sending esc commands to printer
      final sendToPrint = await usb_esc_printer_windows.sendPrintRequest(
          bytes, printerName); //[POS-80C,EPSON TM-T88V Receipt]
      await LogWriter().saveLogsToFile('ERROR_LOG_',
          ['PRINTING COMMAND/JOB SENT TO $printerName SUCCESSFUL']);
    } catch (e) {
      print(e.toString());
      await LogWriter()
          .saveLogsToFile('ERROR_LOG_', ['Printing error :' + e.toString()]);
    }
  }

  Future<void> printSignSlip(
      {required String data, required String slipType, double? float}) async {
    try {
      printerName = POSConfig.printerName;
      File file = File("${POSConfig.localPrintPath}/signTemplate.xml");
      if (await file.exists()) {
        xmlContent = await file.readAsString();
      }

      var document = xml.XmlDocument.parse(xmlContent);
      // Get the root element
      var rootElement = document.rootElement;
      // Get a list of child nodes under the root element
      List<xml.XmlNode> childNodes = rootElement.children;

      // var det = jsonDecode(data);
      var profile = await CapabilityProfile.load(name: 'default');
      generator = Generator(PaperSize.mm80, profile);

      await writeSignBytes(
          childNodes: childNodes, type: slipType, float: float);

      // Cutting the paper
      bytes += generator.cut();

      // Sending esc commands to printer
      final sendToPrint =
          await usb_esc_printer_windows.sendPrintRequest(bytes, printerName);
      await LogWriter().saveLogsToFile('ERROR_LOG_',
          ['PRINTING COMMAND/JOB SENT TO $printerName SUCCESSFUL']);
    } catch (e) {
      print(e.toString());
      await LogWriter()
          .saveLogsToFile('ERROR_LOG_', ['Printing error :' + e.toString()]);
    }
  }

  Future<void> printManagerSlip(
      {required String data,
      required List<POSDenominationModel> denominations,
      required List<POSDenominationDetail> denominationDet}) async {
    try {
      printerName = POSConfig.printerName;
      File file = File("${POSConfig.localPrintPath}/mngSignTemplate.xml");
      if (await file.exists()) {
        xmlContent = await file.readAsString();
      }

      var document = xml.XmlDocument.parse(xmlContent);
      // Get the root element
      var rootElement = document.rootElement;
      // Get a list of child nodes under the root element
      List<xml.XmlNode> childNodes = rootElement.children;

      // var det = jsonDecode(data);
      var profile = await CapabilityProfile.load(name: 'default');
      generator = Generator(PaperSize.mm80, profile);
      print(data);

      var userHed = userBloc.currentUser;
      var det = jsonDecode(data);

      signoffPayDetails = det['SignOffDetails'];

      var signOffHeadDet = det['SignOffHeader']?[0];
      mng_signOffUser = signOffHeadDet["SOH_USER"] ?? '';
      var signoffdate =
          signOffHeadDet["SOH_BKOFFDATE"]; //"2024-01-11T11:00:31.513"
      mng_signOffDate = signoffdate.split('T')[0];
      mng_signOffTime = (signoffdate ?? '').split('T')[1].split('.')[0];
      mng_location = signOffHeadDet?['SOH_LOCATION'] ?? '';
      mng_printedUser = userHed?.uSERHEDUSERCODE ?? ' N/A';
      mng_station = signOffHeadDet['SOH_STATION'] ?? 'N/A';
      mng_shift = signOffHeadDet['SOH_SHIFT'] ?? 0;
      mng_startInv = signOffHeadDet['SOH_STARTINVNO'] ?? '';
      mng_endInv = signOffHeadDet['SOH_ENDINVNO'] ?? '';
      mng_invCount = signOffHeadDet['SOH_INVCOUNT'] ?? 0;
      mng_cancelInvCount = signOffHeadDet['SOH_CANINVCOUNT'] ?? 0;
      mng_refundAmt = signOffHeadDet['SOH_REFUNDTOTAL'] ?? 0;
      mng_totDiscount = signOffHeadDet['SOH_DISCTOTAL'] ?? 0;
      mng_holdBills = signOffHeadDet['SOH_TOTHOLDBILLS'] ?? 0;
      mng_netAmt = signOffHeadDet['SOH_BILLNETTOTAL'] ?? 0;

      mng_openingBalance = signOffHeadDet['SOH_OPBALANCE'] ?? 0;
      mng_totCashSales = signOffHeadDet['SOH_CASHSALE'] ?? 0;
      mng_withdrawals = signOffHeadDet['SOH_WITHDRAWALS'] ?? 0;
      mng_reciepts = signOffHeadDet['SOH_RECEIPTS'] ?? 0;
      mng_calcCashAmt = signOffHeadDet['SOH_CASHCALCULATED'] ?? 0;
      mng_cshPhysical = signOffHeadDet['SOH_CASHPHYSICAL'] ?? 0;
      mng_cshVariance = mng_cshPhysical - mng_calcCashAmt;

      await writeMngSignBytes(
          childNodes: childNodes,
          cshdeno: denominationDet,
          denos: denominations);

      // Cutting the paper
      bytes += generator.cut();

      // Sending esc commands to printer
      final sendToPrint =
          await usb_esc_printer_windows.sendPrintRequest(bytes, printerName);
      await LogWriter().saveLogsToFile('ERROR_LOG_',
          ['PRINTING COMMAND/JOB SENT TO $printerName SUCCESSFUL']);
    } catch (e) {
      print(e.toString());
      await LogWriter()
          .saveLogsToFile('ERROR_LOG_', ['Printing error :' + e.toString()]);
    }
  }

  Future<void> printCashReceiptSlip({
    required String data,
    required bool cashIn,
    required String runno,
    required bool isAdvance,
  }) async {
    try {
      printerName = POSConfig.printerName;
      File file = File("${POSConfig.localPrintPath}/receiptTemplate.xml");
      if (await file.exists()) {
        xmlContent = await file.readAsString();
      }

      var document = xml.XmlDocument.parse(xmlContent);
      // Get the root element
      var rootElement = document.rootElement;
      // Get a list of child nodes under the root element
      List<xml.XmlNode> childNodes = rootElement.children;

      var det = jsonDecode(data);
      await LogWriter().saveLogsToFile('ERROR_LOG_',
          ['Starting the printing process...', 'Tables: ${det.toString()}']);
      var profile = await CapabilityProfile.load(name: 'default');
      generator = Generator(PaperSize.mm80, profile);

      // Inv header table items
      invHed = det['T_TBLINVHEADER'].first;
      invNo = invHed['INVHED_INVNO'];
      loc_code = invHed['INVHED_LOCCODE'];
      date = invHed['INVHED_TXNDATE'].split('T')[0]; // 2023-12-19T00:00:00
      startTime =
          invHed['INVHED_STARTTIME'].split('T')[1] ?? ''; // 1900-01-01T10:06:22
      netAmount = invHed['INVHED_NETAMT'] ?? 0;
      cashier = invHed['INVHED_CASHIER'] ?? '';
      station = invHed['INVHED_STATION'] ?? '';
      endTime = invHed['INVHED_ENDTIME'].split('T')[1] ?? '';

      if (det['U_TBLPRINTMSG'].length != 0) {
        det['U_TBLPRINTMSG']
            .forEach((element) => printMassages.add(element['PR_DESC']));

        printMessage = printMassages.join('\n');
      }

      // Location table items
      loc_det = det['M_TBLLOCATIONS']
          .firstWhere((element) => element['LOC_CODE'] == loc_code);
      loc_desc = loc_det['LOC_DESC'];
      address = loc_det['LOC_ADD1'] +
              ', ' +
              loc_det['LOC_ADD2'] +
              ', ' +
              loc_det['LOC_ADD3'] ??
          ' ';

      // Inv Details table items
      invDet = det['T_TBLINVDETAILS'];
      receipt_remark = invDet?[0]?['INVDET_DISTYPE'] ?? '';
      rwDescription = invDet?[0]?['INVDET_PRODESC'] ?? '';
      invDet.forEach((element) {
        if (element['INVDET_VOID'] == true) {
          voidedItems.add(element);
        }
      });
      invDet.removeWhere((element) => element['INVDET_VOID'] == true);
      totalProductsLength = invDet.length;

      // Inv Payments table items
      invPayment = det['T_TBLINVPAYMENTS'];
      payment_refCode = invPayment?[0]?['INVPAY_REFNO'] ?? '';
      invPayModeHead = det['M_TBLPAYMODEHEAD'];
      invPayModeDet = det['M_TBLPAYMODEDET'];

      totalPayments = invPayment.length;
      for (int i = 0; i < totalPayments; i++) {
        var payMode = invPayment[i];
        if (payMode['INVPAY_PHCODE'] == payMode['INVPAY_PDCODE']) {
          payment_desc = invPayModeHead.firstWhere(
                (element) => element['PH_CODE'] == payMode['INVPAY_PHCODE'],
                orElse: () => null,
              )['PH_DESC'] ??
              'CASH';
          payment_refCode = '--';
          if (payMode['INVPAY_PHCODE'] == 'CSH') {
            triggerCashDrawer = true;
          }
        } else {
          payment_desc = invPayModeDet.firstWhere(
                (element) => element['PD_CODE'] == payMode['INVPAY_PDCODE'],
                orElse: () => null,
              )?['PD_DESC'] ??
              'UNKNOWN';
          if (payMode['INVPAY_PHCODE'] == 'CRC') {
            payment_refCode = payMode['INVPAY_REFNO']
                .split('-')[3]; // 1111-11**-****-1111  last  digits
          } else if (payMode['INVPAY_PHCODE'] == 'CSH') {
            payment_refCode = '';
            triggerCashDrawer = true;
          } else {
            payment_refCode = '';
          }
        }
      }

      await LogWriter()
          .saveLogsToFile('ERROR_LOG_', ['Start writing the receipt...']);
      await writeReceiptBytes(
          childNodes: childNodes,
          type: cashIn ? 'REC' : 'WIT',
          runNo: runno,
          receiptAmount: netAmount.toDouble(),
          isAdvance: isAdvance);
      await LogWriter()
          .saveLogsToFile('ERROR_LOG_', ['Finished writing the receipt...']);

      // Cutting the paper
      bytes += generator.cut();

      if (triggerCashDrawer) {
        bytes += generator.drawer();
      }
      // Sending esc commands to printer
      final sendToPrint = await usb_esc_printer_windows.sendPrintRequest(
          bytes, printerName); //[POS-80C,EPSON TM-T88V Receipt]

      // printing the slip again if it is a advanced payment
      if (isAdvance == true) {
        final sendToPrint2ndTime =
            await usb_esc_printer_windows.sendPrintRequest(bytes, printerName);
      }
      await LogWriter().saveLogsToFile('ERROR_LOG_',
          ['PRINTING COMMAND/JOB SENT TO $printerName SUCCESSFUL']);
      return;
    } catch (e) {
      print(e.toString());
      await LogWriter()
          .saveLogsToFile('ERROR_LOG_', ['Printing error :' + e.toString()]);
      return;
    }
  }

  Future<void> writeInvoiceBytes(
      {required List<xml.XmlNode> childNodes,
      String? colCount,
      bool reprint = false,
      bool cancel = false}) async {
    for (int i = 1; i < childNodes.length; i += 2) {
      print(childNodes[i].toString());
      var node = childNodes[i];
      if (node is xml.XmlElement) {
        var attributes = node.attributes;
        String label = mapValue(attributes, 'label');
        String value = mapValue(attributes, 'value');
        String align =
            mapValue(attributes, 'align', defaultValue: 'left'); // removed
        String font = mapValue(attributes, 'font', defaultValue: 'A');
        String bold = mapValue(attributes, 'bold', defaultValue: 'false');
        String height = mapValue(attributes, 'height', defaultValue: '1');
        String width = mapValue(attributes, 'width', defaultValue: '1');
        String hr = mapValue(attributes, 'hr', defaultValue: 'false');
        String reprintString =
            mapValue(attributes, 'reprint', defaultValue: '-');
        String cancelString = mapValue(attributes, 'cancel', defaultValue: '-');
        String inCancelBill =
            mapValue(attributes, 'inCancelBill', defaultValue: 'true');
        String numOfColumns =
            mapValue(attributes, 'colCount', defaultValue: '0');
        String numOfRows = mapValue(attributes, 'rowCount', defaultValue: '0');
        String rowlength = mapValue(attributes, 'len', defaultValue: '12');
        String hrlength = mapValue(attributes, 'hrlen', defaultValue: '58');

        if (printerName == 'POS-80C' ||
            printerName == 'GP-C80250 Series' ||
            printerName == 'GP-C80250') {
          if (font == 'A') {
            variableMaxLength = 48;
            hrlength = '48';
          } else {
            variableMaxLength = 64;
            hrlength = '64';
          }
        } else if (printerName == 'EPSON TM-T88V Receipt' ||
            printerName == 'EPSON TM-T88V Receipt5') {
          if (font == 'A') {
            variableMaxLength = 42;
            hrlength = '42';
          } else {
            variableMaxLength = 56;
            hrlength = '56';
          }
        } else if (printerName == 'Posiflex PP9000 Printer') {
          if (font == 'A') {
            variableMaxLength = 42;
            hrlength = '42';
          } else {
            variableMaxLength = 42;
            hrlength = '42';
          }
        } else {
          if (font == 'A') {
            variableMaxLength = POSConfig.font_a_length;
            hrlength = POSConfig.font_a_length.toString();
          } else {
            variableMaxLength = POSConfig.font_b_length;
            hrlength = POSConfig.font_b_length.toString();
          }
        }

        if (align == 'right') {
          alignment = PosAlign.right;
        } else if (align == 'center') {
          alignment = PosAlign.center;
        } else {
          alignment = PosAlign.left;
        }

        if (node.name.local == "logo") {
          // Printing image-block
          try {
            File data = File("${POSConfig.localPrintPath}/$value");
            Uint8List bytes1 = data.readAsBytesSync();
            Image image = decodeImage(
              bytes1,
            )!;
            final resized =
                copyResize(image, width: width.toInt(), height: height.toInt());
            // Using `GS v0`
            bytes += generator.imageRaster(
              resized,
            );
          } catch (e) {
            print(e);
          }
        }
        if (node.name.local == "feed") {
          bytes += generator.feed(int.parse(value));
        }
        if (node.name.local == "hr") {
          // skip some parts if it is a cancel bill
          if (cancel && inCancelBill == 'false') {
            continue;
          }
          bytes += generator.hr(
              len: hrlength.toInt() /* font == 'A' ? hrlength.toInt() : 56 */);
        }
        if (node.name.local == "barcode") {
          // bytes += generator.barcode(Barcode.upcA(invNo.split("")),
          //     width: int.tryParse(width), height: int.tryParse(height));
          List prefixData = ['{', 'A'];
          prefixData.addAll(invNo.split(""));
          bytes += generator.barcode(Barcode.code128(prefixData),
              width: int.tryParse(width), height: int.tryParse(height));
        }
        if (node.name.local == "text") {
          //the substracted values are the lengths of the labels
          // we can either pass direct string or regExp
          value = value.replaceAll("{lineNo}", "${addSpacesBack(lineNo, 3)}");
          value = value.replaceAll("{item_desc}",
              "${addSpacesBack(proDesc, variableMaxLength - 4)}");
          value = value.replaceAll("{address}", '$address');
          value = value.replaceAll("{email}", '$email');
          value = value.replaceAll("{number}", '$phone');
          value = value.replaceAll("{startdate}",
              addSpacesBack('$date  $startTime', variableMaxLength - 14));
          value = value.replaceAll(
              "{invNo}", addSpacesBack('$invNo', variableMaxLength - 14));
          value = value.replaceAll("{customerName}", '$custName');
          value = value.replaceAll("{location}", "$loc_desc");
          value =
              value.replaceAll("{stockCode}", addSpacesBack("$stockCode", 12));
          value =
              value.replaceAll("{price}", addSpacesFront("$sellingPrice", 11));
          value = value.replaceAll("{qty}", addSpacesFront("$qt", 7));
          value = value.replaceAll(
              "{amount}", addSpacesFront("$lineAmt", variableMaxLength - 30));
          value = value.replaceAll("{discount}",
              addSpacesBack("$discount_description", variableMaxLength));
          value = value.replaceAll(
              "{grossAmount}",
              addSpacesFront("${formatWithCommas(totalLineAmount)}",
                  variableMaxLength - 15));
          value = value.replaceAll(
              "{allDiscountTotal}",
              addSpacesFront("${formatWithCommas(allDiscountTotal)}",
                  variableMaxLength - 15));
          value = value.replaceAll(
              "{netAmount}",
              addSpacesFront(
                  "${formatWithCommas(netAmount)}", variableMaxLength - 15));
          value = value.replaceAll(
              "{productCount}",
              addSpacesBack(
                  "${uniqueProducts.length}", variableMaxLength - 38));
          value = value.replaceAll(
              "{qtyCount}", addSpacesFront("${formatQuantity(totalQty)}", 7));
          value = value.replaceAll(
              "{balance}",
              addSpacesFront("${formatWithCommas(invHed['INVHED_CHANGE'])}",
                  variableMaxLength - 15));
          value = value.replaceAll(
              "{payment_desc}", addSpacesBack("$payment_desc", 20));
          value = value.replaceAll(
              "{payment_refCode}", addSpacesBack("$payment_refCode", 4));
          value = value.replaceAll(
              "{paymentAmount}",
              addSpacesFront("${formatWithCommas(paymentAmount)}",
                  variableMaxLength - 27));
          value = value.replaceAll(
              "{cashier}", addSpacesBack("$cashier", variableMaxLength - 29));
          value = value.replaceAll("{station}", addSpacesFront("$station", 5));
          value = value.replaceAll(
              "{endTime}", addSpacesBack("$endTime", variableMaxLength - 12));
          value = value.replaceAll(
              "{memberId}", addSpacesBack("$memberId", variableMaxLength - 20));
          value = value.replaceAll(
              "{custName}", addSpacesBack("$custName", variableMaxLength - 20));
          value = value.replaceAll(
              "{earnedPoints}",
              addSpacesBack(
                  "${formatWithCommas(earnedPoints)}", variableMaxLength - 24));
          value = value.replaceAll(
              "{redeemedPoints}",
              addSpacesBack("${formatWithCommas(redeemedPoints)}",
                  variableMaxLength - 24));
          value = value.replaceAll(
              "{balancePoints}",
              addSpacesBack("${formatWithCommas(balancePoints)}",
                  variableMaxLength - 24));
          value = value.replaceAll("{printMessage}", '$printMessage');
          value = value.replaceAll(
              "{promo_sum_lineNo}", addSpacesBack('$promo_sum_lineNo', 3));
          value = value.replaceAll("{promo_line_desc}",
              addSpacesBack('$promoSummaryLineName', variableMaxLength - 13));

          num promoSummaryLineAmountNum = promoSummaryLineAmount;
          value = value.replaceAll(
              "{promo_line_amount}",
              addSpacesFront(
                  '${formatWithCommas(promoSummaryLineAmountNum)}', 10));
          // skip printing gross amount if gross == net
          if (label == 'gross_amount' && totalLineAmount == netAmount) {
            continue;
          }
          // skip printing discountTotal if it is 0
          if (label == 'all_discount_total' && allDiscountTotal == 0) {
            continue;
          }

          if (label == 'points_earn' && earnedPoints == 0) {
            continue;
          }
          if (label == 'points_deduct' && redeemedPoints == 0) {
            continue;
          }
          if (label == 'manual_hr') {
            value = '-' * variableMaxLength;
          }

          // skip if the printMessage is empty
          if (label == 'print_msg' && printMessage.isEmpty) {
            continue;
          }

          // skip some parts if it is a cancel bill
          if (cancel && inCancelBill == 'false') {
            continue;
          }

          // if (label == 'promoSummary_heading' && promoSummary.isEmpty) {
          //   continue;
          // }

          bytes += generator.text(value,
              styles: PosStyles(
                  align: alignment,
                  bold: bold == 'true',
                  fontType: font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                  height: height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                  width: width == '1' ? PosTextSize.size1 : PosTextSize.size2));
          if (label == "invoice" && reprint) {
            // (label == "invoice" && invHed['INVHED_PRINTNO'] != 0)
            bytes += generator.text(reprintString,
                styles: PosStyles(
                    align: alignment,
                    bold: bold == 'true',
                    fontType:
                        font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                    height:
                        height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                    width:
                        width == '1' ? PosTextSize.size1 : PosTextSize.size2));
          }
          if (label == "invoice" && cancel) {
            // (label == "invoice" && invHed['INVHED_PRINTNO'] != 0)
            bytes += generator.text(cancelString,
                styles: PosStyles(
                    align: alignment,
                    bold: bold == 'true',
                    fontType:
                        font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                    height:
                        height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                    width:
                        width == '1' ? PosTextSize.size1 : PosTextSize.size2));
          }
        }
        if (node.name.local == "row") {
          List<xml.XmlNode> rowchildNodes = node.children;
          await writeInvoiceBytes(
              childNodes: rowchildNodes,
              colCount: numOfColumns,
              reprint: reprint,
              cancel: cancel);
          bytes += generator.row(posColList);
          posColList.clear();
        }
        if (node.name.local == "col") {
          value = value.replaceAll("{stockCode}", "$stockCode");
          value = value.replaceAll("{price}", "$sellingPrice");
          value = value.replaceAll("{qty}", "$qt");
          value = value.replaceAll("{amount}", "$lineAmt");
          value = value.replaceAll("{discount}", "$discount_description");
          value = value.replaceAll(
              "{grossAmount}", "${formatWithCommas(totalLineAmount)}");
          value =
              value.replaceAll("{productCount}", "${uniqueProducts.length}");
          value =
              value.replaceAll("{qtyCount}", "${totalQty.toStringAsFixed(3)}");
          value = value.replaceAll("{cashier}", "$cashier");
          value = value.replaceAll("{station}", "$station");
          value = value.replaceAll("{endTime}", "$endTime");
          value = value.replaceAll(
              "{balance}", "${formatWithCommas(invHed['INVHED_CHANGE'])}");
          value =
              value.replaceAll("{netAmount}", "${formatWithCommas(netAmount)}");
          value = value.replaceAll("{payment_desc}", "$payment_desc");
          value = value.replaceAll("{payment_refCode}", "$payment_refCode");
          value = value.replaceAll(
              "{paymentAmount}", "${formatWithCommas(paymentAmount)}");
          value = value.replaceAll("{memberId}", "$memberId");
          value = value.replaceAll("{custName}", "$custName");
          value = value.replaceAll(
              "{earnedPoints}", "${formatWithCommas(earnedPoints)}");
          value = value.replaceAll(
              "{redeemedPoints}", "${formatWithCommas(redeemedPoints)}");
          value = value.replaceAll(
              "{balancePoints}", "${formatWithCommas(balancePoints)}");

          if (value.isNotEmpty) {
            posColList.add(PosColumn(
                text: value,
                textEncoded: null,
                width: int.parse(rowlength),
                styles: PosStyles(
                    align: alignment,
                    bold: bold == 'true',
                    fontType:
                        font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                    height:
                        height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                    width:
                        width == '1' ? PosTextSize.size1 : PosTextSize.size2)));
          }
        }
        if (node.name.local == "product") {
          List<xml.XmlNode> productchildNodes = node.children;
          for (int j = 0; j < totalProductsLength; j++) {
            if (invDet[j]['INVDET_VOID'] == true) {
              // voidedItems.addAll(invDet[j]);
              continue;
            }

            item = invDet[j];

            if (uniqueProducts.length == 0 ||
                uniqueProducts.firstWhere(
                        (element) =>
                            element['INVDET_PROCODE'] == item['INVDET_PROCODE'],
                        orElse: () => -1) ==
                    -1) {
              uniqueProducts.add(item);
            }
            var thisLineAmount =
                item['INVDET_SELLING'] * item['INVDET_UNITQTY'];
            if (item['INVDET_UNITQTY'] >= 0) {
              totalQty += item['INVDET_UNITQTY'];
            }
            totalLineAmount += thisLineAmount; //item['INVDET_AMOUNT'];

            if (item['INVDET_DISCPER'] == 100) {
              discount_description = 'discount is there';
            } else if (item['INVDET_DISCPER'] != null &&
                item['INVDET_DISCPER'] != 0) {
              discount_description = 'discount is there';
            } else if (item['INVDET_DISCAMT'] != null &&
                item['INVDET_DISCAMT'] != 0) {
              discount_description = 'discount is there';
            } else if (item['INVDET_BILLDISCPER'] != null &&
                item['INVDET_BILLDISCPER'] != 0) {
              discount_description = 'discount is there';
            } else if (item['INVDET_BILLDISCAMT'] != null &&
                item['INVDET_BILLDISCAMT'] != 0) {
              discount_description = 'discount is there';
            } else if (item['INVDET_PROMODISCPER'] != null &&
                item['INVDET_PROMODISCPER'] != 0) {
              discount_description = 'discount is there';
            } else if (item['INVDET_PROMODISCAMT'] != null &&
                item['INVDET_PROMODISCAMT'] != 0) {
              discount_description = 'discount is there';
            } else {
              discount_description = '';
            }
            try {
              lineNo = (j + 1)
                  .toString(); // item['INVDET_LINENO'].toStringAsFixed(0);
              proDesc = discount_description == ''
                  ? '${item['INVDET_PRODESC']} *'
                  : item['INVDET_PRODESC'];
              stockCode = item['INVDET_STOCKCODE'];
              sellingPrice = formatWithCommas(item['INVDET_SELLING']);
              // qt = item['INVDET_UNITQTY'].toStringAsFixed(3);
              qt = formatQuantity(item['INVDET_UNITQTY']);
              lineAmt = formatWithCommas(
                  thisLineAmount); // formatWithCommas(item['INVDET_AMOUNT']);

              await writeInvoiceBytes(
                  childNodes: productchildNodes,
                  reprint: reprint,
                  cancel: cancel);
            } catch (e) {
              print(e);
            }
          }
          allDiscountTotal = totalLineAmount - netAmount;
        }
        if (node.name.local == "discounts") {
          discount_description = '';
          List<xml.XmlNode> discountchildNodes = node.children;
          List<String> discountsList = [];
          if (item['INVDET_DISCPER'] == 100) {
            discountsList.add('(FREE ISSUE)');
          }
          if (item['INVDET_DISCPER'] != null && item['INVDET_DISCPER'] != 0) {
            var discount =
                (item['INVDET_PROSELLING'] * item['INVDET_UNITQTY']) *
                    item['INVDET_DISCPER'] /
                    100;
            discountsList.add(
                '(Line discount ${item['INVDET_DISCPER']}% = ${formatWithCommas(discount)})');
          }
          if (item['INVDET_DISCAMT'] != null && item['INVDET_DISCAMT'] != 0) {
            var discount = item['INVDET_DISCAMT'];
            discountsList
                .add('(Line discount amount = ${formatWithCommas(discount)})');
          }
          if (item['INVDET_BILLDISCPER'] != null &&
              item['INVDET_BILLDISCPER'] != 0) {
            var discount = item['INVDET_BILLDISCPER'];
            discountsList
                .add('(Bill discount = ${formatWithCommas(discount)}%)');
          }
          if (item['INVDET_BILLDISCAMT'] != null &&
              item['INVDET_BILLDISCAMT'] != 0) {
            var discount = item['INVDET_BILLDISCAMT'];
            discountsList
                .add('(Bill discount amount = ${formatWithCommas(discount)})');
          }
          if (item['INVDET_PROMODISCPER'] != null &&
              item['INVDET_PROMODISCPER'] != 0) {
            var discount = item['INVDET_PROMODISCPER'];
            discountsList
                .add('(Promotion discount = ${formatWithCommas(discount)}%)');
          }
          if (item['INVDET_PROMODISCAMT'] != null &&
              item['INVDET_PROMODISCAMT'] != 0) {
            var discount = item['INVDET_PROMODISCAMT'];
            discountsList.add(
                '(Promotion discount amount = ${formatWithCommas(discount)})');
          }

          if (discountsList.isNotEmpty) {
            for (int k = 0; k < discountsList.length; k++) {
              discount_description = discountsList[k];
              await writeInvoiceBytes(
                  childNodes: discountchildNodes,
                  reprint: reprint,
                  cancel: cancel);
            }
          }
        }
        if (node.name.local == "payments") {
          for (int i = 0; i < totalPayments; i++) {
            var payMode = invPayment[i];
            if (payMode['INVPAY_PHCODE'] == payMode['INVPAY_PDCODE']) {
              payment_desc = invPayModeHead.firstWhere(
                    (element) => element['PH_CODE'] == payMode['INVPAY_PHCODE'],
                    orElse: () => null,
                  )['PH_DESC'] ??
                  'CASH';
              payment_refCode = '';
              if (payMode['INVPAY_PHCODE'] == 'CSH') {
                triggerCashDrawer = true;
              } else if (payMode['INVPAY_PHCODE'] == 'ADV') {
                payment_refCode =
                    (payMode?['INVPAY_REFNO'].toString() ?? 'status : N/A')
                        .substring(8);
              }
            } else {
              payment_desc = invPayModeDet.firstWhere(
                    (element) => element['PD_CODE'] == payMode['INVPAY_PDCODE'],
                    orElse: () => null,
                  )?['PD_DESC'] ??
                  'UNKNOWN';
              if (payMode['INVPAY_PHCODE'] == 'CRC') {
                payment_refCode = payMode['INVPAY_REFNO']
                    .split('-')[3]; // 1111-11**-****-1111  last  digits
              } else if (payMode['INVPAY_PHCODE'] == 'CSH') {
                payment_refCode = '';
                triggerCashDrawer = true;
              }
            }
            paymentAmount = (payMode['INVPAY_PHCODE'] == 'CSH')
                ? invHed['INVHED_CHANGE'] + payMode['INVPAY_PAIDAMOUNT']
                : payMode['INVPAY_PAIDAMOUNT'];
            List<xml.XmlNode> paymentChildNodes = node.children;
            await writeInvoiceBytes(
                childNodes: paymentChildNodes,
                reprint: reprint,
                cancel: cancel);
          }
        }
        if (node.name.local == "loyalty" && memberId != '') {
          List<xml.XmlNode> loyaltyChildNodes = node.children;
          await writeInvoiceBytes(
              childNodes: loyaltyChildNodes, reprint: reprint, cancel: cancel);
        }
        if (node.name.local == "balance") {
          List<xml.XmlNode> balanceChildNodes = node.children;
          if (invHed['INVHED_CHANGE'] != 0)
            await writeInvoiceBytes(
                childNodes: balanceChildNodes,
                reprint: reprint,
                cancel: cancel);
        }
        if (node.name.local == "qr") {
          try {
            bytes += generator.qrcode(value,
                size: QRSize.Size6, align: PosAlign.center);
          } catch (e) {
            print(e);
          }
        }

        if (node.name.local == 'promotionSummary' && promoSummary.isNotEmpty) {
          List<xml.XmlNode> promotionSummaryChildNodes = node.children;
          await writeInvoiceBytes(
              childNodes: promotionSummaryChildNodes,
              reprint: reprint,
              cancel: cancel);
        }
        if (node.name.local == 'promoSummary') {
          List<xml.XmlNode> promoSummaryChildNodes = node.children;
          int lineno = promo_sum_lineNo;
          List<Map<String, dynamic>> filteredSummaries = [];
          for (int p = 0; p < promoSummary.length; p++) {
            var promo = promoSummary[p];
            if (filteredSummaries.isEmpty) {
              filteredSummaries.add({
                "code": promo['INVPROMO_PROCODE'],
                "desc": promo['INVPROMO_DESC'],
                "value": promo['INVPROMO_DISC_VALUE']
              });
            } else {
              var available = filteredSummaries.firstWhere(
                (element) => element['code'] == promo['INVPROMO_PROCODE'],
                orElse: () => {"code": null, "desc": null, "value": null},
              );
              if (available['code'] == null) {
                filteredSummaries.add({
                  "code": promo['INVPROMO_PROCODE'],
                  "desc": promo['INVPROMO_DESC'],
                  "value": promo['INVPROMO_DISC_VALUE']
                });
              } else {
                // filteredSummaries.removeWhere((element)=> element['code'] == promo['INVPROMO_PROCODE']);
                available['value'] = (available['value'] ?? 0) +
                    (promo['INVPROMO_DISC_VALUE'] ?? 0);
              }
            }
          }
          for (int s = 0; s < filteredSummaries.length; s++) {
            int lineno = promo_sum_lineNo;
            promoSummaryLineName = filteredSummaries[s]['desc'];
            promoSummaryLineAmount =
                double.parse(filteredSummaries[s]['value']?.toString() ?? '0');

            if (promoSummaryLineAmount != 0) {
              promo_sum_lineNo = lineno + 1;
              await writeInvoiceBytes(
                  childNodes: promoSummaryChildNodes,
                  reprint: reprint,
                  cancel: cancel);
            }
          }
          // for (int p = 0; p < promoSummary.length; p++) {
          //   int lineno = promo_sum_lineNo;
          //   bool condition1 = (promoSummary[p]['INVPROMO_DISCPER'] == null ||
          //       promoSummary[p]['INVPROMO_DISCPER'] == 0);
          //   bool condition2 = (promoSummary[p]['INVPROMO_DICAMT'] == null ||
          //       promoSummary[p]['INVPROMO_DICAMT'] == 0);
          //   if (condition1 && condition2) {
          //     continue;
          //   }
          //   promoSummaryLineName = promoSummary[p]['INVPROMO_DESC'];
          //   if (condition1 && !condition2) {
          //     promoSummaryLineAmount =
          //         double.parse(promoSummary[p]['INVPROMO_DICAMT'].toString());
          //     print(promoSummaryLineName +
          //         '   ' +
          //         promoSummaryLineAmount.toString());
          //   } else {
          //     double promo_qty = double.parse(
          //         promoSummary[p]['INVPROMO_INVQTY']?.toString() ?? '0');
          //     double promo_sell = double.parse(
          //         promoSummary[p]['INVPROMO_SPRICE']?.toString() ?? '0');
          //     double promo_perc =
          //         double.parse(promoSummary[p]['INVPROMO_DISCPER'].toString());

          //     promoSummaryLineAmount =
          //         (promo_qty * promo_sell * promo_perc) / 100;
          //     print(promoSummaryLineName +
          //         '   ' +
          //         promoSummaryLineAmount.toString());
          //   }

          // if (promoSummaryLineAmount != 0) {
          //   promo_sum_lineNo = lineno + 1;
          //   await writeInvoiceBytes(
          //       childNodes: promoSummaryChildNodes,
          //       reprint: reprint,
          //       cancel: cancel);
          // }
          // }
        }
      }
    }
    await LogWriter().saveLogsToFile(
        'ERROR_LOG_', ['Printing Lines :' + childNodes.toString()]);
  }

  Future<void> writeSignBytes(
      {required List<xml.XmlNode> childNodes,
      required String type,
      double? float}) async {
    String slipType = type.toLowerCase() == 'signoff' ? 'SIGN OFF' : 'SIGN ON';
    var userHed = userBloc.currentUser;
    var currentUser = userBloc.userDetails;
    String? signOnDate = (userHed?.uSERHEDSIGNONDATE ?? ' ').split(' ')[0];
    String signOffDate = DateFormat('yyyy-MM-dd HH:mm:ss')
        .parse(DateTime.now().toString())
        .toString()
        .split('.')[0];
    String today = DateFormat.yMEd().add_jms().format(DateTime.now());

    for (int i = 1; i < childNodes.length; i += 2) {
      print(childNodes[i].toString());
      var node = childNodes[i];
      if (node is xml.XmlElement) {
        var attributes = node.attributes;
        // String label = mapValue(attributes, 'label');
        String value = mapValue(attributes, 'value');
        String align = mapValue(attributes, 'align', defaultValue: 'left');
        String font = mapValue(attributes, 'font', defaultValue: 'A');
        String bold = mapValue(attributes, 'bold', defaultValue: 'false');
        String height = mapValue(attributes, 'height', defaultValue: '1');
        String width = mapValue(attributes, 'width', defaultValue: '1');
        // String hr = mapValue(attributes, 'hr', defaultValue: 'false');
        // String option = mapValue(attributes, 'option', defaultValue: '-');
        // String numOfColumns = mapValue(attributes, 'colCount', defaultValue: '0');
        String rowlength = mapValue(attributes, 'len', defaultValue: '12');
        String hrlength = mapValue(attributes, 'hrlen', defaultValue: '58');

        if (printerName == 'POS-80C' ||
            printerName == 'GP-C80250 Series' ||
            printerName == 'GP-C80250') {
          if (font == 'A') {
            variableMaxLength = 48;
            hrlength = '48';
          } else {
            variableMaxLength = 64;
            hrlength = '64';
          }
        } else if (printerName == 'EPSON TM-T88V Receipt' ||
            printerName == 'EPSON TM-T88V Receipt5') {
          if (font == 'A') {
            variableMaxLength = 42;
            hrlength = '42';
          } else {
            variableMaxLength = 56;
            hrlength = '56';
          }
        } else if (printerName == 'Posiflex PP9000 Printer') {
          if (font == 'A') {
            variableMaxLength = 42;
            hrlength = '42';
          } else {
            variableMaxLength = 42;
            hrlength = '42';
          }
        } else {
          if (font == 'A') {
            variableMaxLength = POSConfig.font_a_length;
            hrlength = POSConfig.font_a_length.toString();
          } else {
            variableMaxLength = POSConfig.font_b_length;
            hrlength = POSConfig.font_b_length.toString();
          }
        }

        if (align == 'right') {
          alignment = PosAlign.right;
        } else if (align == 'center') {
          alignment = PosAlign.center;
        } else {
          alignment = PosAlign.left;
        }

        if (node.name.local == "feed") {
          bytes += generator.feed(int.parse(value));
        }

        if (node.name.local == "hr") {
          bytes += generator.hr();
        }
        if (node.name.local == "text") {
          // we can either pass direct string or regExp
          value = value.replaceAll("{setupAdd1}", "$setupAdd1");
          value = value.replaceAll("{setupAdd2}", "$setupAdd2");
          value = value.replaceAll("{setupAdd1}", "$setupAdd1");
          value = value.replaceAll("{type}", "$slipType");
          value = value.replaceAll(
              "{cashierId}", addSpacesBack("${userHed?.uSERHEDUSERCODE}", 26));
          value = value.replaceAll(
              "{cashier}", addSpacesBack("${userHed?.uSERHEDTITLE}", 26));
          value = value.replaceAll(
              "{station}", addSpacesBack("${userHed?.uSERHEDSTATIONID}", 26));
          value = value.replaceAll(
              "{shift}", addSpacesBack("${userHed?.shiftNo}", 26));
          // value = value.replaceAll("{signOnDate}", "$signOnDate");
          // value = value.replaceAll("{signOffDate}", "$signOffDate");
          value = value.replaceAll("{signDateType}",
              slipType == 'SIGN OFF' ? 'Sign-Off Date' : 'Sign-On Date');
          // value = value.replaceAll("{signDate}",
          //     slipType == 'SIGN OFF' ? '$signOffDate' : '$signOnDate');
          value = value.replaceAll("{signDate}", today);
          value = value.replaceAll("{locationName}",
              addSpacesBack(POSConfig().setupLocationName, 26));
          bytes += generator.text(value,
              styles: PosStyles(
                  align: alignment,
                  bold: bold == 'true',
                  fontType: font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                  height: height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                  width: width == '1' ? PosTextSize.size1 : PosTextSize.size2));
        }
        if (node.name.local == "row") {
          List<xml.XmlNode> rowchildNodes = node.children;
          await writeSignBytes(childNodes: rowchildNodes, type: type);
          bytes += generator.row(posColList);
          posColList.clear();
        }
        if (node.name.local == "col") {
          value = value.replaceAll("{setupAdd1}", "$setupAdd1");
          value = value.replaceAll("{setupAdd2}", "$setupAdd2");
          value = value.replaceAll("{setupAdd1}", "$setupAdd1");
          value = value.replaceAll("{type}", "$slipType");
          value =
              value.replaceAll("{cashierId}", "${userHed?.uSERHEDUSERCODE}");
          value = value.replaceAll("{cashier}", "${userHed?.uSERHEDTITLE}");
          value = value.replaceAll("{station}", "${userHed?.uSERHEDSTATIONID}");
          value = value.replaceAll("{shift}", "${userHed?.shiftNo}");
          // value = value.replaceAll("{signOnDate}", "$signOnDate");
          // value = value.replaceAll("{signOffDate}", "$signOffDate");
          value = value.replaceAll("{signDateType}",
              slipType == 'SIGN OFF' ? 'Sign-Off Date' : 'Sign-On Date');
          value = value.replaceAll("{signDate}", today);
          value =
              value.replaceAll("{locationName}", POSConfig().setupLocationName);
          if (value.isNotEmpty) {
            posColList.add(PosColumn(
                text: value,
                textEncoded: null,
                width: int.parse(rowlength),
                styles: PosStyles(
                    align: alignment,
                    bold: bold == 'true',
                    fontType:
                        font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                    height:
                        height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                    width:
                        width == '1' ? PosTextSize.size1 : PosTextSize.size2)));
          }
        }
        if (node.name.local == "float" && slipType == "SIGN ON") {
          bytes += generator.feed(2);
          bytes += generator.row([
            PosColumn(
                text: value,
                textEncoded: null,
                width: 4,
                styles: PosStyles(
                    align: alignment,
                    bold: bold == 'true',
                    fontType:
                        font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                    height:
                        height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                    width:
                        width == '1' ? PosTextSize.size1 : PosTextSize.size2)),
            PosColumn(
                text: (float ?? 0).toStringAsFixed(2),
                textEncoded: null,
                width: 8,
                styles: PosStyles(
                    align: alignment,
                    bold: bold == 'true',
                    fontType:
                        font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                    height:
                        height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                    width:
                        width == '1' ? PosTextSize.size1 : PosTextSize.size2))
          ]);
        }
      }
    }
    await LogWriter().saveLogsToFile(
        'ERROR_LOG_', ['Printing Lines :' + childNodes.toString()]);
  }

  Future<void> writeMngSignBytes(
      {required List<xml.XmlNode> childNodes,
      required List<POSDenominationDetail> cshdeno,
      required List<POSDenominationModel> denos}) async {
    for (int i = 1; i < childNodes.length; i += 2) {
      print(childNodes[i].toString());
      var node = childNodes[i];
      if (node is xml.XmlElement) {
        var attributes = node.attributes;
        String label = mapValue(attributes, 'label');
        String value = mapValue(attributes, 'value');
        String align = mapValue(attributes, 'align', defaultValue: 'left');
        String font = mapValue(attributes, 'font', defaultValue: 'A');
        String bold = mapValue(attributes, 'bold', defaultValue: 'false');
        String height = mapValue(attributes, 'height', defaultValue: '1');
        String width = mapValue(attributes, 'width', defaultValue: '1');
        String rowlength = mapValue(attributes, 'len', defaultValue: '12');
        String hrlength = mapValue(attributes, 'hrlen', defaultValue: '58');

        if (printerName == 'POS-80C' ||
            printerName == 'GP-C80250 Series' ||
            printerName == 'GP-C80250') {
          if (font == 'A') {
            variableMaxLength = 48;
            hrlength = '48';
          } else {
            variableMaxLength = 64;
            hrlength = '64';
          }
        } else if (printerName == 'EPSON TM-T88V Receipt' ||
            printerName == 'EPSON TM-T88V Receipt5') {
          if (font == 'A') {
            variableMaxLength = 42;
            hrlength = '42';
          } else {
            variableMaxLength = 56;
            hrlength = '56';
          }
        } else if (printerName == 'Posiflex PP9000 Printer') {
          if (font == 'A') {
            variableMaxLength = 42;
            hrlength = '42';
          } else {
            variableMaxLength = 42;
            hrlength = '42';
          }
        } else {
          if (font == 'A') {
            variableMaxLength = POSConfig.font_a_length;
            hrlength = POSConfig.font_a_length.toString();
          } else {
            variableMaxLength = POSConfig.font_b_length;
            hrlength = POSConfig.font_b_length.toString();
          }
        }

        if (align == 'right') {
          alignment = PosAlign.right;
        } else if (align == 'center') {
          alignment = PosAlign.center;
        } else {
          alignment = PosAlign.left;
        }

        if (node.name.local == "feed") {
          bytes += generator.feed(int.parse(value));
        }

        if (node.name.local == "hr") {
          bytes += generator.hr(len: font == 'A' ? hrlength.toInt() : 56);
        }

        if (node.name.local == "text") {
          value = value.replaceAll(
              "{mng_signOffUser}", addSpacesBack(mng_signOffUser, 20));
          value = value.replaceAll(
              "{mng_signOffDate}", addSpacesBack(mng_signOffDate, 20));
          value = value.replaceAll(
              "{mng_signOffTime}", addSpacesBack(mng_signOffTime, 20));
          value = value.replaceAll(
              "{mng_location}", addSpacesBack(mng_location, 20));
          value = value.replaceAll(
              "{mng_printedOn}", addSpacesBack(mng_printedOn, 20));
          value = value.replaceAll(
              "{mng_printedUser}", addSpacesBack(mng_printedUser, 20));
          value =
              value.replaceAll("{mng_station}", addSpacesBack(mng_station, 20));
          value = value.replaceAll(
              "{mng_shift}", addSpacesBack(mng_shift.toStringAsFixed(0), 20));
          value = value.replaceAll(
              "{mng_startInv}", addSpacesBack(mng_startInv, 20));
          value =
              value.replaceAll("{mng_endInv}", addSpacesBack(mng_endInv, 20));
          value = value.replaceAll("{mng_invCount}",
              addSpacesBack(mng_invCount.toStringAsFixed(0), 20));
          value = value.replaceAll("{mng_cancelInvCount}",
              addSpacesBack(mng_cancelInvCount.toStringAsFixed(0), 20));
          value = value.replaceAll("{mng_refundAmt}",
              addSpacesBack(formatWithCommas(mng_refundAmt), 20));
          value = value.replaceAll("{mng_totDiscount}",
              addSpacesBack(formatWithCommas(mng_totDiscount), 20));
          value = value.replaceAll("{mng_holdBills}",
              addSpacesBack(formatWithCommas(mng_holdBills), 20));
          value = value.replaceAll(
              "{mng_netAmt}", addSpacesBack(formatWithCommas(mng_netAmt), 20));

          value = value.replaceAll("{mng_openingBalance}",
              addSpacesBack("${formatWithCommas(mng_openingBalance)}", 20));
          value = value.replaceAll("{mng_totCashSales}",
              addSpacesBack("${formatWithCommas(mng_totCashSales)}", 20));
          value = value.replaceAll("{mng_withdrawals}",
              addSpacesBack("${formatWithCommas(mng_withdrawals)}", 20));
          value = value.replaceAll("{mng_reciepts}",
              addSpacesBack("${formatWithCommas(mng_reciepts)}", 20));
          value = value.replaceAll("{mng_calcCashAmt}",
              addSpacesBack("${formatWithCommas(mng_calcCashAmt)}", 17));
          value = value.replaceAll("{mng_cshPhysical}",
              addSpacesBack("${formatWithCommas(mng_cshPhysical)}", 17));
          value = value.replaceAll("{mng_cshVariance}",
              addSpacesBack("${formatWithCommas(mng_cshVariance)}", 17));
          value = value.replaceAll(
              "{csh_deno_desc}", addSpacesBack("$cashDenominationDesc", 17));
          value = value.replaceAll(
              "{csh_deno_count}", addSpacesBack("$deno_count", 9));
          value = value.replaceAll(
              "{csh_deno_amt}",
              addSpacesFront("${formatWithCommas(deno_multiply_amt)}",
                  variableMaxLength - 27));
          value = value.replaceAll(
              "{tot_csh_declaration}",
              addSpacesFront("${formatWithCommas(tot_csh_declaration)}",
                  variableMaxLength - 25));
          if (font == 'B') {
            value = value.replaceAll("{sod_payType}",
                addSpacesBack("$sod_payType", variableMaxLength - 43));
            value = value.replaceAll("{sod_sysAmt}",
                addSpacesFront("${formatWithCommas(sod_sysAmt)}", 14));
            value = value.replaceAll("{sod_phyAmt}",
                addSpacesFront("${formatWithCommas(sod_phyAmt)}", 14));
            value = value.replaceAll("{sod_variance}",
                addSpacesFront("${formatWithCommas(sod_variance)}", 15));
          }

          if (label == 'manual_hr') {
            value = '-' * variableMaxLength;
          }

          bytes += generator.text(value,
              styles: PosStyles(
                  align: alignment,
                  bold: bold == 'true',
                  fontType: font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                  height: height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                  width: width == '1' ? PosTextSize.size1 : PosTextSize.size2));
        }
        if (node.name.local == "row") {
          List<xml.XmlNode> rowchildNodes = node.children;
          await writeMngSignBytes(
              childNodes: rowchildNodes, cshdeno: cshdeno, denos: denos);
          bytes += generator.row(posColList);
          posColList.clear();
        }
        if (node.name.local == "col") {
          value = value.replaceAll(
              "{mng_signOffUser}", addSpacesBack(mng_signOffUser, 20));
          value = value.replaceAll(
              "{mng_signOffDate}", addSpacesBack(mng_signOffDate, 20));
          value = value.replaceAll(
              "{mng_signOffTime}", addSpacesBack(mng_signOffTime, 20));
          value = value.replaceAll(
              "{mng_location}", addSpacesBack(mng_location, 20));
          value = value.replaceAll(
              "{mng_printedOn}", addSpacesBack(mng_printedOn, 20));
          value = value.replaceAll(
              "{mng_printedUser}", addSpacesBack(mng_printedUser, 20));
          value =
              value.replaceAll("{mng_station}", addSpacesBack(mng_station, 20));
          value = value.replaceAll(
              "{mng_shift}", addSpacesBack(mng_shift.toStringAsFixed(0), 20));
          value = value.replaceAll(
              "{mng_startInv}", addSpacesBack(mng_startInv, 20));
          value =
              value.replaceAll("{mng_endInv}", addSpacesBack(mng_endInv, 20));
          value = value.replaceAll("{mng_invCount}",
              addSpacesBack(mng_invCount.toStringAsFixed(0), 20));
          value = value.replaceAll("{mng_cancelInvCount}",
              addSpacesBack(mng_cancelInvCount.toStringAsFixed(0), 20));
          value = value.replaceAll("{mng_refundAmt}",
              addSpacesBack(formatWithCommas(mng_refundAmt), 20));
          value = value.replaceAll("{mng_totDiscount}",
              addSpacesBack(formatWithCommas(mng_totDiscount), 20));
          value = value.replaceAll("{mng_holdBills}",
              addSpacesBack(formatWithCommas(mng_holdBills), 20));
          value = value.replaceAll(
              "{mng_netAmt}", addSpacesBack(formatWithCommas(mng_netAmt), 20));

          value = value.replaceAll("{mng_openingBalance}",
              addSpacesBack("${formatWithCommas(mng_openingBalance)}", 20));
          value = value.replaceAll("{mng_totCashSales}",
              addSpacesBack("${formatWithCommas(mng_totCashSales)}", 20));
          value = value.replaceAll("{mng_withdrawals}",
              addSpacesBack("${formatWithCommas(mng_withdrawals)}", 20));
          value = value.replaceAll("{mng_reciepts}",
              addSpacesBack("${formatWithCommas(mng_reciepts)}", 20));
          value = value.replaceAll("{mng_calcCashAmt}",
              addSpacesBack("${formatWithCommas(mng_calcCashAmt)}", 17));
          value = value.replaceAll("{mng_cshPhysical}",
              addSpacesBack("${formatWithCommas(mng_cshPhysical)}", 17));
          value = value.replaceAll("{mng_cshVariance}",
              addSpacesBack("${formatWithCommas(mng_cshVariance)}", 17));
          value = value.replaceAll(
              "{csh_deno_desc}", addSpacesBack("$cashDenominationDesc", 15));
          value = value.replaceAll(
              "{csh_deno_count}", addSpacesBack("$deno_count", 9));
          value = value.replaceAll("{csh_deno_amt}",
              addSpacesFront("${formatWithCommas(deno_multiply_amt)}", 33));
          value = value.replaceAll("{tot_csh_declaration}",
              addSpacesFront("${formatWithCommas(tot_csh_declaration)}", 17));
          value = value.replaceAll(
              "{sod_payType}", addSpacesBack("$sod_payType", 15));
          value = value.replaceAll("{sod_sysAmt}",
              addSpacesFront("${formatWithCommas(sod_sysAmt)}", 15));
          value = value.replaceAll("{sod_phyAmt}",
              addSpacesFront("${formatWithCommas(sod_phyAmt)}", 15));
          value = value.replaceAll("{sod_variance}",
              addSpacesFront("${formatWithCommas(sod_variance)}", 13));
          if (value.isNotEmpty) {
            posColList.add(PosColumn(
                text: value,
                textEncoded: null,
                width: int.parse(rowlength),
                styles: PosStyles(
                    align: alignment,
                    bold: bold == 'true',
                    fontType:
                        font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                    height:
                        height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                    width:
                        width == '1' ? PosTextSize.size1 : PosTextSize.size2)));
          }
        }
        if (node.name.local == "denomination") {
          List<xml.XmlNode> denominationchildNodes = node.children;
          if (cshdeno.length != 0) {
            for (int j = 0; j < cshdeno.length; j++) {
              cashDenominationDesc = cshdeno[j].value.toStringAsFixed(0);
              deno_count = cshdeno[j].count;
              deno_value = cshdeno[j].value;
              deno_multiply_amt = deno_count * deno_value;
              tot_csh_declaration += deno_multiply_amt;

              await writeMngSignBytes(
                  childNodes: denominationchildNodes,
                  cshdeno: cshdeno,
                  denos: denos);
            }
          }
        }
        if (node.name.local == "payment") {
          List<xml.XmlNode> paymentchildNodes = node.children;
          if (signoffPayDetails.length != 0) {
            for (int j = 0; j < signoffPayDetails.length; j++) {
              sod_payType = signoffPayDetails[j]['PH_DESC'];
              sod_sysAmt = signoffPayDetails[j]['SOD_SYSAMT'] ?? 0;
              sod_phyAmt = signoffPayDetails[j]['SOD_PHYAMT'] ?? 0;
              sod_variance = signoffPayDetails[j]['SOD_VARAMT'];

              await writeMngSignBytes(
                  childNodes: paymentchildNodes,
                  cshdeno: cshdeno,
                  denos: denos);
            }
          }
        }
      }
    }
    await LogWriter().saveLogsToFile(
        'ERROR_LOG_', ['Printing Lines :' + childNodes.toString()]);
  }

  Future<void> writeReceiptBytes(
      {required List<xml.XmlNode> childNodes,
      required String type,
      required String runNo,
      required bool isAdvance,
      double? receiptAmount}) async {
    String mode =
        type.toLowerCase() == 'wit' ? '<< WITHDRAWAL >>' : '<< RECEIPT >>';
    var userHed = userBloc.currentUser;
    String today = DateFormat.yMEd().add_jms().format(DateTime.now());
    num amt = receiptAmount ?? 0;
    for (int i = 1; i < childNodes.length; i += 2) {
      print(childNodes[i].toString());
      var node = childNodes[i];
      if (node is xml.XmlElement) {
        var attributes = node.attributes;
        String label = mapValue(attributes, 'label');
        String value = mapValue(attributes, 'value');
        String align = mapValue(attributes, 'align', defaultValue: 'left');
        String font = mapValue(attributes, 'font', defaultValue: 'A');
        String bold = mapValue(attributes, 'bold', defaultValue: 'false');
        String height = mapValue(attributes, 'height', defaultValue: '1');
        String width = mapValue(attributes, 'width', defaultValue: '1');
        // String hr = mapValue(attributes, 'hr', defaultValue: 'false');
        // String option = mapValue(attributes, 'option', defaultValue: '-');
        // String numOfColumns = mapValue(attributes, 'colCount', defaultValue: '0');
        String rowlength = mapValue(attributes, 'len', defaultValue: '12');
        String hrlength = mapValue(attributes, 'hrlen', defaultValue: '48');

        if (printerName == 'POS-80C' ||
            printerName == 'GP-C80250 Series' ||
            printerName == 'GP-C80250') {
          if (font == 'A') {
            variableMaxLength = 48;
            hrlength = '48';
          } else {
            variableMaxLength = 64;
            hrlength = '64';
          }
        } else if (printerName == 'EPSON TM-T88V Receipt' ||
            printerName == 'EPSON TM-T88V Receipt5') {
          if (font == 'A') {
            variableMaxLength = 42;
            hrlength = '42';
          } else {
            variableMaxLength = 56;
            hrlength = '56';
          }
        } else if (printerName == 'Posiflex PP9000 Printer') {
          if (font == 'A') {
            variableMaxLength = 42;
            hrlength = '42';
          } else {
            variableMaxLength = 42;
            hrlength = '42';
          }
        } else {
          if (font == 'A') {
            variableMaxLength = POSConfig.font_a_length;
            hrlength = POSConfig.font_a_length.toString();
          } else {
            variableMaxLength = POSConfig.font_b_length;
            hrlength = POSConfig.font_b_length.toString();
          }
        }

        if (align == 'right') {
          alignment = PosAlign.right;
        } else if (align == 'center') {
          alignment = PosAlign.center;
        } else {
          alignment = PosAlign.left;
        }

        if (isAdvance == false && label == 'advancePaymentContent') {
          continue;
        }

        if (node.name.local == "feed") {
          bytes += generator.feed(int.parse(value));
        }

        if (node.name.local == "hr") {
          bytes += generator.hr();
        }
        if (node.name.local == "barcode") {
          // bytes += generator.barcode(Barcode.upcA(invNo.split("")),
          //     width: int.tryParse(width), height: int.tryParse(height));
          List prefixData = ['{', 'A'];
          prefixData.addAll(runNo.split(""));

          bytes += generator.barcode(Barcode.code128(prefixData),
              width: int.tryParse(width), height: int.tryParse(height));
        }
        if (node.name.local == "logo") {
          // Printing image-block
          try {
            File data = File("${POSConfig.localPrintPath}/$value");
            Uint8List bytes1 = data.readAsBytesSync();
            Image image = decodeImage(
              bytes1,
            )!;
            final resized =
                copyResize(image, width: width.toInt(), height: height.toInt());
            // Using `GS v0`
            bytes += generator.imageRaster(
              resized,
            );
          } catch (e) {
            print(e);
          }
        }
        if (node.name.local == "text") {
          // we can either pass direct string or regExp
          value = value.replaceAll("{location}", POSConfig().setupLocationName);
          value = value.replaceAll("{address}", '$address');
          value = value.replaceAll("{mode}", "$mode");
          value = value.replaceAll(
              "{runNo}", addSpacesBack("$runNo", variableMaxLength - 13));
          value = value.replaceAll(
              "{cashier}",
              addSpacesBack(
                  "${userHed?.uSERHEDTITLE}", variableMaxLength - 13));
          value = value.replaceAll(
              "{station}",
              addSpacesBack(
                  "${userHed?.uSERHEDSTATIONID}", variableMaxLength - 13));
          value = value.replaceAll(
              "{date}", addSpacesBack(today, variableMaxLength - 13));
          value = value.replaceAll(
              "{rw_desc}", addSpacesBack("$rwDescription", variableMaxLength));
          value = value.replaceAll(
              "{amount}",
              (addSpacesBack(
                  "${formatWithCommas(amt)}", variableMaxLength - 13)));
          value = value.replaceAll("{remark}",
              addSpacesBack("$receipt_remark", variableMaxLength - 13));
          value = value.replaceAll("{payMode}",
              addSpacesBack("$payment_desc", variableMaxLength - 21));
          value = value.replaceAll("{refCode}",
              (addSpacesBack("$payment_refCode", variableMaxLength - 21)));

          bytes += generator.text(value,
              styles: PosStyles(
                  align: alignment,
                  bold: bold == 'true',
                  fontType: font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                  height: height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                  width: width == '1' ? PosTextSize.size1 : PosTextSize.size2));
        }
      }
    }
    await LogWriter().saveLogsToFile(
        'ERROR_LOG_', ['Printing Lines :' + childNodes.toString()]);
  }

  Future<void> writeTicketBytes({required List<xml.XmlNode> childNodes}) async {
    for (int i = 1; i < childNodes.length; i += 2) {
      print(childNodes[i].toString());
      var node = childNodes[i];
      if (node is xml.XmlElement) {
        var attributes = node.attributes;
        String label = mapValue(attributes, 'label');
        String value = mapValue(attributes, 'value');
        String align = mapValue(attributes, 'align', defaultValue: 'left');
        String font = mapValue(attributes, 'font', defaultValue: 'A');
        String bold = mapValue(attributes, 'bold', defaultValue: 'false');
        String height = mapValue(attributes, 'height', defaultValue: '1');
        String width = mapValue(attributes, 'width', defaultValue: '1');
        // String hr = mapValue(attributes, 'hr', defaultValue: 'false');
        // String option = mapValue(attributes, 'option', defaultValue: '-');
        // String numOfColumns = mapValue(attributes, 'colCount', defaultValue: '0');
        String rowlength = mapValue(attributes, 'len', defaultValue: '12');
        bool underline = false;

        if (align == 'right') {
          alignment = PosAlign.right;
        } else if (align == 'center') {
          alignment = PosAlign.center;
        } else {
          alignment = PosAlign.left;
        }

        if (node.name.local == "logo") {
          // Printing image-block
          try {
            File data = File("${POSConfig.localPrintPath}/$value");
            Uint8List bytes1 = data.readAsBytesSync();
            Image image = decodeImage(
              bytes1,
            )!;
            final resized =
                copyResize(image, width: width.toInt(), height: height.toInt());
            // Using `GS v0`
            bytes += generator.imageRaster(
              resized,
            );
          } catch (e) {
            print(e);
          }
        }
        if (node.name.local == "feed") {
          bytes += generator.feed(int.parse(value));
        }

        if (node.name.local == "hr") {
          bytes += generator.hr();
        }
        if (node.name.local == "text") {
          value = value.replaceAll("{address}", '$address');
          value = value.replaceAll("{email}", '$email');
          value = value.replaceAll("{number}", '$phone');
          value = value.replaceAll("{ticketDesc}", "$ticketLineContent");
          value = value.replaceAll("{location}", "$loc_desc");
          if (label == 'ticket_description') {
            bold =
                (currentTicketLineDescsMap['IS_BOLD'] == 1) ? 'true' : 'false';
            underline = currentTicketLineDescsMap['IS_UNDERLINE'] == 1;
          }
          bytes += generator.text(value,
              styles: PosStyles(
                  align: alignment,
                  bold: bold == 'true',
                  underline: underline,
                  fontType: font == 'A' ? PosFontType.fontA : PosFontType.fontB,
                  height: height == '1' ? PosTextSize.size1 : PosTextSize.size2,
                  width: width == '1' ? PosTextSize.size1 : PosTextSize.size2));
        }
        if (node.name.local == "barcode" && serial != '') {
          // bytes += generator.barcode(Barcode.upcA(invNo.split("")),
          //     width: int.tryParse(width), height: int.tryParse(height));
          List prefixData = ['{', 'A'];
          prefixData.addAll(serial.split(""));
          bytes += generator.barcode(Barcode.code128(prefixData),
              width: int.tryParse(width), height: int.tryParse(height));
        }
        if (node.name.local == "ticketDescriptions") {
          List<xml.XmlNode> ticketDescriptionschildNodes = node.children;
          promoTicketHeadGroupedData.forEach((key, value) {
            if (key == currentPromoTicket['PROMO_TICKETID']) {
              ticketLineDescsList.clear();
              ticketLineDescsList.addAll(value);
            }
          });
          if (ticketLineDescsList.isNotEmpty) {
            for (int d = 0; d < ticketLineDescsList.length; d++) {
              currentTicketLineDescsMap = ticketLineDescsList[d];
              ticketLineContent = currentTicketLineDescsMap['LINE_CONTENT'];
              ticketLineContent =
                  ticketLineContent.replaceAll('@serial', serial);
              ticketLineContent.replaceAll(
                  '@value', ticketValue.toStringAsFixed(2));
              await writeTicketBytes(childNodes: ticketDescriptionschildNodes);
            }
          }
        }
      }
    }
    await LogWriter().saveLogsToFile(
        'ERROR_LOG_', ['Printing Lines :' + childNodes.toString()]);
  }

  String formatWithCommas(num value) {
    String stringValue = value.toStringAsFixed(2);
    // Split into two parts: integer part and decimal part
    List<String> parts = stringValue.split('.');
    // Format the integer part with thousand separators (`,`)
    String formattedValue = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
    // Combine the integer part with the decimal part (if exists)
    if (parts.length > 1) {
      formattedValue += '.' + parts[1];
    }
    return formattedValue;
  }

  String mapValue(List<xml.XmlAttribute> attributes, String attributeName,
      {String defaultValue = ''}) {
    return attributes
            .where((attribute) => attribute.name.local == attributeName)
            .map((attribute) => attribute.value)
            .firstOrNull ??
        defaultValue;
  }

  String addSpacesFront(String inputString, int desiredLength) {
    if (inputString.length == desiredLength) {
      return inputString;
    } else if (inputString.length < desiredLength) {
      int spacesToAdd = desiredLength - inputString.length;
      String spaces = ' ' * spacesToAdd;
      return '$spaces$inputString';
    } else {
      // Handle the case where the inputString is longer than the desiredLength, if needed.
      // You may want to truncate the string or handle it in a way that fits your use case.
      return inputString;
    }
  }

  String addSpacesBack(String inputString, int desiredLength) {
    if (inputString.length == desiredLength) {
      return inputString;
    } else if (inputString.length < desiredLength) {
      int spacesToAdd = desiredLength - inputString.length;
      String spaces = ' ' * spacesToAdd;
      return '$inputString$spaces';
    } else {
      int truncatedLength = desiredLength - 3;
      String truncatedString = inputString.substring(0, truncatedLength);
      return '$truncatedString...';
    }
  }

  String formatQuantity(num qt) {
    if (qt % 1 == 0) {
      // If qt is a whole number, return its integer part
      return qt.toInt().toString();
    } else {
      // If qt has decimal places, return it with up to 3 decimal places
      return qt
          .toStringAsFixed(3)
          .replaceAll(RegExp(r'0{1,3}$'), ''); // Remove trailing zeros
    }
  }

  Future openDrawer() async {
    printerName = POSConfig.printerName;
    var profile = await CapabilityProfile.load(name: 'default');
    generator = Generator(PaperSize.mm80, profile);
    bytes = generator.drawer();
    // Sending esc commands to printer
    final sendToPrint = await usb_esc_printer_windows.sendPrintRequest(
        bytes, printerName); //[POS-80C,EPSON TM-T88V Receipt]
  }
}
