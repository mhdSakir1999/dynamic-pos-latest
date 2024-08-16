/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 5/15/21, 10:35 AM
 */

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/gift_voucher_controller.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/product_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/controllers/time_controller.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/pos/Inv_appliedPeomotons.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/gift_voucher_result.dart';
import 'package:checkout/models/pos/inv_tax.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos/pro_price.dart';
import 'package:checkout/models/pos/product_price_changes.dart';
import 'package:checkout/models/pos/product_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/invoice/open_item_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supercharged/supercharged.dart';
import '../bloc/user_bloc.dart';
import '../components/common_regex.dart';
import '../models/pos/pro_tax.dart';
import '../models/pos/promotion_free_items.dart';
import 'pos_logger_controller.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:easy_localization/easy_localization.dart';

/// This class wii handle the all calculation
class POSPriceCalculator {
  TextEditingController _refNoEditingController = TextEditingController();
  TextEditingController _multiplePriceEditingController =
      TextEditingController();
  KeyBoardController keyBoardController = KeyBoardController();
  FocusNode multiplePriceNode = FocusNode();

  // this method can handle the open items
  Future<Product?> handleOpenItem(
    Product product,
    BuildContext context, {
    bool? isOpen = true,
  }) async {
    final res = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => OpenItemView(
        product: product,
        isOpen: isOpen,
      ),
    );
    return res;
  }

  Future<CartModel?> addGv(
      GiftVoucher voucher, double qty, BuildContext context,
      {bool permission = true}) async {
    //check the permission
    if (permission) {
      String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
      String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';

      String refCode = '$invoiceNo@${user}VC${voucher.vCNO}-${voucher.vCVAlUE}';
      bool hasPermission = false;
      hasPermission = SpecialPermissionHandler(context: context).hasPermission(
          permissionCode: PermissionCode.giftVoucherSales,
          accessType: "A",
          refCode: refCode);

      //if user doesnt have the permission
      if (!hasPermission) {
        final res = await SpecialPermissionHandler(context: context)
            .askForPermission(
                permissionCode: PermissionCode.giftVoucherSales,
                accessType: "A",
                refCode: refCode);
        hasPermission = res.success;
        user = res.user;
      }
      if (!hasPermission) {
        return null;
      }
    }

    double amount = (voucher.vCVAlUE ?? 0) * qty;
    CartSummaryModel cartSummary = cartBloc.cartSummary ??
        CartSummaryModel(
            invoiceNo: "",
            items: 0,
            qty: 0,
            subTotal: 0,
            startTime: '',
            priceMode: '');

    final model = CartModel(
        setUpLocation: POSConfig().setupLocation,
        posDesc: voucher.vCDESC ?? "",
        proSelling: amount,
        noDisc: false,
        scanBarcode: "",
        proCode: voucher.vCNO ?? "",
        stockCode: "",
        selling: voucher.vCVAlUE ?? 0,
        proCaseSize: 1,
        proCost: 0,
        proAvgCost: 0,
        itemVoid: false,
        discAmt: 0,
        discPer: 0,
        billDiscPer: 0,
        unitQty: qty,
        discountReason: '',
        maxDiscAmt: 0,
        maxDiscPer: 0,
        isVoucher: true,
        amount: amount,
        lineRemark: [])
      ..dateTime = DateTime.now();

    final cartList = cartBloc.currentCart ?? {};

    int lineNo = cartList.length;
    model.lineNo = lineNo + 1;
    model.image = '';
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "New Item Added to the cart"));
    final res = await cartBloc.updateCurrentCart(model, false);

    //update cart summary
    cartSummary.subTotal += amount;
    cartSummary.qty = cartSummary.qty + 1;
    cartSummary.items = cartSummary.items + 1;

    if (res) {
      cartBloc.updateCartSummary(cartSummary);
      final controller = InvoiceController();
      controller.updateTempCartSummary(cartSummary);
    } else {
      //revert the current calculations
      cartSummary.subTotal -= amount;
      cartSummary.qty = cartSummary.qty - 1;
      cartSummary.items = cartSummary.items - 1;
      cartBloc.updateCartSummary(cartSummary);
    }
    return model; //added by PW to return the CartModel to free GV issue function
  }

  Future<void> addUtilityBill(
      String mode, String accountNo, double amount, String billType) async {
    CartSummaryModel cartSummary = cartBloc.cartSummary ??
        CartSummaryModel(
            invoiceNo: "",
            items: 0,
            qty: 0,
            subTotal: 0,
            startTime: '',
            priceMode: '',
            invMode: billType);

    final model = CartModel(
        setUpLocation: POSConfig().setupLocation,
        posDesc: mode,
        proSelling: amount,
        noDisc: true,
        scanBarcode: "",
        proCode: accountNo,
        stockCode: "",
        selling: amount,
        proCaseSize: 1,
        proCost: 0,
        proAvgCost: 0,
        itemVoid: false,
        discAmt: 0,
        discPer: 0,
        billDiscPer: 0,
        unitQty: 1,
        discountReason: '',
        maxDiscAmt: 0,
        maxDiscPer: 0,
        isVoucher: false,
        amount: amount,
        lineRemark: [])
      ..dateTime = DateTime.now();

    final cartList = cartBloc.currentCart ?? {};

    int lineNo = cartList.length;
    model.lineNo = lineNo + 1;
    model.image = '';
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "New Item Added to the cart"));
    final res = await cartBloc.updateCurrentCart(model, false);

    //update cart summary
    cartSummary.subTotal += amount;
    cartSummary.qty = cartSummary.qty + 1;
    cartSummary.items = cartSummary.items + 1;

    if (res) {
      cartBloc.updateCartSummary(cartSummary);
      final controller = InvoiceController();
      controller.updateTempCartSummary(cartSummary);
    } else {
      //revert the current calculations
      cartSummary.subTotal -= amount;
      cartSummary.qty = cartSummary.qty - 1;
      cartSummary.items = cartSummary.items - 1;
      cartBloc.updateCartSummary(cartSummary);
    }
  }

  Future<void> _qtyErrorDialog(
    BuildContext context,
  ) async {
    showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: 'qty_error.title'.tr(),
          subtitle: 'qty_error.error'.tr(),
          actions: [
            AlertDialogButton(
                onPressed: () => Navigator.pop(context),
                text: 'qty_error.okay'.tr())
          ]),
    );
  }

  //Add Items to the list (Cart)
  Future<List<CartModel?>?> addItemToCart(
      Product product,
      double qty,
      BuildContext context,
      List<ProductPriceChanges>? multiplePrices,
      List<ProPrice>? proPrices,
      List<ProTax>? proTax,
      {bool successToast = false,
      bool secondApiCall =
          true, //this is used to enable or disable the api call for multiple prices
      bool scaleBarcode = false}) async {
    if (cartBloc.cartSummary!.discPer != 0 &&
        cartBloc.cartSummary!.discPer != null) {
      EasyLoading.showError('invoice.item_block_after_net_discount'.tr());
      return null;
    }

    if (product.pLUACTIVE == false) {
      EasyLoading.showError('invoice.inactive_item'.tr());
      return null;
    }

    if (product.posActive == false) {
      EasyLoading.showError('invoice.inactive_item_for_pos'.tr());
      return null;
    }

    if (qty > (POSConfig().setup?.maxQtyLimit ?? 0) &&
        (POSConfig().setup?.maxQtyLimit ?? 0) > 0) {
      EasyLoading.showError('invoice.max_qty_limit_exceed'.tr() +
          '\n Maximum quantity can be punched is limited to ${(POSConfig().setup?.maxQtyLimit ?? 0)}');
      return null;
    }

    /* check this barcode is scale barcode */
    /* by dinuka 2022/10/19 */
    // if (scaleBarcode) {
    //   if (product.volume != null) {
    //     proPrices = null;
    //     proTax = null;
    //     secondApiCall = true;
    //     qty = qty / product.volume!;
    //   }
    // }

    //check return item validation (Item should be defined as Exchangeable in Product Master to generate refunds)
    if (qty < 0 && product.exchangable == false) {
      EasyLoading.showError('invoice.nonexchangable'.tr());
      return null;
    }

    String strPriceMode = '';
    bool blAllowLoyalty = false;
    bool blAllowDiscount = true;
    //check the quantity
    String strQty = qty.toString();
    int noOfQtyDecimalPoints = POSConfig().setup?.qtyDecimalPoints ?? 3;
    if (product.pluDecimal == true && strQty.contains('.')) {
      //check the decimal points
      String right = strQty.split('.')[1];
      if (right.length > noOfQtyDecimalPoints) {
        _qtyErrorDialog(context);
        return null;
      }
    }
    if (product.pluDecimal != true && qty % 1 != 0) {
      _qtyErrorDialog(context);
      return null;
    }

    double selling = product.sELLINGPRICE ?? 0;

    /// handle maximum qty for item
    if (product.maxVolume != null && product.maxVolume! > 0) {
      String group = product.maxVolumeGroup ?? '';
      String groupLvl = product.maxVolumeGroupLvl ?? '';
      List<CartModel> relevantProducts = [];
      double maxQty = product.maxVolume!;
      String? error;
      double currentVolume = 0;
      double vol = qty;
      if (group.isNotEmpty && groupLvl.isNotEmpty) {
        // group wise

        relevantProducts = cartBloc.currentCart?.values
                .toList()
                .where((element) =>
                        element.itemVoid != true &&
                        element.maxVolumeGroup == product.maxVolumeGroup &&
                        element.maxVolumeGroupLvl == product.maxVolumeGroupLvl
                    // && element.proUnit == product.pluUnit
                    )
                .toList() ??
            [];
        relevantProducts.forEach((element) {
          currentVolume += element.unitQty * (element.volume ?? 0);
        });
        vol = qty * (product.volume ?? 0);
        error =
            'Maximum allowed volume/qty for this product is $maxQty.(Current:$currentVolume)';
      } else {
        relevantProducts = cartBloc.currentCart?.values
                .toList()
                .where((element) =>
                    element.proCode == product.pLUCODE &&
                    element.itemVoid != true)
                .toList() ??
            [];
        relevantProducts.forEach((element) {
          currentVolume += element.unitQty;
        });
        error =
            'Maximum allowed volume/qty for this product is $maxQty.(Current:$currentVolume)';
      }

      if ((currentVolume + vol) > maxQty) {
        // EasyLoading.showError(error);
        await showDialog(
          context: context,
          builder: (context) => POSErrorAlert(
              title: 'invoice.product_max_exceed_title'.tr(),
              subtitle: 'invoice.product_max_exceed_content'.tr(namedArgs: {
                "maxQty": maxQty.toString(),
                "currentVolume": currentVolume.toString(),
                "entered": vol.toString()
              }),
              actions: <Widget>[
                AlertDialogButton(
                    onPressed: () => Navigator.pop(context),
                    text: 'invoice.product_max_exceed_okay'.tr())
              ]),
        );
        return null;
      }
    }

    // /// handle multiple prices
    // if (secondApiCall) {
    //   final secondCall = (await ProductController()
    //       .getProductsMultiplePrices(product.pLUCODE ?? '', qty.toDouble()));
    //   multiplePrices = secondCall?.price;
    //   proPrices = secondCall?.proPrice;
    //   proTax = secondCall?.proTax;
    // }

    // filter the fixed price mode if the price mode is not selected (double check)
    if ((cartBloc.cartSummary?.priceMode ?? '').isEmpty) {
      proPrices = proPrices
          ?.where((element) =>
              (element.pplUFIXPRICE ?? 0) > 0 && element.prMFIXED == true)
          .toList();
    }
    bool canPopUpMultiplePrice = true;

    //hide multiple price popup for check exchangeable item
    if (qty < 0) {
      canPopUpMultiplePrice = false;
    }

    bool fixedPriceApplied = false;

    /// going through pro price
    if (proPrices != null) {
      if (proPrices.length > 0) {
        //check fixed price
        int fixedPriceIndex =
            proPrices.indexWhere((element) => element.prMFIXED == true);
        canPopUpMultiplePrice = false;
        //if the item has a fixed price
        if (fixedPriceIndex != -1) {
          selling = proPrices[fixedPriceIndex].pplUFIXPRICE ?? 0;
          strPriceMode = proPrices[fixedPriceIndex].prMCODE ?? '';
          blAllowLoyalty = proPrices[fixedPriceIndex].allowLoyalty ?? true;
          blAllowDiscount = proPrices[fixedPriceIndex].allowDiscount ?? true;
          fixedPriceApplied = true;
        } else {
          ProPrice proPrice = proPrices.first;
          blAllowLoyalty = proPrice.allowLoyalty ?? true;
          strPriceMode = proPrice.prMCODE ?? '';
          blAllowDiscount = proPrice.allowDiscount ?? true;
          if (proPrice.pplUDISCPER != null && proPrice.pplUDISCPER != 0) {
            selling = selling - (selling * (proPrice.pplUDISCPER ?? 0) / 100.0);
            fixedPriceApplied = true;
          } else if (proPrice.pplUDISCAMT != null &&
              proPrice.pplUDISCAMT != 0) {
            selling = selling - (proPrice.pplUDISCAMT ?? 0);
            fixedPriceApplied = true;
          } else if (proPrice.pplUFIXPRICE != null &&
              proPrice.pplUFIXPRICE != 0) {
            selling = proPrice.pplUFIXPRICE ?? 0;
            fixedPriceApplied = true;
          }
        }
      }
    }

    if (multiplePrices != null && canPopUpMultiplePrice) {
      bool canPopUpMultiplePrice = true;
      //if price mode selected
      // if ((cartBloc.cartSummary?.priceMode ?? '').isNotEmpty) {
      //   // added !secondApiCall flag here, because there is no need to call the api for the 2nd time
      //   final ProPriceResults? priceRes = await ProductController()
      //       .getProductsMultiplePrices(product.pLUCODE ?? '', qty.toDouble());
      //   if (priceRes != null) {
      //     multiplePrices = priceRes.price ?? multiplePrices;
      //     //handle pro prices
      //   }
      // }

      // new change by sakir -- setting the costPrice related to selected multiplePrice
      if (multiplePrices.length > 0 && canPopUpMultiplePrice) {
        // add the current price to multiple price array
        multiplePrices.add(ProductPriceChanges(
            pRSPRICE: product.sELLINGPRICE, pRDATE: 'Current Price'));
        ProductPriceChanges? sprice;
        sprice = await multiplePriceAlert(
            context, product.sELLINGPRICE ?? 0, multiplePrices, product);
        if (sprice == null) return null;
        selling = sprice.pRSPRICE!;
        product.cost = sprice.pRCPRICE ?? product.cost;

        // product.sELLINGPRICE = sprice.pRSPRICE;
        // product.avgCost = sprice.pRCPRICE ?? product.avgCost;
      }
    }

    // check the line amount zero items
    if (product.sELLINGPRICE == 0 && product.pluOpen != true) {
      showDialog(
        context: context,
        builder: (context) => POSErrorAlert(
            title: 'invoice.zero_item_title'.tr(),
            subtitle: 'invoice.zero_item_subtitle'.tr(),
            actions: <Widget>[
              AlertDialogButton(
                  onPressed: () => Navigator.pop(context),
                  text: 'invoice.zero_item_button'.tr())
            ]),
      );
      return null;
    }
    CartSummaryModel cartSummary = cartBloc.cartSummary ??
        CartSummaryModel(
            invoiceNo: "",
            items: 0,
            qty: 0,
            subTotal: 0,
            startTime: '',
            priceMode: '');

    // check sih
    bool? allowMinusRes;
    if (product.allowMinus == false && qty > (product.sIH ?? 0)) {
      allowMinusRes =
          await allowMinusAlert(context, cartSummary.invoiceNo, product, qty);
      if (!allowMinusRes) return null;
    }

    // check the weighted item or not if this is normal item remove the double number
    if (product.pluDecimal != true && (qty % 1 != 0)) {
      qty = qty.toInt().toDouble();
    }

    // stop price edit on product return
    if (qty > 0) {
      if (product.pluOpen == true) {
        final openItemRes = await handleOpenItem(product, context);
        if (openItemRes == null)
          return null;
        else {
          product = openItemRes;
          selling = product.sELLINGPRICE ?? 0;
          qty = 1;
        }
      }

      // cashier can edit the price. But entered price will be compared with min selling price (can be bypasses with permission)
      if (product.pluOpen != true && product.allowPriceChange == true) {
        final prcChangeRes =
            await handleOpenItem(product, context, isOpen: false);
        if (prcChangeRes == null)
          return null;
        else {
          product = prcChangeRes;
          selling = product.sELLINGPRICE ?? 0;
          // qty = 1;
        }
      }
    }

    bool minus = qty < 0;
    var lineAmount = qty * selling;
    List<String> lineRemark = [];
    CartModel? returnProduct;

    List<double> lineAmounts = [];
    List<double> sellings = [];
    List<CartModel?> returnProducts = [];

    ///exchangeable item calculation
    if (!minus) {
      cartSummary.qty += qty;
    } else {
      if (product.isEmptyBottle != true) {
        SpecialPermissionHandler handler =
            SpecialPermissionHandler(context: context);
        String code = PermissionCode.salesReturn;
        String type = "A";
        bool permissionStatus =
            handler.hasPermission(permissionCode: code, accessType: type);
        if (!permissionStatus) {
          String refCode = (cartBloc.cartSummary?.invoiceNo ?? "") +
              "@" +
              (product.pLUCODE ?? "") +
              "@" +
              qty.toDouble().toString();
          bool success = (await handler.askForPermission(
                  accessType: type, permissionCode: code, refCode: refCode))
              .success;
          permissionStatus = success;
          if (!success) return null;
        }
        if (permissionStatus) {
          // get the current item return count from storage
          var returnItems = (cartBloc.currentCart?.values.map((e) {
                if (e.stockCode == product.pLUSTOCKCODE &&
                    e.itemVoid != true &&
                    e.unitQty < 0) {
                  return e.unitQty;
                } else
                  return 0.0;
              }).toList() ??
              []);
          double returnItemsQty = 0;
          if (returnItems.isNotEmpty) {
            returnItemsQty =
                returnItems.reduce((value, element) => value + element);
          }
          Map<String, dynamic> salesReturn = await _showSalesReturnDialog(
              context, product.pLUSTOCKCODE ?? '', returnItemsQty + qty, qty);

          if (salesReturn['continue'] == 'continue') {
            // var res = await showInvoice(context);
            cartSummary.refNo = salesReturn['refInvNo'];
            lineRemark.add(salesReturn['refInvNo']);
            lineAmounts = salesReturn['amounts'];
            sellings = salesReturn['sellings'];
            returnProducts = salesReturn['returnProducts']; //new change
          } else if (salesReturn['continue'] == 'continue_without_inv') {
            //check for permissions to SKIP ORIGINAL INVOICE WHEN RETURN ITEMS
            SpecialPermissionHandler handler =
                SpecialPermissionHandler(context: context);
            bool permissionStatus = handler.hasPermission(
                permissionCode: PermissionCode.skipOrgInvInTReturns,
                accessType: 'A');
            if (!permissionStatus) {
              String refCode = (cartBloc.cartSummary?.invoiceNo ?? "") +
                  "@" +
                  (product.pLUCODE ?? "") +
                  "@" +
                  qty.toDouble().toString();
              bool success = (await handler.askForPermission(
                      accessType: 'A',
                      permissionCode: PermissionCode.skipOrgInvInTReturns,
                      refCode: refCode))
                  .success;
              permissionStatus = success;
              if (!success) return null;
            }
          } else {
            return null;
          }
        }
      }
    }

    List<CartModel?>? cartedItems = [];
    if (returnProducts.length == 0 &&
        lineAmounts.length == 0 &&
        sellings.length == 0) {
      double disAmt = 0;
      double disPre = 0;

      // get current cart list
      final cartList = cartBloc.currentCart ?? {};

      //check item already in the cart or not
      //iteration through map
      final founded = cartList.values.toList().indexWhere((element) =>
          element.proCode == product.pLUCODE &&
          element.itemVoid != true &&
          element.unitQty > 0 &&
          element.stockCode == product.pLUSTOCKCODE &&
          element.selling == selling);
      bool alreadyAdded = founded != -1;

      if (!alreadyAdded && !minus) {
        cartSummary.items++;
      }
      String discReason = "";

      //TODO block item batch for disounted items/multiple price
      // if (alreadyAdded && POSConfig().cartBatchItem) {
      //   //  handle anything for already added item
      //   final item = cartList.values.toList()[founded];
      //   disAmt = item.discAmt!;
      //   disPre = item.discPer!;
      //   discReason = item.discountReason ?? "";
      //   if (disPre > 0) {
      //     lineAmount -= ((lineAmount * disPre) / 100);
      //   }
      // }

      // //new change
      // //this allows to pass the correct discount(per or amnt) for the return products
      // if (minus) {
      //   disAmt = returnProduct?.discAmt ?? 0;
      //   disPre = returnProduct?.discPer ?? 0;
      //   discReason = returnProduct?.discountReason ?? '';
      // }

      //calculate and apply bill discount
      final billDisc = cartSummary.discPer ?? 0;
      double billDiscAmt = 0;
      if (billDisc > 0 && product.pLUNODISC != true && blAllowDiscount) {
        billDiscAmt = (lineAmount * billDisc / 100);
      }

      cartSummary.subTotal += (lineAmount - billDiscAmt);

      final model = CartModel(
          setUpLocation: POSConfig().setupLocation,
          posDesc: product.pLUPOSDESC ?? "",
          proSelling: product.sELLINGPRICE ?? 0,
          noDisc: fixedPriceApplied ? true : product.pLUNODISC ?? true,
          scanBarcode: product.sCANCODE ?? "",
          proCode: product.pLUCODE ?? "",
          stockCode: product.pLUSTOCKCODE ?? "",
          selling: selling,
          proCaseSize: product.caseSize,
          proCost: product.cost ?? 0,
          proAvgCost: product.avgCost ?? 0,
          itemVoid: false,
          discAmt: disAmt,
          discPer: disPre,
          billDiscPer: blAllowDiscount ? cartSummary.discPer : 0,
          unitQty: qty,
          discountReason: discReason,
          maxDiscAmt: product.maxDiscAmt,
          maxDiscPer: product.maxDiscPer,
          amount: lineAmount,
          proUnit: product.pluUnit,
          volume: product.volume,
          maxVolume: product.maxVolume,
          maxVolumeGroup: product.maxVolumeGroup,
          lineRemark: lineRemark,
          maxVolumeGroupLvl: product.maxVolumeGroupLvl,
          allowDiscount: !minus
              ? blAllowDiscount
              : false, //this is to ensure that no discounts allow for return products //new change
          allowLoyalty: blAllowLoyalty,
          priceMode: strPriceMode,
          varientEnabled: product.varientEnable,
          batchEnabled: product.batchEnable,
          allowMinus: product.allowMinus,
          userAllowedMinus: allowMinusRes,
          fixedPriceApplied: fixedPriceApplied)
        ..proTax = proTax ?? [];
      int lineNo = cartList.length;
      model.lineNo = lineNo + 1;
      if (!POSConfig().localMode) model.image = product.image;
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.info, "New Item Added to the cart"));

      final res = await cartBloc.updateCurrentCart(model, alreadyAdded);
      if (res) {
        final String startTime = cartSummary.startTime;
        if (startTime.isEmpty) {
          //fetch time from server
          final dateTime = await TimeController().getCurrentServerTime();
          cartSummary.startTime = dateTime.toIso8601String();

          // DateFormat("yyyy-MM-dd HH:mm:ss.000")
          //     .parse(dateTime.toString())
          //     .toIso8601String();
        }
        cartBloc.updateCartSummary(cartSummary);
        final controller = InvoiceController();
        controller.updateTempCartSummary(cartSummary);
        if (successToast) {
          EasyLoading.showSuccess("easy_loading.item_add".tr());

          // return model;
        }
        cartedItems.add(model);
        // return model;
      } else {
        //revert the current calculations
        cartSummary.subTotal -= lineAmount;
        if (!alreadyAdded && !minus) {
          cartSummary.items--;
        }
        if (!minus) {
          cartSummary.qty -= qty;
        }
        cartBloc.updateCartSummary(cartSummary);
      }
      // return null;
      return cartedItems == [] ? null : cartedItems;
    } else {
      // This block is exclusive for product returns
      for (int j = 0; j < returnProducts.length; j++) {
        double disAmt = 0;
        double disPre = 0;
        double promoDiscAmt = 0;
        double promoDiscPer = 0;
        double netDiscAmt = 0;
        double netDiscPer = 0;
        final cartList = cartBloc.currentCart ?? {};
        final founded = cartList.values.toList().indexWhere((element) =>
            element.proCode == product.pLUCODE &&
            element.itemVoid != true &&
            element.unitQty > 0 &&
            element.stockCode == product.pLUSTOCKCODE &&
            element.selling == sellings[j]);
        bool alreadyAdded = founded != -1;
        if (!alreadyAdded && !minus) {
          cartSummary.items++;
        }
        String discReason = "";
        if (minus) {
          disAmt = returnProducts[j]?.discAmt ?? 0;
          disPre = returnProducts[j]?.discPer ?? 0;
          netDiscAmt = returnProducts[j]?.billDiscAmt ?? 0;
          netDiscPer = returnProducts[j]?.billDiscPer ?? 0;
          promoDiscAmt = returnProducts[j]?.promoDiscAmt ?? 0;
          promoDiscPer = returnProducts[j]?.promoDiscPre ?? 0;
          discReason = returnProducts[j]?.discountReason ?? '';
        }
        final billDisc = cartSummary.discPer ?? 0;
        double billDiscAmt = 0;
        if (billDisc > 0 && product.pLUNODISC != true && blAllowDiscount) {
          billDiscAmt = (lineAmounts[j] * billDisc / 100);
        }

        double addedQty = (qty * -1 <= returnProducts[j]!.unitQty)
            ? qty
            : -1 * returnProducts[j]!.unitQty;

        // handling the product with net disc
        if (netDiscPer != 0) {
          var tempDiscAmt = lineAmounts[j] * netDiscPer / 100;
          lineAmounts[j] -= tempDiscAmt;
          disPre += netDiscPer;
          netDiscPer = 0;
        }
        // else if (netDiscAmt != 0) {
        //   var tempDiscAmt = (netDiscAmt / returnProducts[j]!.unitQty) / qty;
        // }

        cartSummary.subTotal += (lineAmounts[j] - billDiscAmt);
        final model = CartModel(
            setUpLocation: POSConfig().setupLocation,
            posDesc: product.pLUPOSDESC ?? "",
            proSelling: product.sELLINGPRICE ?? 0,
            noDisc: product.pLUNODISC ?? true,
            scanBarcode: product.sCANCODE ?? "",
            proCode: product.pLUCODE ?? "",
            stockCode: product.pLUSTOCKCODE ?? "",
            selling: sellings[j],
            proCaseSize: product.caseSize,
            proCost: product.cost ?? 0,
            proAvgCost: product.avgCost ?? 0,
            itemVoid: false,
            discAmt:
                (disAmt / returnProducts[j]!.unitQty) * addedQty.abs() * -1,
            discPer: disPre,
            billDiscPer: 0, //blAllowDiscount ? cartSummary.discPer : 0,
            billDiscAmt: 0,
            unitQty: addedQty, // qty,
            discountReason: discReason,
            maxDiscAmt: product.maxDiscAmt,
            maxDiscPer: product.maxDiscPer,
            amount: lineAmounts[j],
            proUnit: product.pluUnit,
            volume: product.volume,
            maxVolume: product.maxVolume,
            maxVolumeGroup: product.maxVolumeGroup,
            lineRemark: lineRemark,
            maxVolumeGroupLvl: product.maxVolumeGroupLvl,
            allowDiscount: !minus
                ? blAllowDiscount
                : false, //this is to ensure that no discounts allow for return products //new change
            allowLoyalty: blAllowLoyalty,
            priceMode: strPriceMode,
            allowMinus: product.allowMinus,
            varientEnabled: product.varientEnable,
            batchEnabled: product.batchEnable,
            promoDiscAmt: -1 *
                (promoDiscAmt / returnProducts[j]!.unitQty) *
                addedQty.abs(),
            promoDiscPre: promoDiscPer)
          ..proTax = proTax ?? [];
        int lineNo = cartList.length;
        model.lineNo = lineNo + 1;
        if (!POSConfig().localMode) model.image = product.image;
        POSLoggerController.addNewLog(
            POSLogger(POSLoggerLevel.info, "New Item Added to the cart"));

        final res = await cartBloc.updateCurrentCart(model, alreadyAdded);
        if (res) {
          final String startTime = cartSummary.startTime;
          if (startTime.isEmpty) {
            final dateTime = await TimeController().getCurrentServerTime();
            cartSummary.startTime = dateTime.toIso8601String();
          }
          cartBloc.updateCartSummary(cartSummary);
          final controller = InvoiceController();
          controller.updateTempCartSummary(cartSummary);
          if (successToast) {
            EasyLoading.showSuccess("easy_loading.item_add".tr());
            // return model;
            // cartedItems.add(model);
          }
          // return model;
          cartedItems.add(model);
        } else {
          cartSummary.subTotal -= lineAmounts[j];
          if (!alreadyAdded && !minus) {
            cartSummary.items--;
          }
          if (!minus) {
            cartSummary.qty -= qty;
          }
          cartBloc.updateCartSummary(cartSummary);
        }
      }
      // return cartedItems == [] ? null : cartedItems.first;
      return cartedItems == [] ? null : cartedItems;
    }
  }

  void voidItem(CartModel cartModel, BuildContext? context) async {
    if (context != null) {
      SpecialPermissionHandler handler =
          SpecialPermissionHandler(context: context);
      String code = PermissionCode.itemVoid;
      String type = "A";
      String refCode = (cartBloc.cartSummary?.invoiceNo ?? "") +
          "@" +
          cartModel.proCode +
          '\$' +
          cartModel.amount.toStringAsFixed(2) +
          '*' +
          (cartModel.unitQty.toStringAsFixed(2));
      bool permissionStatus = handler.hasPermission(
          permissionCode: code, accessType: type, refCode: refCode);
      if (!permissionStatus) {
        bool success = (await handler.askForPermission(
                accessType: type, permissionCode: code, refCode: refCode))
            .success;
        if (!success) return;
      }
    }
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Item void ${cartModel.proCode}"));
    CartSummaryModel cartSummary = cartBloc.cartSummary ??
        CartSummaryModel(
            invoiceNo: "",
            items: 0,
            qty: 0,
            subTotal: 0,
            startTime: '',
            priceMode: '');

    //recalculate the subtotal
    cartSummary.subTotal -= (cartModel.amount -
        (cartModel.amount * (cartModel.billDiscPer ?? 0) / 100));
    //check item is mention twice in the cart
    int deductItem = 0;
    List<CartModel> mention = cartBloc.currentCart?.values
            .toList()
            .where((element) =>
                element.itemVoid == false &&
                element.proCode == cartModel.proCode)
            .toList() ??
        [];
    if (mention.length == 1) {
      deductItem = 1;
    }

    //deduct item and qty
    cartSummary.items = cartSummary.items - deductItem;

    // reason for this if statement and condition is when the returned product is voided it adds +1 to qty...ex:(1-(-1))
    if (cartModel.unitQty > 0)
      cartSummary.qty = cartSummary.qty - cartModel.unitQty;
    bool res = await cartBloc.voidCartItem(cartModel);
    if (res) {
      cartBloc.updateCartSummary(cartSummary);
      final controller = InvoiceController();
      controller.updateTempCartSummary(cartSummary);
    } else {
      cartSummary.subTotal += cartModel.amount;
    }
  }

  /// return true if the minus allow approved
  Future<bool> allowMinusAlert(
      BuildContext context, String invNo, Product product, double qty) async {
    // handle permission
    SpecialPermissionHandler handler =
        SpecialPermissionHandler(context: context);
    String code = PermissionCode.stockBypass;
    String type = "A";
    String refCode =
        invNo + "@" + (product.pLUCODE ?? "") + "@" + qty.toDouble().toString();
    bool permissionStatus = handler.hasPermission(
        permissionCode: code, accessType: type, refCode: refCode);
    if (!permissionStatus) {
      bool success = (await handler.askForPermission(
              accessType: type, permissionCode: code, refCode: refCode))
          .success;
      return success;
    }
    return permissionStatus;
    // final bool? allowMinusRes =await showDialog(context: context, builder: (context) => POSErrorAlert(title: 'sih_validation.title'.tr(), subtitle: 'sih_validation.subtitle'.tr(), actions: <Widget>[
    //   AlertDialogButton(onPressed: ()=>Navigator.pop(context,false), text: 'sih_validation.no'.tr()),
    //   AlertDialogButton(onPressed: ()async{
    //     // handle permission
    //     SpecialPermissionHandler handler =
    //     SpecialPermissionHandler(context: context);
    //     String code = PermissionCode.stockBypass;
    //     String type = "A";
    //     bool permissionStatus =
    //     handler.hasPermission(permissionCode: code, accessType: type);
    //     if (!permissionStatus) {
    //       String refCode = invNo +
    //           "@" +
    //           (product.pLUCODE ?? "") +
    //           "@" +
    //           qty.toDouble().toString();
    //       bool success = (await handler.askForPermission(
    //       accessType: type, permissionCode: code, refCode: refCode))
    //         .success;
    //     if (success) {
    //      Navigator.pop(context,true);
    //     }
    //   }else{
    //       Navigator.pop(context,true);
    //     }
    //   }, text: 'sih_validation.yes'.tr())
    // ]),);
    // return allowMinusRes??false;
  }

  //TODO: Multiple Price
  Future<ProductPriceChanges?> multiplePriceAlert(
      BuildContext context,
      double sellingPrice,
      List<ProductPriceChanges> multiplePrices,
      Product prod) async {
    multiplePriceNode.requestFocus();
    List<ProductPriceChanges> prices = [];
    prices.addAll(multiplePrices.reversed.toList());
    _multiplePriceEditingController.clear();
    final dynamic price = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          prod.pLUPOSDESC ?? '',
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          height: ScreenUtil().screenHeight * 0.65,
          width: ScreenUtil().screenWidth * 0.35,
          child: Column(
            children: [
              Text('multiple_prices.title'.tr()),
              TextField(
                onTap: () {
                  keyBoardController.init(context);
                  keyBoardController.showBottomDPKeyBoard(
                      _multiplePriceEditingController,
                      onEnter: () =>
                          onEnterMultiplePrice(prices, context, true),
                      buildContext: context);
                },
                autofocus: false,
                controller: _multiplePriceEditingController,
                onEditingComplete: () =>
                    onEnterMultiplePrice(prices, context, false),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(CommonRegExp.decimalRegExp),
                ],
                decoration:
                    InputDecoration(hintText: 'invoice.enter_price'.tr()),
              ),
              Expanded(
                child: KeyboardListener(
                  onKeyEvent: (value) {
                    if (value is KeyDownEvent) {
                      String label = value.logicalKey.keyLabel;
                      label = label.replaceAll('Numpad ', '');
                      //check the key is 0
                      int index = 0;
                      if (label == '0') {
                        index = 1;
                      } else {
                        index = label.toString().parseDouble().toInt();
                        if (index == 0) {
                          index = -1;
                        }
                      }

                      // do the selection
                      if (index <= prices.length + 1) {
                        // Navigator.pop(context, prices[index - 1].pRSPRICE);
                        Navigator.pop(context, prices[index - 1]);
                      }
                    }
                  },
                  focusNode: multiplePriceNode,
                  autofocus: true,
                  child: ListView.builder(
                    itemCount: prices.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        onTap: () =>
                            // Navigator.pop(context, prices[index].pRSPRICE),
                            Navigator.pop(context, prices[index]),
                        title: Row(
                          children: <Widget>[
                            Text(
                              '${index + 1}. ' +
                                  (prices[index].pRSPRICE ?? 0)
                                      .thousandsSeparator(),
                              style: CurrentTheme.headline6,
                            ),
                            if ((prices[index].pRDATE ?? '').isNotEmpty)
                              Text(
                                ' - ${prices[index].pRDATE ?? ''}',
                                style: CurrentTheme.bodyText1!.copyWith(
                                    color: POSConfig()
                                        .primaryLightColor
                                        .toColor()),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              ElevatedButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context, 0.0);
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (price == 0) {
      return null;
    }
    // return price ?? sellingPrice;
    return price ?? prices.first;
  }

  void onEnterMultiplePrice(List<ProductPriceChanges> prices,
      BuildContext context, bool isPosKeyboard) {
    double entered = _multiplePriceEditingController.text.parseDouble();
    //check the price is in the list
    int index = prices.indexWhere((element) => element.pRSPRICE == entered);
    _multiplePriceEditingController.clear();
    if (index != -1) {
      // Navigator.pop(context, entered);
      Navigator.pop(context, prices[index]);
      if (isPosKeyboard) {
        // Navigator.pop(context, entered);
        Navigator.pop(context, prices[index]);
      }
    } else {
      EasyLoading.showError('invoice.invalid_price'.tr());
    }
  }

  //Tax calculation is done here (item wise)
  void taxCalculation() {
    List<CartModel> itemList = cartBloc.currentCart?.values.toList() ?? [];
    double taxInc = 0;
    double taxExc = 0;
    List<InvTax> invTax = [];
    int lineNo = 0;
    for (CartModel item in itemList) {
      lineNo++;
      if (item.itemVoid == true) {
        continue;
      }
      // if (item.isTaxCalculated == true) {
      //   continue;
      // }
      double basePrice =
          item.amount - (item.amount * (item.billDiscPer ?? 0) / 100);
      //used for calculation
      double currentPrice = basePrice;

      currentPrice = basePrice;
      final proTaxes = item.proTax;
      double taxRate = 0;
      double taxAmt = 0;
      bool bltaxInc = false;
      for (int i = 0; i < proTaxes.length; i++) {
        final proTax = proTaxes[i];
        taxRate = proTax.taXRATE ?? 0;
        bltaxInc = proTax.ttXTAXINC ?? false;
        final taxAmt = _itemTaxCalc(currentPrice, taxRate, bltaxInc);
        // double priceWithTax = currentPrice;
        if (bltaxInc) {
          currentPrice -= taxAmt;
          taxInc += taxAmt;
        } else {
          if (proTax.taXCALONLY != true) taxExc += taxAmt;

          currentPrice += taxAmt;
          // priceWithTax = currentPrice;
        }
        invTax.add(InvTax(
            taxCode: proTax.taXCODE ?? '',
            productCode:
                item.proCode ?? item.stockCode, // changed stockCode --> proCode
            grossAmount: basePrice.toDouble(),
            taxAmount: taxAmt,
            taxPercentage: taxRate,
            afterTax: item.selling * item.unitQty,
            // afterTax: priceWithTax.toDouble(),
            taxInc: bltaxInc,
            lineNo: lineNo,
            taxSeq: proTax.ttXSEQUENCE ?? 0));
      }
      // item.isTaxCalculated = true;
      //save item price after the tax
      // double priceWithTax = basePrice;
      // List<ProTax> proTaxesInc =
      //     item.proTax.where((element) => element.ttXTAXINC == true).toList();
      // List<ProTax> proTaxesExc =
      //     item.proTax.where((element) => element.ttXTAXINC == false).toList();
      //inclusive tax calculation

      // for (int i = proTaxesInc.length - 1; i >= 0; i--) {
      //   ProTax proTax = proTaxesInc[i];
      //
      //   double taxAmt = _itemTaxCalc(currentPrice.toDouble(),
      //           proTax.taXRATE?.toDouble() ?? 0, proTax.ttXTAXINC == true)
      //       .toStringAsFixed(2)
      //       .parseDouble();
      //   print(taxAmt);
      //   taxInc += taxAmt;
      //   priceWithTax = currentPrice;
      //   currentPrice -= taxAmt;
      //   invTax.add(InvTax(
      //       taxCode: proTax.taXCODE ?? '',
      //       productCode: item.stockCode,
      //       grossAmount: basePrice.toDouble(),
      //       taxAmount: taxAmt.toDouble(),
      //       taxPercentage: proTax.taXRATE?.toDouble() ?? 0,
      //       afterTax: priceWithTax.toDouble(),
      //       taxInc: proTax.ttXTAXINC == true,
      //       lineNo: lineNo,
      //       taxSeq: proTax.ttXSEQUENCE ?? 0));
      // }
      // //exclusive tax calculation
      // for (ProTax proTax in proTaxesExc) {
      //   if (proTax.ttXSEQUENCE == 0) {
      //     currentPrice = basePrice;
      //   } else {
      //     currentPrice = priceWithTax;
      //   }
      //   double taxAmt = _itemTaxCalc(currentPrice.toDouble(),
      //           proTax.taXRATE?.toDouble() ?? 0, proTax.ttXTAXINC == true)
      //       .toString()
      //       .parseDouble();
      //   taxExc += taxAmt;
      //   priceWithTax += taxAmt;
      //
      //   invTax.add(InvTax(
      //       taxCode: proTax.taXCODE ?? '',
      //       productCode: item.stockCode,
      //       grossAmount: basePrice.toDouble(),
      //       taxAmount: taxAmt.toDouble(),
      //       taxPercentage: proTax.taXRATE?.toDouble() ?? 0,
      //       afterTax: priceWithTax.toDouble(),
      //       taxInc: proTax.ttXTAXINC == true,
      //       lineNo: lineNo,
      //       taxSeq: proTax.ttXSEQUENCE ?? 0));
      // }
    }
    final summary = cartBloc.cartSummary;
    if (summary != null) {
      summary.grossTotal = summary.subTotal;
      summary.taxExc = taxExc;
      summary.taxInc = taxInc;
      summary.invTax = invTax;
      summary.subTotal = summary.grossTotal! + taxExc;
      cartBloc.updateCartSummary(summary);
    }
  }

  double _itemTaxCalc(double amount, double tax, bool inc) {
    double taxAmt = 0;
    double hundred = 100.0;
    if (inc) {
      // taxAmt =  ((amount / ( hundred + tax)).todouble() *  hundred);
      // double pAmount = ((hundred * amount) / (hundred + tax));
      // return amount - pAmount;

      // lets say the tax rate (variable dblTR) is = 12%
      // and the item's line amount (dblLineWithoutTax) is is 100.00

      double dblDedPer = 1 + (tax / 100); // this becomes 1.12
      return amount - (amount / dblDedPer);
    } else {
      taxAmt = amount * (tax / hundred);
    }
    return taxAmt;
  }

  Future<Map<String, dynamic>> _showSalesReturnDialog(BuildContext context,
      String itemCode, double totalQty, double enteredQty) async {
    String refInvNo = cartBloc.cartSummary?.refNo ?? '';
    bool canContinue = true;
    String output = "";

    if (refInvNo.isEmpty) {
      String response = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'return_sales.title'.tr(),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('return_sales.enter'.tr()),
                SizedBox(
                  height: 15.h,
                ),
                TextField(
                  onTap: () {
                    keyBoardController.dismiss();
                    keyBoardController.init(context);
                    keyBoardController.showBottomDPKeyBoard(
                        _refNoEditingController, onEnter: () {
                      if (_refNoEditingController.text != "") {
                        KeyBoardController().dismiss();
                        Navigator.pop(context, 'continue');
                      }
                    }, buildContext: context);
                  },
                  controller: _refNoEditingController,
                  onEditingComplete: () {
                    if (_refNoEditingController.text.isEmpty) {
                      EasyLoading.showError('Please enter the invoice number');
                      return;
                    }
                    Navigator.pop(context, 'continue');
                  },
                  autofocus: true,
                )
              ],
            ),
            actions: [
              AlertDialogButton(
                  onPressed: () {
                    if (_refNoEditingController.text.isEmpty) {
                      EasyLoading.showError('Please enter the invoice number');
                      return;
                    }
                    Navigator.pop(context, 'continue');
                  },
                  text: 'return_sales.continue'.tr()),
              SizedBox(
                height: 15.h,
                width: 5.w,
              ),
              AlertDialogButton(
                  onPressed: () =>
                      Navigator.pop(context, 'continue_without_inv'),
                  text: 'return_sales.continue_without_ref'.tr()),
              SizedBox(
                height: 15.h,
                width: 5.w,
              ),
              AlertDialogButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  text: 'return_sales.cancel'.tr()),
            ],
          );
        },
      );
      refInvNo = _refNoEditingController.text;
      _refNoEditingController.clear();
      canContinue = (response == 'continue' ? true : false);
      output = response;
    }

    double lineAmount = 0;
    double selling = 0;

    //new change for new product window
    List<CartModel?>? selectedProducts = [];
    double sold = 0;

    List<double> sellings = [];
    List<double> lineAmounts = [];

    try {
      if (canContinue) {
        canContinue = false;
        // get item details from server
        // EasyLoading.show(status: 'please_wait'.tr(), dismissOnTap: true);
        final serverMap = await InvoiceController().getCartDetails(refInvNo);

        final itemList =
            (serverMap['cartModels'] as List<dynamic>).cast<CartModel>();

        if (itemList.isEmpty && POSConfig().saveInvoiceLocal) {
          final localMap =
              await InvoiceController().getCartDetails(refInvNo, local: true);
          itemList.addAll(localMap['cartModels'] ?? []);
        }
        //check the item is in the database
        final List<CartModel> summarizedReturnList = itemList
            .where((element) =>
                element.stockCode == itemCode &&
                element.itemVoid == false &&
                (element.unitQty ?? 0) > 0)
            .toList();
        EasyLoading.dismiss();
        if (summarizedReturnList.isEmpty) {
          EasyLoading.dismiss();
          await _salesReturnError(context, 'invalid_item', refInvNo);
          return {
            'continue': 'cancel',
          };
        }

        if ((POSConfig().setup?.itemReturnDayLimit ?? 0) > 0 &&
            summarizedReturnList.first.dateTime != null) {
          DateTime expiredDate = DateFormat('yyyy-MM-dd').parse(
              (summarizedReturnList.first.dateTime)!
                  .add(Duration(days: POSConfig().setup!.itemReturnDayLimit!))
                  .toIso8601String());
          bool expired = DateFormat('yyyy-MM-dd')
              .parse(DateTime.now().toIso8601String())
              .isAfter(expiredDate);
          if (expired) {
            EasyLoading.dismiss();
            await _salesReturnError(context, 'expired', refInvNo);
            return {
              'continue': 'cancel',
            };
          }
        }
        EasyLoading.dismiss();

        /*
      * Author: TM.Sakir
      * change: Added a window for showing product list and giving the facility to select the desired product to return
      */
        // EasyLoading.dismiss();
        selectedProducts = await showInvoicedProducts(context,
            cartItems: summarizedReturnList, invNo: refInvNo);

        // final List<CartModel> new_itemList=[];
        // for (int i=0;i<itemList.length;i++)
        //   {
        //     dynamic retItem=itemList[i];
        //     dynamic x= new_itemList.indexWhere((element) => element.stockCode == itemCode);
        //     if (x!=-1){
        //       CartModel xitem = new_itemList[x];
        //       xitem.unitQty = double.tryParse(retItem["unitQty"]);
        //     }
        //     else
        //       {
        //         new_itemList[retItem["stockCode"]] = double.tryParse(retItem["unitQty"]);
        //       }
        //   }

        // if (summarizedReturnList.isEmpty) {
        //   await _salesReturnError(context, 'invalid_item', refInvNo);
        // }
        // // final item = itemList[index];
        // double summarizedTotalQty =
        //     summarizedReturnList.fold(0, (sum, element) => sum + element.unitQty);
        // double summarizedAmount =
        //     summarizedReturnList.fold(0, (sum, element) => sum + element.amount);
        // if ((totalQty * -1) > summarizedTotalQty) {
        //   await _salesReturnError(context, 'invalid_qty', refInvNo);
        // } else {
        //   canContinue = true;
        //   //TODO: re calculate the calculation
        //   selling = summarizedAmount / summarizedTotalQty;
        //   lineAmount = selling * enteredQty;
        // }

        if (selectedProducts == null) {
          output = 'cancel';
          // await _salesReturnError(context, 'invalid_item', refInvNo);
        } else {
          double summarizedTotalQty = 0;
          selectedProducts.forEach((element) {
            summarizedTotalQty += element!.unitQty;
          });

          if ((totalQty * -1) > summarizedTotalQty) {
            await _salesReturnError(context, 'invalid_qty', refInvNo);
            output = 'cancel';
          } else {
            for (int i = 0; i < selectedProducts.length; i++) {
              canContinue = true;
              output = 'continue';
              sold = selectedProducts[i]!.amount / selectedProducts[i]!.unitQty;
              // lineAmount = sold * (-1 * selectedProducts[i]!.unitQty); //wrong
              lineAmount = (selectedProducts[i]!.unitQty >= (-1 * enteredQty))
                  ? sold * enteredQty
                  : sold * -1 * selectedProducts[i]!.unitQty;
              selling = selectedProducts[i]!.selling;

              sellings.add(selling);
              lineAmounts.add(lineAmount);
            }
          }
        }
      }
    } catch (e) {
      // EasyLoading.dismiss();
      LogWriter().saveLogsToFile(
          'ERROR_LOG_', ['Error on _showSalesReturnDialog() :' + e.toString()]);
    }

    return {
      'continue': output,
      'refInvNo': refInvNo,
      'amounts': lineAmounts,
      'sellings': sellings,
      'returnProducts': selectedProducts
    };
  }

  Future<void> _salesReturnError(
      BuildContext context, String localizationKey, String ref) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return POSErrorAlert(
            title: 'return_sales.title'.tr(),
            subtitle:
                'return_sales.$localizationKey'.tr(namedArgs: {'inv': ref}),
            actions: [
              AlertDialogButton(
                  onPressed: () => Navigator.pop(context),
                  text: 'return_sales.okay'.tr())
            ]);
      },
    );
  }

  Future<void> applyPromotions(
      List<CartModel> cart,
      double totalBillDiscount,
      double totalLineDiscount,
      List<InvBillDiscAmountPromo> billDiscPromo) async {
    //TODO: store DISCOUNT in a global variable
    final List<CartModel> cartList =
        cart.where((element) => element.proCode == "DISCOUNT").toList();
    for (CartModel cartItem in cartList) {
      cartBloc.updateCurrentCart(cartItem, false);
    }
    //update cart summary
    final summary = cartBloc.cartSummary;
    if (summary != null) {
      summary.promoDiscount = (totalBillDiscount + totalLineDiscount);
      summary.subTotal -= (totalBillDiscount + totalLineDiscount);
      cartBloc.updateCartSummary(summary);
      cartBloc.updateCartForPromo(cart, billDiscPromo);
    }
  }

  Future<void> addPromotionFreeItem(
      String enteredCode, BuildContext context) async {
    double qty = 1;
    String temp = enteredCode;
    String code = temp;
    final symbol = "*";
    if (code.contains(symbol)) {
      //  split it lhs is qty
      final split = code.split(symbol);
      code = split.last;
      qty = double.tryParse(split.first) ?? 1;
    }
    final res = await searchProduct(enteredCode);
    //check this item already in free item bloc
    if (res != null && res.product != null) {
      final String itemCode = res.product!.first.pLUCODE ?? '';
      final List<PromotionFreeItems> promoFreeItems =
          cartBloc.promoFreeItems ?? [];
      int freeItemHeaderCode = -1;
      int freeItemDetailsCode = -1;
      String promoCode = '';
      String promoDesc = '';
      String originalItem = '';
      for (int i = 0; i < promoFreeItems.length; i++) {
        freeItemDetailsCode = promoFreeItems[i]
            .freeItemBundle
            .indexWhere((element) => element.proCode == itemCode);
        if (freeItemDetailsCode != -1 && promoFreeItems[i].remainingQty > 0) {
          freeItemHeaderCode = i;
          promoCode = promoFreeItems[i].promotionCode;
          promoDesc = promoFreeItems[i].promotionDesc;
          originalItem = promoFreeItems[i].originalItemCode;
          break;
        }
      }
      // update the cart block with given qty
      if (freeItemHeaderCode != -1 && freeItemDetailsCode != -1) {
        bool freeItemSaved = cartBloc.updatePromoFreeItem(
            promoFreeItems, freeItemHeaderCode, freeItemDetailsCode, qty);
        if (freeItemSaved) {
          final cartItem = await addItemToCart(res.product!.first, qty, context,
              res.prices, res.proPrices, res.proTax,
              secondApiCall: false, successToast: true);
          //set 100 discounts
          if (cartItem != null && cartItem.isNotEmpty) {
            add100Discount(cartItem.first!, promoCode, promoDesc, originalItem);
          }
        }
      } else {
        EasyLoading.showError('promo.invalid_product'.tr());
      }
    } else {
      EasyLoading.showError('promo.invalid_product'.tr());
    }
  }

  Future<void> addPromotionFreeGV(
      String enteredCode, BuildContext context) async {
    double qty = 1;
    String temp = enteredCode;
    String code = temp;

    final GiftVoucherResult? voucherRes =
        await GiftVoucherController().getGiftVoucherById(code);
//  if this is invalid one lets show message
    if (voucherRes == null ||
        voucherRes.success != true && voucherRes.giftVoucher != null) {
      // return gv validation
      final bool sold = voucherRes?.giftVoucher?.soldInv?.isNotEmpty ?? false;
      final bool redeem =
          voucherRes?.giftVoucher?.redeemInv?.isNotEmpty ?? false;
      final bool cancel =
          voucherRes?.giftVoucher?.cancelInv?.isNotEmpty ?? false;
      final bool returnInv =
          voucherRes?.giftVoucher?.returnInv?.isNotEmpty ?? false;
      print('*************************************');
      print('*************$sold************************');
      print('*************************************');
      if (sold &&
          (!redeem && !cancel && !returnInv) &&
          voucherRes?.giftVoucher != null) {
        if (qty > 0) {
          //_gvError(voucherRes?.message ?? 'gv_error.sold'.tr());
          EasyLoading.showError('gv_error.sold'.tr());
        }
      } else {
        //_gvError(voucherRes?.message ?? 'gv_error.not_found'.tr());
        EasyLoading.showError('gv_error.not_found'.tr());
      }
      return;
    }

    //check this item already in free item bloc
    if (voucherRes != null && voucherRes.giftVoucher != null) {
      final String itemCode = voucherRes.giftVoucher!.vCNO ?? '';
      final List<PromotionFreeGVs> promoFreeGVs = cartBloc.promoFreeGVs ?? [];
      int freeItemHeaderCode = -1;
      int freeGVDetailsCode = -1;
      String promoCode = '';
      String promoDesc = '';
      String originalItem = '';
      for (int i = 0; i < promoFreeGVs.length; i++) {
        freeGVDetailsCode = promoFreeGVs[i]
            .gvCodes
            .indexWhere((element) => element == itemCode);
        //TODO: check GV value and show a message
        if (freeGVDetailsCode == -1 &&
            promoFreeGVs[i].remainingQty > 0 &&
            voucherRes.giftVoucher!.vCVAlUE == promoFreeGVs[i].gvValue) {
          freeItemHeaderCode = i;
          promoCode = promoFreeGVs[i].promotionCode;
          promoDesc = promoFreeGVs[i].promotionDesc;
          originalItem = promoFreeGVs[i].originalItemCode;
          promoFreeGVs[i].gvCodes.add(itemCode);
          break;
        }
      }
      // update the cart block with given qty
      if (freeGVDetailsCode == -1) {
        bool freeItemSaved = cartBloc.updatePromoFreeGV(
            promoFreeGVs, freeItemHeaderCode, freeGVDetailsCode, qty);
        if (freeItemSaved) {
          //final cartItem = await addItemToCart(
          //res.product!, qty, context, res.prices, res.proPrices, res.proTax,
          //secondApiCall: false, successToast: true);
          final cartItem = await addGv(voucherRes.giftVoucher!, qty, context);
          //set 100 discounts
          if (cartItem != null) {
            add100Discount(cartItem, promoCode, promoDesc, originalItem);
          }
        }
      } else {
        EasyLoading.showError('promo.invalid_product'.tr());
      }
    } else {
      EasyLoading.showError('promo.invalid_product'.tr());
    }
  }

  void add100Discount(CartModel cartModel, String promoCode, String promoDesc,
      String originalItem) {
    double amount = cartModel.amount;
    cartModel.amount = 0;
    cartModel.promoDiscPre = 100;
    cartModel.promoCode = promoCode;
    cartModel.promoDesc = promoDesc;
    cartModel.promoOriginalItem = originalItem;
    cartBloc.updateCartItem(cartModel);
    //update original item's promo code
    final Map<String, CartModel> currentMap = cartBloc.currentCart ?? {};
    final originalIndex = currentMap.values
        .toList()
        .indexWhere((element) => element.proCode == originalItem);
    if (originalIndex != -1) {
      final CartModel originalCartItem =
          currentMap.values.toList()[originalIndex];
      originalCartItem.promoCode = promoCode;
      cartBloc.updateCartItem(originalCartItem);
    }
    cartBloc.updateCartSummaryPrice(amount * -1);
  }

  void clearPayments() {
    InvoiceController().clearTempPayment();
    clearProductTax();
    clearPromotion();
    clearGroupBasedDiscounts();
  }

  // clearing staff-based auto discount when go back form payment view
  void clearGroupBasedDiscounts() {
    // final summary = cartBloc.cartSummary;
    cartBloc.currentCart?.values.forEach((element) {
      if (element.itemVoid != true && element.groupDiscApplied == true) {
        final double disc = element.discAmt ?? 0;
        element.amount += disc;
        cartBloc.cartSummary?.subTotal += disc;
        element.discAmt = 0;
        element.discountReason = '';
        element.groupDiscApplied = false;
      }
    });
  }

  void clearProductTax() {
    final summary = cartBloc.cartSummary;

    if (summary != null) {
      summary.subTotal = summary.subTotal - (summary.taxExc ?? 0);
      summary.taxExc = 0;
      summary.taxInc = 0;
      summary.invTax = [];
      cartBloc.updateCartSummary(summary);
    }
  }

  void clearPromotion() {
    final summary = cartBloc.cartSummary;
    if (summary != null) {
      summary.subTotal += (summary.promoDiscount ?? 0);
      summary.promoDiscount = 0;
      cartBloc.updateCartSummary(summary);
      cartBloc.clearPromoTickets();
      cartBloc.clearAppliedPromo();
    }
    //going through cart items
    cartBloc.currentCart?.values.forEach((element) {
      double amount = 0;
      double selling = element.selling;
      double qty = element.unitQty;
      double promoDiscPre = (element.promoDiscPre ?? 0);
      double promoBillDiscPre = (element.promoBillDiscPre ?? 0);
      if ((element.promoDiscAmt ?? 0) > 0) {
        amount = (element.promoDiscAmt ?? 0);
      } else if (promoDiscPre > 0) {
        amount = selling * qty * promoDiscPre / 100;
      } else if (promoBillDiscPre > 0) {
        amount = selling * qty * promoBillDiscPre / 100;
      }
      if ((element.promoCode ?? '').isNotEmpty &&
          (element.promoDiscPre ?? 0) == 100) {
        voidItem(element, null);
      }
      if ((element.promoCode ?? '').isNotEmpty &&
          (element.stockCode) == 'DISCOUNT') {
        voidItem(element, null);
      }
      if (element.unitQty > 0) {
        // this condition prevent clearing promotion disc amount for returned item (promotion applied)
        element.amount += amount;
        element.promoDiscAmt = 0;
        element.promoDiscPre = 0;
        element.promoBillDiscPre = 0;
        element.promoCode = '';
        element.promoDesc = '';
        element.promoDiscValue = 0;
      }
      cartBloc.updateCartUnconditionally(element);
    });
  }

  ProductController productController = ProductController();

  Future<ProductResult?> searchProduct(String enteredCode) async {
    double qty = 1;
    String temp = enteredCode;
    String code = temp;
    final symbol = "*";
    if (code.contains(symbol)) {
      //  split it lhs is qty
      final split = code.split(symbol);
      code = split.last;
      qty = double.tryParse(split.first) ?? 1;
      if (qty == 0) {
        EasyLoading.showError('Invalid quantity... \ncannot add zero quantity');
        return null;
      }
    } else if (POSConfig().setup?.setuPSCALESYMBOL != null) {
      // check if the . is available or not
      String scaleSymbol = POSConfig().setup!.setuPSCALESYMBOL!;
      if (code.contains(scaleSymbol)) {
        final split = code.split(scaleSymbol);
        code = split.first;

        double? quantity;

        if (POSConfig().setup?.setuPSCALEDIGIT != null) {
          int digit = POSConfig().setup!.setuPSCALEDIGIT!;
          quantity =
              split.last.substring(0, (split.last).length - digit).toDouble();
        } else {
          quantity = split.last.toDouble();
        }

        qty = (quantity != null) ? quantity : 0;
      }
    }

    EasyLoading.show(status: 'please_wait'.tr());
    final res = await productController.searchProductByBarcode(
      code,
      qty.toDouble(),
    );
    EasyLoading.dismiss();
    return res;
  }

  Future<List<CartModel?>?> showInvoicedProducts(BuildContext context,
      {required List<CartModel> cartItems, required String invNo}) async {
    final Color iconColor = CurrentTheme.primaryLightColor!;
    final space1 = SizedBox(
      width: 15.w,
    );
    final double fontSize = 20.sp;
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    double total = 0;
    for (int i = 0; i < cartItems.length; i++) {
      total += cartItems[i].amount;
    }

    final List<bool> isSelected =
        List.generate(cartItems.length, (index) => false);
    List<int> selectedProductIndexes = [];
    List<CartModel?> selectedProducts = [];
    // bool isSelected = false;
    List<int?>? res = await showGeneralDialog<List<int?>>(
      context: context,
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          StatefulBuilder(builder: (context, StateSetter setState) {
        return Transform.scale(
          scale: animation.value,
          child: Padding(
            padding: EdgeInsets.all(height * 0.05),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              color: Theme.of(context).primaryColor,
              elevation: 5,
              shadowColor: Theme.of(context).primaryColor,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Padding(
                  padding: EdgeInsets.only(
                      left: width * 0.02,
                      right: width * 0.02,
                      bottom: height * 0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: height * 0.1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesome5.clipboard,
                              color: iconColor,
                            ),
                            space1,
                            Tooltip(
                              message: "Invoice Number",
                              child: Text(
                                invNo,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: width * 0.02),
                        child: Column(
                          children: [
                            Container(
                              height: height * 0.13,
                              child: Column(
                                children: [
                                  const Divider(),
                                  ListTile(
                                    leading: SizedBox(
                                      width: width * 0.02,
                                    ),
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Expanded(
                                        //   flex: 1,
                                        //   child: Text(''),
                                        // ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('ItemCode',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                        Expanded(
                                          flex: 6,
                                          child: Text('Description',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('Unit Prc',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text('Qty ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('Disc.per',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('Disc.amt',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('Promotion \nDisc.per',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('Promotion \nDisc.amt',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text('Total \nAmount',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider()
                                ],
                              ),
                            ),
                            SizedBox(
                              height: height * 0.47,
                              child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: cartItems.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: Checkbox(
                                          value: isSelected[index],
                                          onChanged: (value) {
                                            setState(
                                              () {
                                                isSelected[index] = value!;
                                              },
                                            );
                                            if (value == true) {
                                              selectedProductIndexes.add(index);
                                            } else {
                                              selectedProductIndexes
                                                  .remove(index);
                                            }
                                            setState(
                                              () {},
                                            );
                                            print(selectedProductIndexes);
                                          }),
                                      title: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: InkWell(
                                          onTap: () {
                                            // if (selectedProductIndexes.length ==
                                            //     0) {
                                            //   selectedProductIndexes.add(index);
                                            //   Navigator.pop(context,
                                            //       selectedProductIndexes);
                                            // }
                                            setState(() {
                                              isSelected[index] =
                                                  !isSelected[index];
                                            });
                                            if (isSelected[index] == true) {
                                              selectedProductIndexes.add(index);
                                            } else {
                                              selectedProductIndexes
                                                  .remove(index);
                                            }

                                            setState(
                                              () {},
                                            );
                                            print(selectedProductIndexes);
                                          },
                                          child: SizedBox(
                                            height: height * 0.08,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                      cartItems[index].proCode,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 20.sp,
                                                          color: Colors.white)),
                                                ),
                                                Expanded(
                                                  flex: 6,
                                                  child: Text(
                                                      cartItems[index].posDesc,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 20.sp,
                                                          color: Colors.white)),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                      cartItems[index]
                                                          .selling
                                                          .toStringAsFixed(2),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 20.sp,
                                                          color: Colors.white)),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                      cartItems[index]
                                                          .unitQty
                                                          .toStringAsFixed(2),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 20.sp,
                                                          color: Colors.white)),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                      cartItems[index]
                                                              .discPer
                                                              ?.toStringAsFixed(
                                                                  2) ??
                                                          '0.00',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 20.sp,
                                                          color: (cartItems[index]
                                                                          .discPer ==
                                                                      null ||
                                                                  cartItems[index]
                                                                          .discPer!
                                                                          .toStringAsFixed(
                                                                              2) ==
                                                                      '0.00')
                                                              ? Colors.white
                                                              : Colors.red)),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                      cartItems[index]
                                                              .discAmt
                                                              ?.toStringAsFixed(
                                                                  2) ??
                                                          '0.00',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 20.sp,
                                                          color: (cartItems[index]
                                                                          .discAmt ==
                                                                      null ||
                                                                  cartItems[index]
                                                                          .discAmt!
                                                                          .toStringAsFixed(
                                                                              2) ==
                                                                      '0.00')
                                                              ? Colors.white
                                                              : Colors.red)),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                      cartItems[index]
                                                              .promoDiscPre
                                                              ?.toStringAsFixed(
                                                                  2) ??
                                                          '0.00',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 20.sp,
                                                          color: (cartItems[index]
                                                                          .promoDiscPre ==
                                                                      null ||
                                                                  cartItems[index]
                                                                          .promoDiscPre!
                                                                          .toStringAsFixed(
                                                                              2) ==
                                                                      '0.00')
                                                              ? Colors.white
                                                              : Colors.red)),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                      cartItems[index]
                                                              .promoDiscAmt
                                                              ?.toStringAsFixed(
                                                                  2) ??
                                                          '0.00',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 20.sp,
                                                          color: (cartItems[index]
                                                                          .promoDiscAmt ==
                                                                      null ||
                                                                  cartItems[index]
                                                                          .promoDiscAmt!
                                                                          .toStringAsFixed(
                                                                              2) ==
                                                                      '0.00')
                                                              ? Colors.white
                                                              : Colors.red)),
                                                ),
                                                Expanded(
                                                  flex: 4,
                                                  child: Text(
                                                      cartItems[index]
                                                          .amount
                                                          .toStringAsFixed(2),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 20.sp,
                                                          color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text('Items: ${cartItems.length}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: fontSize,
                                          color: Colors.white)),
                                  space1,
                                  space1,
                                  Text(
                                      'Total Amount: Rs. ${total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: fontSize,
                                          color: Colors.white))
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Divider(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 25,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AlertDialogButton(
                                onPressed: () => Navigator.pop(context, null),
                                text: 'return_sales.cancel'.tr()),
                            SizedBox(
                              width: 20,
                            ),
                            AlertDialogButton(
                                onPressed: () {
                                  if (selectedProductIndexes.isEmpty) {
                                    EasyLoading.showError(
                                        'No product/s selected for return');
                                  } else {
                                    Navigator.pop(
                                        context, selectedProductIndexes);
                                  }
                                },
                                text: 'return_sales.continue'.tr()),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
    if (res != null) {
      res.forEach((element) {
        selectedProducts.add(cartItems[element!]);
      });
      return selectedProducts;

      //cartItems[int.parse(res.toString())];
    }
    return null;
  }
}
