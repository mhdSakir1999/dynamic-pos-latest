/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 7/12/21, 1:08 PM
 */

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos/product_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/views/invoice/cart.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:supercharged/supercharged.dart';

/// this view will show in the open item pop up
/// This class will return the Product Object it can be null
class OpenItemView extends StatefulWidget {
  final Product product;
  final bool? isOpen;

  const OpenItemView({Key? key, required this.product, this.isOpen = true})
      : super(key: key);

  @override
  _OpenItemViewState createState() => _OpenItemViewState();
}

class _OpenItemViewState extends State<OpenItemView> {
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final amountFocus = FocusNode();
  final descriptionFocus = FocusNode();
  final doneButton = FocusNode();
  bool active = false;
  @override
  void initState() {
    super.initState();
    amountFocus.requestFocus();
    // Future.delayed(
    //   Duration(seconds: 2),
    // ).then((value) {
    //   setState(() {
    //     active = true;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
        child: Cart(
      replaceController: priceController,
      replaceCart: buildBody(),
      replacePayButton: actionButtons(),
      replaceOnEnter: () {
        if (widget.isOpen == true) {
          descriptionFocus.requestFocus();
          showAlphaKey();
        } else {
          handleDone();
        }
      },
      openCustomerEnter: false,
    ));
  }

  void showAlphaKey() {
    KeyBoardController().init(context);
    KeyBoardController().dismiss();
    KeyBoardController().showBottomDPKeyBoard(descriptionController,
        onEnter: () {
      Navigator.pop(context);
      handleDone();
    });
  }

  Widget buildBody() {
    return Column(
      children: [
        SizedBox(
          height: 5.h,
        ),
        productMasterDetails(),
        SizedBox(
          height: 5.h,
        ),
        TextField(
          controller: priceController,
          focusNode: amountFocus,
          onEditingComplete: () {
            if (widget.isOpen == true) {
              descriptionFocus.requestFocus();
              showAlphaKey();
            } else {
              handleDone();
            }
          },
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
          ],
          decoration: InputDecoration(
              filled: true, hintText: "open_item_view.amount".tr()),
        ),
        SizedBox(
          height: 8.h,
        ),
        widget.isOpen == true
            ? TextField(
                controller: descriptionController,
                focusNode: descriptionFocus,
                onEditingComplete: () {
                  handleDone();
                },
                onTap: () => showAlphaKey(),
                decoration: InputDecoration(
                    filled: true, hintText: "open_item_view.description".tr()),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget actionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: Text("open_item_view.cancel".tr())),
        ),
        SizedBox(
          width: 8.w,
        ),
        Expanded(
          child: ElevatedButton(
              focusNode: doneButton,
              style: ElevatedButton.styleFrom(
                  backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
              onPressed: () {
                handleDone();
              },
              child: Text("open_item_view.done".tr())),
        ),
      ],
    );
  }

  void handleDone() async {
    if (widget.isOpen != true &&
        double.parse(priceController.text ?? '0') <
            (widget.product.minSell ?? 0)) {
      String refCode =
          '${cartBloc.cartSummary?.invoiceNo}/${widget.product.pLUCODE}/${widget.product.sELLINGPRICE}->${priceController.text}';
      bool hasPermission = false;
      hasPermission = SpecialPermissionHandler(context: context).hasPermission(
          permissionCode: PermissionCode.skipMinSellValidation,
          accessType: "A",
          refCode: refCode);

      //if user doesnt have the permission
      if (!hasPermission) {
        final res = await SpecialPermissionHandler(context: context)
            .askForPermission(
                permissionCode: PermissionCode.skipMinSellValidation,
                accessType: "A",
                refCode: refCode);
        hasPermission = res.success;
      }
      if (!hasPermission) {
        amountFocus.requestFocus();
        return null;
      }
    }
    String des = descriptionController.text;
    if (descriptionController.text.isEmpty) {
      des = widget.product.pLUPOSDESC ?? "";
    }
    var product = widget.product;
    product.pLUPOSDESC = des;
    product.sELLINGPRICE = priceController.text.parseDouble();
    Navigator.pop(context, product);
  }

  Widget productMasterDetails() {
    final style = CurrentTheme.subtitle2;
    return Card(
      color: CurrentTheme.primaryColor,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(8.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text("open_item_view.product_master_details".tr())),
            Text(
              "open_item_view.product_master_item_code"
                  .tr(namedArgs: {"code": widget.product.pLUCODE ?? ""}),
              style: style,
            ),
            Text(
              "open_item_view.product_master_desc"
                  .tr(namedArgs: {"desc": widget.product.pLUPOSDESC ?? ""}),
              style: style,
            ),
            Text(
              "open_item_view.product_master_price".tr(namedArgs: {
                "mrp": widget.product.sELLINGPRICE?.thousandsSeparator() ?? ""
              }),
              style: style,
            ),
            widget.isOpen != true
                ? Text(
                    "open_item_view.product_min_sell".tr(namedArgs: {
                      "msp": widget.product.minSell?.thousandsSeparator() ?? ""
                    }),
                    style: style?.copyWith(color: Colors.greenAccent),
                  )
                : const SizedBox.shrink()
          ],
        ),
      ),
    );
  }
}
