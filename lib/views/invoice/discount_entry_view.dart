/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/28/21, 10:40 AM
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/discount_bloc.dart';
import 'package:checkout/bloc/keyboard_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/mypos_screen_utils.dart';
import 'package:checkout/components/widgets/poskeyboard.dart';
import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/controllers/bill_discount_handler.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/models/enum/keyboard_type.dart';
import 'package:checkout/models/net_bill_discount_model.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/discount_type_result.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:checkout/extension/extensions.dart';
import 'invoice_app_bar.dart';
import 'package:checkout/controllers/discount_handler.dart';
import 'package:supercharged/supercharged.dart';

class DiscountEntryView extends StatefulWidget {
  static const routeName = "discount_entry";
  final bool discountPercentage;
  final CartModel? cartItem;
  const DiscountEntryView({
    Key? key,
    this.discountPercentage = true,
    this.cartItem,
  }) : super(key: key);

  @override
  _DiscountEntryViewState createState() => _DiscountEntryViewState();
}

class _DiscountEntryViewState extends State<DiscountEntryView> {
  double height = 60;
  NetBillDiscountModel? selectedDiscount;
  TextEditingController discountEditingController = TextEditingController();
  double spacing = 3;
  final discountFocus = FocusNode();
  double maxDiscountPre = 0;
  double total = 0;
  double discount = 0;
  bool clicked = false;
  DiscountTypes? discountType;
  bool initial = true;

  @override
  void initState() {
    super.initState();

    //check discount applicable or not
    if (widget.cartItem != null && widget.cartItem!.noDisc == true) {
      if (widget.cartItem!.allowDiscount != true) Navigator.pop(context);
    }
    getMaxDiscountAmount(userBloc.currentUser?.uSERHEDUSERCODE ?? '');
    //listner
    discountEditingController.addListener(() {
      if (initial && discountEditingController.text.isNotEmpty) {
        setState(() {
          initial = false;
        });
      }
    });

    if (widget.cartItem != null) {
      final item = widget.cartItem!;
      if (widget.discountPercentage) {
        total = (item.unitQty * item.selling).toDouble();
      } else {
        final item = widget.cartItem!;
        final zero = 0;
        final hundred = 100.0;
        final net = (item.unitQty * item.selling).toDouble();
        total = net - ((item.discPer?.toDouble() ?? 0) * net / hundred);
      }
    } else {
      total = BillDiscountHandler(0).calculateApplicableTotal().toDouble();
    }
  }

  @override
  void dispose() {
    discountEditingController.dispose();
    super.dispose();
  }

