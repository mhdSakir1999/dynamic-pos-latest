/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 7/12/21, 5:24 PM
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/group_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/mypos_screen_utils.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/components/widgets/poskeyboard.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/controllers/product_controller.dart';
import 'package:checkout/models/pos/GroupResults.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/product_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/views/invoice/invoice_app_bar.dart';
import 'package:checkout/views/invoice/returnBottle_selection_view.dart';

import 'package:flutter/material.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:responsive_grid/responsive_grid.dart';

import '../../controllers/keyboard_controller.dart';

class WeightedItemView extends StatefulWidget {
  @override
  _WeightedItemViewState createState() => _WeightedItemViewState();
}

class _WeightedItemViewState extends State<WeightedItemView> {
  TextEditingController editingController = TextEditingController();
  final POSPriceCalculator calculator = POSPriceCalculator();
  FocusNode textFocus = FocusNode();
  bool quickSearch = true;
  Groups? selectedGroup;
  POSConfig config = POSConfig();
  final desireWidthMultiplier = .25;
  Product? selectedProduct;
  double qty = 0;
  List<Product> productList = [];
  _ViewStatus _viewStatus = _ViewStatus.Department;
  bool active = false;
  ScrollController scrollController = ScrollController();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1)).then((value) {
      if (mounted)
        setState(() {
          active = true;
        });
    });
    editingController.addListener(() {
      handleTxtValueChange();
    });
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          child: POSInvoiceAppBar(),
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
          child: buildBody(),
        )),
      ],
    ));
  }

  Widget lineSpace() {
    return SizedBox(
      height: 8.h,
    );
  }

  Widget buildBody() {
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

  Widget buildDefaultLHS() {
    return Column(
      children: [
        Card(
            child: Padding(
          padding: EdgeInsets.all(6.0.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 8.w,
                  ),
                  GoBackIconButton(
                    onPressed: handleBack,
                  ),
                  SizedBox(
                    width: 8.w,
                  ),
                  Text(
                    "weighted_item.title".tr(),
                    style: CurrentTheme.bodyText2!.copyWith(
                        color: CurrentTheme.primaryColor,
                        fontSize: 15 * getFontSize()),
                  ),
                ],
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.only(top: 10, bottom: 10)),
                  onPressed: () {
                    switch (_viewStatus) {
                      case _ViewStatus.Department:
                        Navigator.pop(context);
                        return;
                      case _ViewStatus.Product:
                        clear();
                        Navigator.pop(context);
                        break;
                    }
                    if (mounted) setState(() {});
                    textFocus.requestFocus();
                  },
                  child: const Text('exit'))
            ],
          ),
        )),
        Expanded(child: buildLSHContent()),
        _viewStatus != _ViewStatus.Product
            ? const SizedBox.shrink()
            : lineSpace(),
        _viewStatus != _ViewStatus.Product
            ? const SizedBox.shrink()
            : buildBottomCard(),
        _viewStatus != _ViewStatus.Product
            ? const SizedBox.shrink()
            : buildGroupDetailsCard(),
        _viewStatus != _ViewStatus.Product
            ? const SizedBox.shrink()
            : buildProductDetailsCard(),
      ],
    );
  }

  // this will handle which card to show on lhs bottom
  Widget buildBottomCard() {
    return StreamBuilder(
      stream: cartBloc.currentCartSnapshot,
      builder: (BuildContext context,
          AsyncSnapshot<Map<String, CartModel>> snapshot) {
        if (snapshot.data != null && (snapshot.data?.length ?? 0) > 0)
          return Padding(
            padding: EdgeInsets.only(left: 8.r, right: 8.r, bottom: 4.r),
            child: buildPriceCard(),
          );
        return const SizedBox.shrink();
      },
    );
  }

  // this will return the lhs bottom price card
  Widget buildPriceCard() {
    final style1 =
        CurrentTheme.bodyText1!.copyWith(color: CurrentTheme.primaryLightColor);
    final style1Bold = style1.copyWith(
        fontWeight: FontWeight.bold, fontSize: 10 * getFontSize());
    // final style2 = CurrentTheme.headline4!.copyWith(
    //     color: CurrentTheme.primaryLightColor, fontSize: 10 * getFontSize());
    // final style2Bold = style2.copyWith(
    //     fontWeight: FontWeight.bold, fontSize: 10 * getFontSize());
    return StreamBuilder<CartSummaryModel>(
        stream: cartBloc.cartSummarySnapshot,
        builder: (context, AsyncSnapshot<CartSummaryModel> snapshot) {
          final data = snapshot.data;
          String items = "${data?.items ?? 0}";
          String qty = data?.qty.qtyFormatter() ?? "0.0";
          String subtotal = "${(data?.subTotal ?? 0).thousandsSeparator()}";
          // String lines = "";

          return Card(
              color: CurrentTheme.primaryColor,
              margin: EdgeInsets.zero,
              child: Container(
                padding: EdgeInsets.all(8.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      'invoice.item'.tr() + ':',
                      style: style1,
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                    Text(
                      items,
                      style: style1Bold,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'invoice.quantity'.tr() + ':',
                      style: style1,
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                    Text(
                      qty,
                      style: style1Bold,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'invoice.sub_total'.tr() + ':',
                      style: style1,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      subtotal,
                      style: style1Bold,
                    ),
                    const Spacer(),
                  ],
                ),
              ));
        });
  }

  /// Build lhs contents base on the view status
  Widget buildLSHContent() {
    switch (_viewStatus) {
      case _ViewStatus.Department:
        return buildGroupList();
      case _ViewStatus.Product:
        return buildProductList();
    }
  }

  Widget buildGroupList() {
    return Container(
      child: Scrollbar(
        child: StreamBuilder<GroupResults?>(
          stream: groupBloc.getDepartmentSteam,
          builder: (context, AsyncSnapshot<GroupResults?> snapshot) {
            if (!snapshot.hasData) return Container();
            List<Groups> list = snapshot.data?.groups ?? [];

            return ResponsiveGridList(
              scroll: true,
              squareCells: true,
              desiredItemWidth:
                  config.paymentDynamicButtonWidth.w * desireWidthMultiplier,
              children: list.map((button) {
                bool selected = selectedGroup != null &&
                    button.gPCODE == selectedGroup?.gPCODE;
                return customButton(
                  name: button.gPDESC ?? "",
                  image: config.posImageServer +
                      "images/groups/${button.gPTABLE}/${button.gPCODE}.png",
                  selected: selected,
                  onPressed: () async {
                    clear();
                    selectedGroup = button;
                    if (mounted) {
                      setState(() {});
                    }
                    EasyLoading.show(status: 'please_wait'.tr());
                    final list = await ProductController().getWeightedProducts(
                        button.gPTABLE ?? "", button.gPCODE ?? "");
                    EasyLoading.dismiss();
                    if (list.length > 0) {
                      _viewStatus = _ViewStatus.Product;
                      productList = list;
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget buildProductList() {
    return Container(
      child: Scrollbar(
        controller: _scrollController,
        child: ResponsiveGridList(
          controller: _scrollController,
          scroll: true,
          squareCells: true,
          physics: BouncingScrollPhysics(),
          desiredItemWidth:
              config.paymentDynamicButtonWidth.w * desireWidthMultiplier,
          children: productList.map((button) {
            bool selected = selectedProduct != null &&
                button.pLUSTOCKCODE == selectedProduct?.pLUSTOCKCODE;
            return customButton(
              name: button.pLUPOSDESC ?? "",
              image: button.image ?? "",
              selected: selected,
              onPressed: () async {
                if (selected) {
                  selectedProduct = null;
                } else {
                  quickSearch = false;
                  textFocus.requestFocus();
                  selectedProduct = button;
                }
                if (mounted) {
                  setState(() {});
                }
                textFocus.requestFocus();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget customButton(
      {required String name,
      required String image,
      required VoidCallback onPressed,
      required bool selected}) {
    final color =
        selected ? CurrentTheme.primaryColor : CurrentTheme.primaryLightColor;

    final style = CurrentTheme.overline!.copyWith(fontWeight: FontWeight.bold);
    print(image);
    return Card(
      color: color,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          child: Column(
            children: [
              Expanded(
                  child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft:
                      Radius.circular(config.rounderBorderRadiusBottomLeft),
                  bottomRight:
                      Radius.circular(config.rounderBorderRadiusBottomRight),
                  topRight: Radius.circular(config.rounderBorderRadiusTopRight),
                  topLeft: Radius.circular(config.rounderBorderRadiusTopLeft),
                ),
                child: CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  httpHeaders: {'Access-Control-Allow-Origin': '*'},
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              )),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child:
                    // SizedBox(
                    //     height: 20,
                    //     child: Marquee(
                    //       text: name,
                    //       style: style,
                    //       velocity: 20,
                    //       pauseAfterRound: Duration(milliseconds: 700),
                    //     ))
                    Text(
                  name,
                  style: style,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  maxLines: 3,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // this method return the cart list
  Widget buildCartList() {
    // final headingStyle = TextStyle(
    //     fontSize: POSConfig().cartDynamicButtonFontSize.sp,
    //     fontWeight: FontWeight.bold,
    //     color: CurrentTheme.primaryLightColor);
    // final dataStyle = TextStyle(
    //     fontSize: POSConfig().cartDynamicButtonFontSize.sp,
    //     color: CurrentTheme.primaryLightColor);

    return StreamBuilder<Map<String, CartModel>>(
        stream: cartBloc.currentCartSnapshot,
        builder: (context, AsyncSnapshot<Map<String, CartModel>> snapshot) {
          scrollToBottom();
          final map = snapshot.data;
          int length = 0;
          if (map != null) {
            length = map.values.length;
          }
          return ListView.builder(
            controller: scrollController,
            itemCount: length,
            shrinkWrap: true,
            reverse: false,
            physics: BouncingScrollPhysics(),
            itemBuilder: (context, index) =>
                buildCartCard(map!.values.toList()[index]),
          );
        });
  }

  // this method build the card based cart item list
  Widget buildCartCard(CartModel cartModel) {
    // bool voided = (cartModel.itemVoid ?? false);
    final style = CurrentTheme.bodyText1!.copyWith(
        color: CurrentTheme.primaryLightColor,
        fontSize: (POSConfig().cardFontSize).sp);

    String? discountText;

    final zero = 0;
    if ((cartModel.discPer ?? zero) > zero) {
      discountText = "${cartModel.discPer?.toStringAsFixed(2)}%";
    } else if ((cartModel.discAmt ?? zero) > zero) {
      discountText = "Rs. ${cartModel.discAmt?.toStringAsFixed(2)}";
    } else if ((cartModel.billDiscPer ?? zero) > zero) {
      discountText = "${cartModel.billDiscPer?.toStringAsFixed(2)}%";
    }
    String code = cartModel.stockCode;
    if (code.isEmpty) {
      code = cartModel.proCode;
    }
    return Card(
        color: CurrentTheme.primaryColor,
        child: Padding(
          padding: EdgeInsets.all(5.r),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Row(
                children: [
                  Container(
                    height: 30.r,
                    child: CachedNetworkImage(
                      httpHeaders: {'Access-Control-Allow-Origin': '*'},
                      imageUrl: (cartModel.image ??
                          "images/products/" + cartModel.proCode + '.png'),
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                      imageBuilder: (context, image) {
                        return Card(
                          elevation: 5,
                          color: CurrentTheme.primaryColor,
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(
                                  POSConfig().rounderBorderRadiusBottomLeft),
                              bottomRight: Radius.circular(
                                  POSConfig().rounderBorderRadiusBottomRight),
                              topLeft: Radius.circular(
                                  POSConfig().rounderBorderRadiusTopLeft),
                              topRight: Radius.circular(
                                  POSConfig().rounderBorderRadiusTopRight),
                            ),
                            child: Image(
                              image: image,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                    width: POSConfig().cardIdLength.w,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "$code",
                                        style: style.copyWith(
                                            fontSize: 10 * getFontSize()),
                                      ),
                                    )),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Container(
                                      width: POSConfig().cardNameLength == 0
                                          ? double.infinity
                                          : POSConfig().cardNameLength.w,
                                      child: Text(
                                        "${cartModel.noDisc ? "* " : ""}${cartModel.posDesc}",
                                        style: style.copyWith(
                                            fontSize: 10 * getFontSize()),
                                      )),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Spacer(),
                                // SizedBox(width: POSConfig().cardIdLength.w,
                                //     ),
                                Container(
                                    width: POSConfig().cardPriceLength.w,
                                    child: Text(
                                      "${(cartModel.selling).thousandsSeparator()}",
                                      style: style.copyWith(
                                          fontSize: 10 * getFontSize()),
                                      textAlign: TextAlign.end,
                                    )),
                                Container(
                                    width: POSConfig().cardQtyLength.w,
                                    child: Text(
                                      cartModel.unitQty.qtyFormatter(),
                                      style: style.copyWith(
                                          fontSize: 10 * getFontSize()),
                                      textAlign: TextAlign.end,
                                    )),
                                Container(
                                    width: POSConfig().cardTotalLength.w,
                                    child: Text(
                                      "${(cartModel.amount).thousandsSeparator()}",
                                      style: style.copyWith(
                                          fontSize: 10 * getFontSize()),
                                      textAlign: TextAlign.end,
                                    )),
                              ],
                            ),
                          ],
                        ),
                        discountText == null
                            ? const SizedBox.shrink()
                            : Positioned(
                                right: 0,
                                child: Card(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 5),
                                    child: Text(discountText),
                                  ),
                                  color: Colors.deepOrange,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  void scrollToBottom() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      } else {
        if (mounted) setState(() => null);
      }
    });
  }

  Widget buildDefaultRHS() {
    return Column(
      children: [
        Container(
            height: MediaQuery.of(context).size.height * 0.45,
            child: buildCartList()),
        lineSpace(),
        TextField(
          autofocus: true,
          focusNode: textFocus,
          controller: editingController,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          onEditingComplete: handleEnterPress,
          onTap: () {
            if (!quickSearch) {
              return;
            }
            KeyBoardController().dismiss();
            KeyBoardController().showBottomDPKeyBoard(editingController,
                buildContext: context, onEnter: () {
              handleEnterPress();
              KeyBoardController().dismiss();
            });
          },
          decoration: InputDecoration(
            filled: true,
            hintText:
                "weighted_item.${quickSearch ? "quick_search" : "qty"}".tr(),
            prefixIcon: Icon(Icons.search),
          ),
        ),
        lineSpace(),
        Expanded(
          child: POSKeyBoard(
            onEnter: () {
              if (active) handleEnterPress();
              textFocus.requestFocus();
            },
            onPressed: () {
              if (active) editingController.clear();
              textFocus.requestFocus();
            },
            isInvoiceScreen: false,
            clearButton: true,
            controller: editingController,
            nextFocusTo: textFocus,
          ),
        )
      ],
    );
  }

  /// This card will show the selected item's group card
  Widget buildGroupDetailsCard() {
    final style = CurrentTheme.subtitle2;
    final String code = selectedGroup?.gPCODE ?? "";
    final String desc = selectedGroup?.gPDESC ?? "";
    return Card(
      color: CurrentTheme.primaryColor,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(8.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                "weighted_item.group_master_code".tr(namedArgs: {"code": code}),
                overflow: TextOverflow.ellipsis,
                style: style!.copyWith(fontSize: 10 * getFontSize()),
              ),
            ),
            Expanded(
              flex: 7,
              child: Text(
                "weighted_item.group_master_desc".tr(namedArgs: {"desc": desc}),
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(fontSize: 10 * getFontSize()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// This card show the item details
  Widget buildProductDetailsCard() {
    final String code = selectedProduct?.pLUCODE ?? "";
    final String desc = selectedProduct?.pLUPOSDESC ?? "";
    final price = selectedProduct?.sELLINGPRICE ?? 0;
    final String mrp = price.thousandsSeparator();
    final String qty = this.qty.toString();

    final style = CurrentTheme.subtitle2;
    return Card(
      color: CurrentTheme.primaryColor,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(8.r),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "weighted_item.product_code".tr(namedArgs: {"code": code}),
                  style: style!.copyWith(fontSize: 10 * getFontSize()),
                ),
                Text(
                  "weighted_item.product_name".tr(namedArgs: {"name": desc}),
                  style: style.copyWith(fontSize: 10 * getFontSize()),
                ),
                Text(
                  "weighted_item.mpr".tr(namedArgs: {"mrp": mrp}),
                  style: style.copyWith(fontSize: 10 * getFontSize()),
                ),
                Text(
                  "weighted_item.quantity".tr(namedArgs: {"qty": qty}),
                  style: style.copyWith(fontSize: 10 * getFontSize()),
                ),
                Text(
                  "weighted_item.line_amount".tr(namedArgs: {
                    "total": (this.qty * price).thousandsSeparator()
                  }),
                  style: style.copyWith(fontSize: 10 * getFontSize()),
                ),
              ],
            ),
            Positioned(
              right: 40.w,
              bottom: 10.h,
              child: Row(
                children: [
                  IconButton(
                      onPressed: decrementQty,
                      icon: const Icon(
                        FontAwesome.minus_circle,
                      ),
                      iconSize: 40.r,
                      color: Colors.redAccent),
                  SizedBox(
                    width: 15.w,
                  ),
                  IconButton(
                    onPressed: incrementQty,
                    icon: const Icon(
                      FontAwesome.plus_circle,
                    ),
                    iconSize: 40.r,
                    color: Colors.greenAccent,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// this method will increment the qty
  void incrementQty() {
    if (!quickSearch) {
      if (qty == (POSConfig().setup?.maxQtyLimit ?? 0) &&
          (POSConfig().setup?.maxQtyLimit ?? 0) > 0) {
        EasyLoading.showError('invoice.max_qty_limit_exceed'.tr() +
            '\n Maximum quantity can be punched is limited to ${(POSConfig().setup?.maxQtyLimit ?? 0)}');
        return;
      }
      this.qty = this.qty + 1;
      editingController.text = qty.toStringAsFixed(2);
      editingController.selection = TextSelection.fromPosition(
          TextPosition(offset: editingController.text.length));
    }
    if (mounted) setState(() {});
    textFocus.requestFocus();
  }

  /// this method will decrement the qty
  void decrementQty() {
    if (!quickSearch) {
      this.qty = this.qty - 1;
      editingController.text = qty.toStringAsFixed(2);
      editingController.selection = TextSelection.fromPosition(
          TextPosition(offset: editingController.text.length));
    }
    if (mounted) setState(() {});
    textFocus.requestFocus();
  }

  /// this method used to handle the back button
  void handleBack() {
    switch (_viewStatus) {
      case _ViewStatus.Department:
        Navigator.pop(context);
        return;
      case _ViewStatus.Product:
        clear();
        textFocus.requestFocus();
        break;
    }
    if (mounted) setState(() {});
  }

  /// this method used to handle enter key press event
  void handleEnterPress() {
    if (quickSearch) {
      quickSearchItem();
    } else {
      addItem();
    }
  }

  /// this method used to handle the text field value changes
  void handleTxtValueChange() {
    final val = editingController.text;
    if (!quickSearch) {
      final qty = val.parseDouble();
      this.qty = qty;
    }
    if (mounted) setState(() {});
  }

  /// add item in to the cart
  Future<void> addItem() async {
    if (qty == 0) {
      qty = 1;
    }

    if (qty > (POSConfig().setup?.maxQtyLimit ?? 0) &&
        (POSConfig().setup?.maxQtyLimit ?? 0) > 0) {
      EasyLoading.showError('invoice.max_qty_limit_exceed'.tr() +
          '\n Maximum quantity can be punched is limited to ${(POSConfig().setup?.maxQtyLimit ?? 0)}');
      return;
    }

    if (selectedProduct == null)
      return;
    else {
      var myProduct = selectedProduct;
      if (!quickSearch) {
        myProduct = (await ProductController()
            .getWeightedProductByID(myProduct!.pLUCODE ?? ''))!['product'];
      }

      // empty bottles can't be sell directly which means it can only be sold along with liquir products.
      // so, even if the cashier type + qty for empty bottle, I consider it as a return scenario.
      if (myProduct?.isEmptyBottle == true) {
        qty = -1 * qty.abs();
      }

      /// new change - adding bottle prices seperately in invoice when buying liquor items [or maybe any other]
      /// Author : [TM.Sakir] at 2023-11-01 11:10 AM
      /// -------------------------------------------------------------------------------------------------
      // var size = MediaQuery.of(context).size;
      // TextEditingController qtyController =
      //     TextEditingController(text: qty.toString());
      // double newqty = 1;
      await POSPriceCalculator().addItemToCart(
          myProduct!, qty, context, null, null, null,
          secondApiCall: true, successToast: false);
      bool isMinus = qty < 0;
      if (myProduct.returnBottleCode != null &&
          myProduct.returnBottleCode!.isNotEmpty) {
        List<String> returnBottleCodes =
            myProduct.returnBottleCode!.split(',') ?? [];
        List<ProductResult?> returnProResList = [];
        for (String code in returnBottleCodes) {
          var res = await calculator.searchProduct(code);
          if (res != null && res.product != null && res.product?.length != 0) {
            returnProResList.add(res);
          }
        }
        if (returnProResList.isNotEmpty) {
          // await showModalBottomSheet(
          //   enableDrag: false,
          //   isScrollControlled: true,
          //   useRootNavigator: true,
          //   context: context!,
          //   builder: (context) {
          //     return ReturnBottleSelectionView(
          //       returnProResList: returnProResList,
          //       isMinus: isMinus,
          //       defaultQty: qty ?? 1,
          //     );
          //   },
          // );
          try {
            ProductResult bottle = returnProResList.first!;
            List<CartModel?>? addedBottle = await calculator.addItemToCart(
                bottle.product!.first,
                qty,
                context,
                bottle.prices,
                bottle.proPrices,
                bottle.proTax,
                secondApiCall: false,
                scaleBarcode: false);

            if (addedBottle == null) {
              EasyLoading.showError('Cannot add the bottle to the invoice');
            }
          } catch (e) {}

          var resList =
              await calculator.searchProduct(selectedProduct!.pLUCODE!);

          if (resList?.emptyBottles != null &&
              resList?.emptyBottles != [] &&
              !isMinus) {
            await showModalBottomSheet(
              enableDrag: false,
              isScrollControlled: true,
              isDismissible: false,
              useRootNavigator: true,
              context: context,
              builder: (context) {
                return ReturnBottleSelectionView(
                  returnProResList: resList!.emptyBottles!,
                  isMinus: true, // it is always - since it is a return bottle
                  defaultQty: qty ?? 1,
                );
              },
            );
          }
        }
        // var returnProRes = await POSPriceCalculator()
        //     .searchProduct(myProduct.returnBottleCode!);
        // if (returnProRes != null && returnProRes.product != null) {
        //   await showGeneralDialog(
        //       context: context,
        //       transitionDuration: const Duration(milliseconds: 200),
        //       barrierDismissible: false,
        //       barrierLabel: '',
        //       transitionBuilder: (context, a, b, _) => Transform.scale(
        //           scale: a.value,
        //           child: AlertDialog(
        //             title: Center(child: Text('Invoicing the bottles')),
        //             content: Container(
        //               child: Column(
        //                 mainAxisSize: MainAxisSize.min,
        //                 children: [
        //                   Padding(
        //                     padding:
        //                         const EdgeInsets.only(top: 10.0, bottom: 30),
        //                     child: Row(
        //                       children: [
        //                         Container(
        //                           height: 100.r,
        //                           child: CachedNetworkImage(
        //                             httpHeaders: {
        //                               'Access-Control-Allow-Origin': '*'
        //                             },
        //                             imageUrl: (POSConfig().posImageServer +
        //                                 "images/products/" +
        //                                 returnProRes.product!.first.pLUCODE! +
        //                                 '.png'),
        //                             errorWidget: (context, url, error) =>
        //                                 Image.asset(
        //                                     'assets/images/empty_bottle.png'),
        //                             imageBuilder: (context, image) {
        //                               return Card(
        //                                 elevation: 5,
        //                                 color: CurrentTheme.primaryColor,
        //                                 child: ClipRRect(
        //                                   borderRadius: BorderRadius.only(
        //                                     bottomLeft: Radius.circular(POSConfig()
        //                                         .rounderBorderRadiusBottomLeft),
        //                                     bottomRight: Radius.circular(POSConfig()
        //                                         .rounderBorderRadiusBottomRight),
        //                                     topLeft: Radius.circular(POSConfig()
        //                                         .rounderBorderRadiusTopLeft),
        //                                     topRight: Radius.circular(POSConfig()
        //                                         .rounderBorderRadiusTopRight),
        //                                   ),
        //                                   child: Image(
        //                                     image: image,
        //                                     fit: BoxFit.contain,
        //                                   ),
        //                                 ),
        //                               );
        //                             },
        //                           ),
        //                         ),
        //                         Padding(
        //                           padding: const EdgeInsets.only(left: 8.0),
        //                           child: Text(
        //                               "${returnProRes.product!.first.pLUCODE} \n${returnProRes.product!.first.pLUPOSDESC}"),
        //                         )
        //                       ],
        //                     ),
        //                   ),
        //                   Row(
        //                     children: [
        //                       SizedBox(child: Text('Quantity:')),
        //                       SizedBox(
        //                         width: 10,
        //                       ),
        //                       SizedBox(
        //                         width: size.width * 0.2,
        //                         child: TextField(
        //                           controller: qtyController,
        //                           keyboardType: TextInputType.number,
        //                           onTap: () {
        //                             qtyController.clear();
        //                             KeyBoardController().init(context);
        //                             KeyBoardController().showBottomDPKeyBoard(
        //                                 qtyController, onEnter: () async {
        //                               newqty = double.parse(qtyController.text);
        //                               KeyBoardController().dismiss();

        //                               //  add to cart
        //                               await POSPriceCalculator().addItemToCart(
        //                                   returnProRes.product!.first,
        //                                   newqty,
        //                                   context,
        //                                   returnProRes.prices,
        //                                   returnProRes.proPrices,
        //                                   returnProRes.proTax,
        //                                   secondApiCall: false,
        //                                   successToast: false);
        //                             });
        //                             Navigator.pop(context);
        //                           },
        //                           onEditingComplete: () {
        //                             newqty = double.parse(qtyController.text);
        //                           },
        //                         ),
        //                       )
        //                     ],
        //                   ),
        //                   Padding(
        //                     padding: const EdgeInsets.only(top: 16.0),
        //                     child: Row(
        //                       mainAxisAlignment: MainAxisAlignment.center,
        //                       children: [
        //                         Padding(
        //                           padding: const EdgeInsets.all(8.0),
        //                           child: ElevatedButton(
        //                               onPressed: () async {
        //                                 //  add to cart
        //                                 await POSPriceCalculator()
        //                                     .addItemToCart(
        //                                         returnProRes.product!.first,
        //                                         newqty,
        //                                         context,
        //                                         returnProRes.prices,
        //                                         returnProRes.proPrices,
        //                                         returnProRes.proTax,
        //                                         secondApiCall: false,
        //                                         successToast: false);
        //                                 Navigator.pop(context);
        //                               },
        //                               child: Text('Add')),
        //                         ),
        //                         Padding(
        //                           padding: const EdgeInsets.all(8.0),
        //                           child: ElevatedButton(
        //                               onPressed: () {
        //                                 Navigator.pop(context);
        //                               },
        //                               child: Text('Cancel')),
        //                         )
        //                       ],
        //                     ),
        //                   )
        //                 ],
        //               ),
        //             ),
        //           )),
        //       pageBuilder: (context, animation, secondaryAnimation) {
        //         return SizedBox();
        //       });
        // }
      }
//-----------------------------------------------------------------------------------------------------------------
      clear(stayInItem: true);
    }
  }

  ///clear view
  void clear({bool stayInItem = false}) {
    if (!stayInItem) _viewStatus = _ViewStatus.Department;
    selectedProduct = null;
    selectedGroup = null;
    editingController.clear();
    quickSearch = true;
    qty = 0;
  }

  /// quick search item by id
  void quickSearchItem() async {
    EasyLoading.show(status: 'please_wait'.tr());
    String input = editingController.text.contains('*')
        ? editingController.text.split('*')[1]
        : editingController.text;
    final resultMap = await ProductController().getWeightedProductByID(input);
    EasyLoading.dismiss();
    if (resultMap == null) return;

    final group = resultMap["group"];
    final product = resultMap["product"];
    selectedGroup = group;
    selectedProduct = product;

    if (editingController.text.contains('*')) {
      try {
        qty = double.parse(editingController.text.split('*')[0]);
        addItem();
        editingController.clear();
        return;
      } catch (e) {
        EasyLoading.showError('Invalid quantity or product code');
        editingController.clear();
        return;
      }
    }
    _viewStatus = _ViewStatus.Product;
    quickSearch = false;
    editingController.clear();
    if (mounted) setState(() {});
    // straightly add the product with qty=1
    // addItem();
  }

  @override
  void dispose() {
    editingController.dispose();
    super.dispose();
  }
}

enum _ViewStatus { Department, Product }
