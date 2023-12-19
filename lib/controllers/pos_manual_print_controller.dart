/// Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
/// Author: [TM.SAKIR]
/// Created At: 2023-12-18 2.30PM.
/// Trying to generate printouts from pos

import 'dart:io';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:usb_esc_printer_windows/usb_esc_printer_windows.dart'
    as usb_esc_printer_windows;

class POSManualPrint {
  var center = PosAlign.center;

  Future<void> printInvoice({String? data}) async {
    final profile = await CapabilityProfile.load(name: 'default');
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Printing image-block
    // try {
    //   ByteData data =
    //       await rootBundle.load('assets/images/logo_with_powered.png');
    //   Uint8List bytes1 = data.buffer.asUint8List();
    //   Image image = decodeImage(
    //     bytes1,
    //   )!;
    //   // Using `GS v0`
    //   bytes += generator.imageRaster(image);
    // } catch (e) {
    //   print(e);
    // }

    // Printing header-block
    bytes += generator.text('LIBERTY PLAZA',
        styles: PosStyles(
            align: center,
            bold: true,
            fontType: PosFontType.fontB,
            height: PosTextSize.size1,
            width: PosTextSize.size2));
    bytes += generator.feed(1);
    bytes += generator.text('1-33, 1st Floor, Liberty Plaza, Colombo 03',
        styles: PosStyles(align: center, fontType: PosFontType.fontA));
    bytes += generator.text('info@bestrends.lk',
        styles: PosStyles(align: center, fontType: PosFontType.fontA));
    bytes += generator.text('www.Bestrends.lk',
        styles: PosStyles(align: center, fontType: PosFontType.fontA));
    bytes += generator.text('Phone: 0112285333',
        styles: PosStyles(align: center, fontType: PosFontType.fontA));

    // Date&Time, Inv No - block
    bytes += generator.hr();
    bytes += generator.text('Date & Time :  13/12/2023  5:30PM',
        styles: PosStyles(fontType: PosFontType.fontA));
    bytes += generator.text('Invoice No  :  010103000096',
        styles: PosStyles(fontType: PosFontType.fontA));
    bytes += generator.hr();

    // Product list - block
    bytes += generator.text('INVOICE',
        styles: PosStyles(
            align: center,
            bold: true,
            fontType: PosFontType.fontB,
            height: PosTextSize.size2,
            width: PosTextSize.size2));
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
        text: 'PRODUCT',
        textEncoded: null,
        width: 3,
        styles: PosStyles(
            align: PosAlign.left, bold: true, width: PosTextSize.size2),
      ),
      PosColumn(
        text: 'PRICE',
        textEncoded: null,
        width: 3,
        styles: PosStyles(
            align: PosAlign.left, bold: true, width: PosTextSize.size2),
      ),
      PosColumn(
        text: 'QTY',
        textEncoded: null,
        width: 2,
        styles: PosStyles(
            align: PosAlign.left, bold: true, width: PosTextSize.size2),
      ),
      PosColumn(
        text: 'AMOUNT',
        textEncoded: null,
        width: 4,
        styles: PosStyles(
            align: PosAlign.right, bold: true, width: PosTextSize.size2),
      )
    ]);
    bytes += generator.hr();
    for (int i = 1; i < 3; i++) {
      try {
        bytes += generator.text('${i.toString()}  Test 123 Crystal white EU 40',
            styles: PosStyles(fontType: PosFontType.fontA));
        // bytes += generator
        //     .text('00000020105         11,000.00       10        110,000.00');
        bytes += generator.row([
          PosColumn(
            text: '00000020105',
            textEncoded: null,
            width: 3,
            styles:
                PosStyles(align: PosAlign.left, fontType: PosFontType.fontB),
          ),
          PosColumn(
            text: '100,000.00',
            textEncoded: null,
            width: 3,
            styles:
                PosStyles(align: PosAlign.left, fontType: PosFontType.fontB),
          ),
          PosColumn(
            text: '10000',
            textEncoded: null,
            width: 2,
            styles:
                PosStyles(align: PosAlign.left, fontType: PosFontType.fontB),
          ),
          PosColumn(
            text: '1,000,000.00',
            textEncoded: null,
            width: 4,
            styles:
                PosStyles(align: PosAlign.right, fontType: PosFontType.fontB),
          )
        ]);
      } catch (e) {
        print(e);
      }
    }
    bytes += generator.hr();

    // Gross amount - block
    bytes += generator.row([
      PosColumn(
        text: 'GROSS AMOUNT',
        textEncoded: null,
        width: 7,
        styles: PosStyles(
            align: PosAlign.left, fontType: PosFontType.fontA, bold: true),
      ),
      PosColumn(
        text: '33,000.00',
        textEncoded: null,
        width: 5,
        styles: PosStyles(
            align: PosAlign.right, fontType: PosFontType.fontA, bold: true),
      )
    ]);
    bytes += generator.text('-22,000.00',
        styles: PosStyles(
            align: PosAlign.right, fontType: PosFontType.fontA, bold: true));
    bytes += generator.hr();

    // Net amount - block
    bytes += generator.row([
      PosColumn(
        text: 'NET AMOUNT',
        textEncoded: null,
        width: 7,
        styles: PosStyles(
            align: PosAlign.left,
            fontType: PosFontType.fontA,
            bold: true,
            width: PosTextSize.size2),
      ),
      PosColumn(
        text: '11,000.00',
        textEncoded: null,
        width: 5,
        styles: PosStyles(
            align: PosAlign.right,
            fontType: PosFontType.fontB,
            bold: true,
            width: PosTextSize.size2),
      )
    ]);
    bytes += generator.hr();

    // Payment methods - block
    for (int i = 1; i < 3; i++) {
      bytes += generator.row([
        PosColumn(
          text: 'Cash',
          textEncoded: null,
          width: 6,
          styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontB),
        ),
        PosColumn(
          text: '11,000.00',
          textEncoded: null,
          width: 6,
          styles: PosStyles(align: PosAlign.right, fontType: PosFontType.fontB),
        )
      ]);
    }
    bytes += generator.hr();

    // No. of items & quantity - block
    bytes += generator.row([
      PosColumn(
        text: 'NUMBER OF ITEMS :',
        textEncoded: null,
        width: 7,
        styles: PosStyles(
            align: PosAlign.left, fontType: PosFontType.fontA, bold: true),
      ),
      PosColumn(
        text: '1',
        textEncoded: null,
        width: 5,
        styles: PosStyles(
            align: PosAlign.center, fontType: PosFontType.fontA, bold: true),
      )
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL QUANTITY :',
        textEncoded: null,
        width: 7,
        styles: PosStyles(
            align: PosAlign.left, fontType: PosFontType.fontA, bold: true),
      ),
      PosColumn(
        text: '1',
        textEncoded: null,
        width: 5,
        styles: PosStyles(
            align: PosAlign.center, fontType: PosFontType.fontA, bold: true),
      )
    ]);
    bytes += generator.hr();

    // Cashier, Terminal & Time
    bytes += generator.row([
      PosColumn(
        text: 'Cashier   :  ADMIN',
        textEncoded: null,
        width: 6,
        styles: PosStyles(
            align: PosAlign.left, fontType: PosFontType.fontA, bold: false),
      ),
      PosColumn(
        text: 'Terminal  :  003',
        textEncoded: null,
        width: 6,
        styles: PosStyles(
            align: PosAlign.right, fontType: PosFontType.fontA, bold: false),
      )
    ]);
    bytes += generator.text('End Time  :  5:59 PM',
        styles: PosStyles(
            align: PosAlign.left, fontType: PosFontType.fontA, bold: false));
    bytes += generator.hr();

    // QR-block
    String qrData = "https://bestrends.lk/";
    try {
      bytes += generator.qrcode(qrData, size: QRSize.Size6);
    } catch (e) {
      print(e);
    }
    bytes += generator.text('Thank you ${''}',
        styles: PosStyles(
            align: PosAlign.center, fontType: PosFontType.fontB, bold: true));
    bytes += generator.feed(1);

    // Footer-block
    bytes += generator.text('www.facebook.com/Bestrends.lk',
        styles: PosStyles(
            align: PosAlign.center, fontType: PosFontType.fontB, bold: true));

    // Cutting the paper
    bytes += generator.cut();

    // Sending esc commands to printer
    final sendToPrint =
        await usb_esc_printer_windows.sendPrintRequest(bytes, 'POS-80C');
  }
}