  Future<double> getMaxDiscountAmount(String userCode) async {
    EasyLoading.show(status: 'please_wait'.tr());
    maxDiscountPre =
        (await AuthController().getMaxDiscountForUser(userCode)).toDouble();
    if (mounted) setState(() {});
    EasyLoading.dismiss();
    return maxDiscountPre;
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
        child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildBody(),
      ),
    ));
  }

  Widget buildBody() {
    return Column(
      children: [POSInvoiceAppBar(), Expanded(child: buildContent())],
    );
  }

  Widget buildContent() {
    if (POSConfig().defaultCheckoutLSH)
      return Row(
        children: [
          Expanded(child: buildDefaultLHS()),
          Expanded(child: buildDefaultRHS()),
        ],
      );
    else
      return Row(
        children: [
          Expanded(child: buildDefaultRHS()),
          Expanded(child: buildDefaultLHS()),
        ],
      );
  }

  // this is the default lhs in the app
  Widget buildDefaultLHS() {
    return Column(
      children: [
        widget.cartItem == null ? netDiscTitle() : productView(),
        Expanded(child: buildDiscountButtonList())
      ],
    );
  }

  Widget netDiscTitle() {
    String title = "net_bill_discount_entry_view.title".tr();

    return Container(
      width: double.infinity,
      height: height.h,
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
          child: Center(
              child: Text(
            title,
            style: CurrentTheme.bodyText2!
                .copyWith(color: CurrentTheme.primaryColor),
          )),
        ),
      ),
    );
  }

  Widget productView() {
    final product = widget.cartItem!;
    String itemName = product.posDesc;
    double mrp = product.proSelling;
    double quantity = product.unitQty;
    final textStyle = CurrentTheme.headline6!.copyWith(
        color: CurrentTheme.primaryDarkColor, fontWeight: FontWeight.w600);
    return Container(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                            text: TextSpan(style: textStyle, children: [
                          TextSpan(
                              text:
                                  "line_discount_entry_view.discount_for".tr()),
                          TextSpan(
                              text: itemName,
                              style: TextStyle(
                                  color: CurrentTheme.primaryColor,
                                  fontWeight: FontWeight.w700))
                        ])),
                        Text(
                          "line_discount_entry_view.mrp"
                              .tr(namedArgs: {"mrp": mrp.toStringAsFixed(2)}),
                          style: textStyle,
                        ),
                        Text(
                          "line_discount_entry_view.quantity"
                              .tr(namedArgs: {"qty": quantity.toString()}),
                          style: textStyle,
                        )
                      ],
                    ),
                  ),
                  Expanded(
                      flex: 1,
                      child: Container(
                          child: CachedNetworkImage(
                        httpHeaders: {'Access-Control-Allow-Origin': '*'},
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                        imageUrl: product.image ?? "",
                      )))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDiscountButtonList() {
    final config = POSConfig();

    return StreamBuilder(
      stream: discountBloc.discountTypeSteam,
      builder:
          (BuildContext context, AsyncSnapshot<List<DiscountTypes>> snapshot) {
        if (!snapshot.hasData) return Container();
        // remove unwanted discount types
        List<DiscountTypes> validButtons = (snapshot.data ?? [])
            .where((element) => element.rcDisc == true)
            .toList();
        bool billDisc = widget.cartItem == null;

        // remove unwanted line discounts
        if (billDisc) {
          validButtons = validButtons
              .where((element) => element.rcNetPer == true)
              .toList();
        } else {
          {
            validButtons = validButtons
                .where((element) => element.rcNetPer != true)
                .toList();
          }
        }

        return Container(
          child: Scrollbar(
            child: ResponsiveGridList(
              scroll: true,
              desiredItemWidth: config.paymentDynamicButtonWidth.w,
              children: (validButtons).map((payButton) {
                return discountButton(payButton);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget discountButton(DiscountTypes payButton) {
    final config = POSConfig();

    return Container(
      margin: EdgeInsets.all(POSConfig().paymentDynamicButtonPadding),
      height: config.paymentDynamicButtonHeight.h,
      child: MaterialButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(config.rounderBorderRadiusBottomLeft),
          bottomRight: Radius.circular(config.rounderBorderRadiusBottomRight),
          topRight: Radius.circular(config.rounderBorderRadiusTopRight),
          topLeft: Radius.circular(config.rounderBorderRadiusTopLeft),
        )),
        color: discountType?.diSCODE == payButton.diSCODE
            ? CurrentTheme.backgroundColor
            : CurrentTheme.primaryColor,
        child: Row(
          children: [
            SizedBox(
              width: 15.w,
            ),
            Text(
              payButton.diSDISCRIPTION ?? "",
              style: TextStyle(
                fontSize: 24.sp,
                color: CurrentTheme.primaryLightColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
           const Spacer(),
          ],
        ),
        // style: ElevatedButton.styleFrom(
        //     primary: posButton.buttonNormalColor.toColor()),
        onPressed: () {
          POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
              "${payButton.diSDISCRIPTION}(${payButton.diSCODE}) button pressed"));
          discountType = payButton;
          discountFocus.requestFocus();
          if (mounted) setState(() {});
        },
      ),
    );
  }

// this is the default rhs in the app
  Widget buildDefaultRHS() {
    return Container(
      child: Column(
        children: [
          widget.cartItem != null ? rhsLineDiscount() : rhsNetDiscount(),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: spacing.r),
              child: StreamBuilder(
                  stream: keyBoardBloc.currentPressKeyStream,
                  builder:
                      (BuildContext context, AsyncSnapshot<keyType> snapshot) {
                    return POSKeyBoard(
                        onPressed: () {
                          discountEditingController.clear();
                        },
                        onEnter: () {
                          handleDiscount();
                        },
                        isInvoiceScreen: true,
                        clearButton: true,
                        controller: discountEditingController);
                  }),
            ),
          ),
        ],
      ),
    );
  }

  Widget rhsLineDiscount() {
    return Column(
      children: [
        buildCard("line_discount_entry_view.line_total".tr(),
            (total).toStringAsFixed(2)),
        discountField(),
        buildCard("line_discount_entry_view.line_amount".tr(),
            (total - discount).toStringAsFixed(2)),
      ],
    );
  }

  Widget discountField() {
    return buildCard(
      "net_bill_discount_entry_view.discount".tr(),
      (discount).toStringAsFixed(2),
      SizedBox(
        width: 2000,
        child: TextField(
          readOnly: isMobile,
          showCursor: true,
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.end,
          focusNode: discountFocus,
          autofocus: true,
          style: CurrentTheme.bodyText2!.copyWith(
              color: CurrentTheme.primaryColor, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
              filled: true,
              suffixIcon: Text(
                !widget.discountPercentage ? "" : "%",
                style: CurrentTheme.bodyText2!.copyWith(
                    color: CurrentTheme.primaryColor,
                    fontWeight: FontWeight.w600),
              )),
          controller: discountEditingController,
          keyboardType: TextInputType.number,
          onEditingComplete: () => handleDiscount(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
          ],
        ),
      ),
    );
  }

  Widget rhsNetDiscount() {
    return Column(
      children: [
        buildCard("net_bill_discount_entry_view.sub_total".tr(),
            total.toStringAsFixed(2)),
        discountField(),
        buildCard("net_bill_discount_entry_view.net_amount".tr(),
            (total - discount).toStringAsFixed(2)),
      ],
    );
  }

  Widget buildCard(String title, String amount, [Widget? child]) {
    return Container(
      width: double.infinity,
      height: height.h,
      margin: EdgeInsets.symmetric(vertical: spacing.r),
      child: Card(
        color: CurrentTheme.primaryColor,
        margin: EdgeInsets.zero,
        child: Row(
          children: [
           const Spacer(
              flex: 1,
            ),
            Text(
              title,
              style: CurrentTheme.headline6!.copyWith(
                  color: CurrentTheme.primaryLightColor,
                  fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                child: child == null ? const SizedBox.shrink() : child,
              ),
            ),
            Container(
              width: 120.w,
              child: Text(
                amount,
                textAlign: TextAlign.end,
                style: CurrentTheme.headline6!
                    .copyWith(color: CurrentTheme.primaryLightColor),
              ),
            ),
            SizedBox(
              width: 10.w,
            ),
          ],
        ),
      ),
    );
  }

  void handleDiscount() async {
    if (clicked || initial || !mounted) {
      return;
    }
    final amount = discountEditingController.text.parseDouble();
    if (amount == 0) {
      clearDiscount();
      Navigator.pop(context);
      return;
    }
    if (amount < 0) return;

    if (discountType == null) {
      await showDialog(
        context: context,
        builder: (context) => POSErrorAlert(
            title: "discount_type_empty_error.title".tr(),
            subtitle: "discount_type_empty_error.subtitle".tr(),
            actions: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor()),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("discount_type_empty_error.okay".tr()))
            ]),
      );
    } else {
      setState(() {
        clicked = true;
      });
      //validate the discount percentage is more than 100%
      if ((widget.discountPercentage && amount > 100) ||
          (!widget.discountPercentage &&
              amount > (widget.cartItem?.amount.abs() ?? 0))) {
        await overDiscountAmount();
        return;
      } else {
        if (widget.cartItem != null)
          await handleLineDiscount();
        else
          await handleNetDiscount();
      }
    }
  }

  Future handleNetDiscount() async {
    var enteredDiscount = discountEditingController.text.parseDouble();
    String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';
    String refCode = '$invoiceNo%$enteredDiscount';
    bool hasPermission = false;
    hasPermission = SpecialPermissionHandler(context: context).hasPermission(
        permissionCode: PermissionCode.invoiceDiscount,
        accessType: "A",
        refCode: refCode);

    //if user doesnt have the permission
    String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";

    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: context)
          .askForPermission(
              permissionCode: PermissionCode.invoiceDiscount,
              accessType: "A",
              refCode: refCode);
      hasPermission = res.success;
      user = res.user;
    }
    if (!hasPermission) {
      return;
    }
    // getMaxDiscountAmount(user);

    if (enteredDiscount > 100) {
      overDiscountAmount();
      return;
    } else {
      await BillDiscountHandler(
        enteredDiscount,
      ).calculateDiscount(
          user, context, maxDiscountPre.toString().parseDouble());
      discount = total * (1 - (enteredDiscount / 100)).toDouble();
      Navigator.pop(context);
      if (mounted)
        setState(() {
          clicked = false;
        });
    }
  }

  Future overDiscountAmount() async {
    String title = "title";
    String subtitle = "subtitle";
    if (widget.discountPercentage) {
      title += '_per';
      subtitle += '_per';
    } else {
      title += '_amt';
      subtitle += '_amt';
    }
    await showDialog(
      context: context,
      builder: (context) {
        return POSErrorAlert(
            title: "discount_above_100.$title".tr(),
            subtitle: "discount_above_100.$subtitle".tr(),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        POSConfig().primaryDarkGrayColor.toColor()),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "discount_above_100.okay".tr(),
                  style: Theme.of(context).dialogTheme.contentTextStyle,
                ),
              )
            ]);
      },
    );
    discountEditingController.text = widget.discountPercentage
        ? "100"
        : (widget.cartItem?.amount ?? 0).toStringAsFixed(2);
    setState(() {
      clicked = false;
    });
  }

  void clearDiscount() async {
    if (widget.cartItem != null) {
      DiscountHandler()
          .clearDiscount(widget.discountPercentage, widget.cartItem!);
    } else {
      BillDiscountHandler(0).clearDiscount();
    }
  }

  Future handleLineDiscount() async {
    var cart = widget.cartItem!;
    if (cart.noDisc == true) {
      if (cart.allowDiscount != true) {
        return;
      }
    }
    // check override amount
    var enteredDiscount = discountEditingController.text.parseDouble();
    cart.discountReason = discountType?.diSDISCRIPTION ?? '';

    String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
    String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';

    String dollar = widget.discountPercentage ? '%' : '\$';

    String refCode =
        '$invoiceNo@${cart.proCode}*${cart.unitQty}$dollar$enteredDiscount-${cart.lineNo}';
    bool hasPermission = false;
    hasPermission = SpecialPermissionHandler(context: context).hasPermission(
        permissionCode: PermissionCode.lineDiscount,
        accessType: "A",
        refCode: refCode);

    //if user doesnt have the permission
    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: context)
          .askForPermission(
              permissionCode: PermissionCode.lineDiscount,
              accessType: "A",
              refCode: refCode);
      hasPermission = res.success;
      user = res.user;
    }

    if (!hasPermission) {
      setState(() {
        clicked = false;
      });
      return;
    }
    await getMaxDiscountAmount(user);
    discount = await DiscountHandler().manualLineDiscount(
        cart,
        enteredDiscount.toDouble(),
        widget.discountPercentage,
        maxDiscountPre,
        context,
        user,
        discountType!);
    if (mounted) setState(() {});
    if (discount != 0) {
      Navigator.pop(context);
    } else {
      if (mounted)
        setState(() {
          clicked = false;
        });
    }
  }
}
