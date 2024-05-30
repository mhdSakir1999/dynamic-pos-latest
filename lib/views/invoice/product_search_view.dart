/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/27/21, 4:20 PM
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/components/widgets/poskeyboard.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/controllers/product_controller.dart';
import 'package:checkout/controllers/usb_serial_controller.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/location_wise_stock_result.dart';
import 'package:checkout/models/pos/product_result.dart';
import 'package:checkout/models/pos/variant_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/views/invoice/returnBottle_selection_view.dart';
import 'package:checkout/views/invoice/variant_selection_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:checkout/extension/extensions.dart';
import '../../bloc/user_bloc.dart';
import '../../controllers/special_permission_handler.dart';
import '../../models/pos/permission_code.dart';
import 'invoice_app_bar.dart';
import 'package:supercharged/supercharged.dart';

/// This is the product search screen
class ProductSearchView extends StatefulWidget {
  static const routeName = "product_search";
  final String? keyword;

  const ProductSearchView({Key? key, this.keyword}) : super(key: key);

  @override
  _ProductSearchViewState createState() => _ProductSearchViewState();
}

class _ProductSearchViewState extends State<ProductSearchView> {
  TextEditingController searchEditingController = TextEditingController();
  TextEditingController qtyEditingController = TextEditingController();
  TextEditingController locationSearchController = TextEditingController();
  ScrollController scrollController = ScrollController();
  final POSPriceCalculator calculator = POSPriceCalculator();
  int _selectedIndex = -1;
  List<Product> productList = [];
  Product? selectedProduct;
  double height = 60;
  bool _sort = true;
  int _sortIndex = 1;
  FocusNode searchFocus = FocusNode();
  final FocusNode _keyboardFocus = FocusNode();
  final editingFocusNode = FocusNode();
  final addFocusNode = FocusNode();
  List<LocationStocks> locationStocks = [];
  List<LocationStocks> allLocationStocks = [];
  bool codeSearch = false;
  bool firstLetterSearch = false;
  bool combinedSearch = false;

  @override
  void initState() {
    super.initState();
    if (widget.keyword != null && widget.keyword!.isNotEmpty) {
      searchEditingController.text = widget.keyword!;
      searchItem();
    }
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
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
    return KeyboardListener(
      focusNode: _keyboardFocus,
      onKeyEvent: (value) {},
      child: Container(
        child: Row(
          children: [
            Container(width: ScreenUtil().screenWidth * 0.6, child: buildLHS()),
            SizedBox(
              width: 10.h,
            ),
            Expanded(child: buildRHS()),
          ],
        ),
      ),
    );
  }

  Future searchItem() async {
    if (searchEditingController.text.length > 2) {
      EasyLoading.show(status: 'please_wait'.tr());
      productList = await ProductController().searchProductByKeyword(
          searchEditingController.text,
          0,
          _sortIndex,
          firstLetterSearch,
          combinedSearch);
      if (mounted) setState(() {});
      EasyLoading.dismiss();
    }
  }

  Widget buildLHS() {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 15.r,
            ),
            GoBackIconButton(),
            SizedBox(
              width: 15.r,
            ),
            Expanded(
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                    fontSize: 22.sp, color: CurrentTheme.primaryColor),
                onTap: () async {
                  // KeyBoardController().dismiss();
                  if (codeSearch == true && POSConfig().touchKeyboardEnabled) {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.transparent,
                          alignment: Alignment.bottomCenter,
                          content: SizedBox(
                            width: 520.w,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    )),
                                SizedBox(
                                  height: 10.h,
                                ),
                                Tooltip(
                                  message: "product_view.code_search".tr(),
                                  child: TextField(
                                    // onEditingComplete: () => searchItem(),
                                    onSubmitted: (value) async {
                                      Navigator.pop(context);
                                      await searchItem();
                                    },
                                    controller: searchEditingController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                        hintStyle: CurrentTheme.headline6!
                                            .copyWith(
                                                color: CurrentTheme
                                                    .primaryDarkColor),
                                        hintText:
                                            "product_view.code_search".tr(),
                                        filled: true),
                                  ),
                                ),
                                SizedBox(
                                  height: 10.h,
                                ),
                                POSKeyBoard(
                                  color: Colors.transparent,
                                  onPressed: () {
                                    //_customerCodeEditingController.clear();
                                    if (searchEditingController.text.length !=
                                        0) {
                                      searchEditingController.text =
                                          searchEditingController.text
                                              .substring(
                                                  0,
                                                  searchEditingController
                                                          .text.length -
                                                      1);
                                    }
                                  },
                                  clearButton: true,
                                  isInvoiceScreen: false,
                                  disableArithmetic: true,
                                  onEnter: () async {
                                    Navigator.pop(context);
                                    await searchItem();
                                  },
                                  controller: searchEditingController,
                                  nextFocusTo: searchFocus,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    KeyBoardController().init(context);
                    KeyBoardController().showBottomDPKeyBoard(
                        searchEditingController, onEnter: () {
                      searchItem();
                    }, buildContext: context);
                  }
                },
                onEditingComplete: () => searchItem(),
                controller: searchEditingController,
                autofocus: true,
                focusNode: searchFocus,
                decoration: InputDecoration(
                    filled: true,
                    prefixIcon: Icon(
                      MaterialCommunityIcons.magnify,
                      size: 28.sp,
                    ),
                    hintText: "product_view.search_text".tr(),
                    hintStyle: TextStyle(
                        fontSize: 22.sp,
                        color: CurrentTheme.primaryColor,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 10.h,
        ),
        Expanded(child: buildItemList())
      ],
    );
  }

  Widget buildItemList() {
    final headingStyle = TextStyle(
        fontSize: POSConfig().cartDynamicButtonFontSize.sp,
        fontWeight: FontWeight.bold,
        color: CurrentTheme.primaryLightColor);

    return Container(
      width: double.infinity,
      child: Scrollbar(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              Row(
                children: [
                  _buildTitleItem(
                      text: "product_view.code".tr(), index: 0, flex: 2),
                  _buildTitleItem(
                      text: "product_view.description".tr(), index: 1, flex: 4),
                  _buildTitleItem(text: "product_view.unit".tr(), index: 2),
                  _buildTitleItem(text: "product_view.ps".tr(), index: 3),
                  _buildTitleItem(text: "product_view.selling".tr(), index: 4),
                  _buildTitleItem(
                      text: "product_view.department".tr(), index: 5, flex: 2),
                  _buildTitleItem(
                      text: "product_view.sub_department".tr(),
                      index: 6,
                      flex: 2),
                ],
              ),
              const Divider(),
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemCount: productList.length,
                itemBuilder: (context, index) => buildTableRow(index),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleItem(
      {required String text, required int index, int flex = 1}) {
    final headingStyle = TextStyle(
        fontSize: POSConfig().cartDynamicButtonFontSize.sp,
        fontWeight: FontWeight.bold,
        color: CurrentTheme.primaryLightColor);

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () {
          if (mounted) {
            _sortIndex = index;
            setState(() {
              if (text == "product_view.code".tr()) {
                codeSearch = true;
              } else {
                codeSearch = false;
              }

              if (index == 0 || index == 1) {
                combinedSearch = combinedSearch;
              } else {
                combinedSearch = false;
              }
            });
            searchFocus.requestFocus();
          }
        },
        child: Row(
          children: [
            const Spacer(),
            Text(
              text,
              style: headingStyle,
              textAlign: TextAlign.center,
            ),
            if (_sortIndex == index)
              Icon(
                Icons.arrow_downward,
                color: POSConfig().primaryLightColor.toColor(),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _selectItem(int index, Product product) {
    _selectedIndex = index;
    if (mounted) {
      editingFocusNode.requestFocus();

      setState(() {
        selectedProduct = product;
        _resetStock();
      });
    }
    _qtyKeyboard();
  }

  Widget buildTableRow(int index) {
    final Product product = productList[index];
    bool selected = product.pLUCODE == selectedProduct?.pLUCODE;
    final dataStyle = TextStyle(
        fontSize: POSConfig().cartDynamicButtonFontSize.sp * 1.3,
        color: CurrentTheme.primaryLightColor);
    return Column(
      children: <Widget>[
        ListTile(
          selected: selected,
          selectedTileColor: CurrentTheme.primaryColor,
          onTap: () => _selectItem(index, product),
          contentPadding: EdgeInsets.zero,
          title: Row(children: [
            Expanded(
                flex: 2,
                child: Text(
                  "${product.pLUCODE}",
                  textAlign: TextAlign.center,
                  style: dataStyle,
                )),
            Expanded(
              flex: 4,
              child: Text(
                "${product.pLUPOSDESC}",
                maxLines: 1,
                style: dataStyle,
              ),
            ),
            Expanded(
                child: Text(
              "${product.pluUnit}",
              textAlign: TextAlign.center,
              style: dataStyle,
            )),
            Expanded(
                child: Text(
              "${(POSConfig().comName.toUpperCase() == 'SARASAVI BOOKSHOP (PVT) LTD' ? product.vendorPLU : product.caseSize)}",
              textAlign: TextAlign.center,
              style: dataStyle,
            )),
            Expanded(
              child: Text(
                "${product.sELLINGPRICE?.thousandsSeparator() ?? "0.00"}",
                textAlign: TextAlign.right,
                style: dataStyle,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${product.department ?? ""}",
                textAlign: TextAlign.center,
                style: dataStyle,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${product.subDepartment ?? ""}",
                textAlign: TextAlign.center,
                style: dataStyle,
              ),
            ),
          ]),
        ),
        const Divider()
      ],
    );
  }

  void _qtyKeyboard() async {
    // KeyBoardController().dismiss();
    if (POSConfig().touchKeyboardEnabled) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            alignment: Alignment.bottomCenter,
            content: SizedBox(
              width: 520.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                      )),
                  SizedBox(
                    height: 10.h,
                  ),
                  Tooltip(
                    message: 'quantity',
                    child: TextField(
                      // onEditingComplete: () => searchItem(),
                      onSubmitted: (value) async {
                        Navigator.pop(context);
                        await _addQtyToCart();
                      },
                      controller: qtyEditingController,
                      autofocus: true,
                      decoration: InputDecoration(
                          hintStyle: CurrentTheme.headline6!
                              .copyWith(color: CurrentTheme.primaryDarkColor),
                          hintText: '',
                          filled: true),
                    ),
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  POSKeyBoard(
                    color: Colors.transparent,
                    onPressed: () {
                      //_customerCodeEditingController.clear();
                      if (qtyEditingController.text.length != 0) {
                        qtyEditingController.text = qtyEditingController.text
                            .substring(0, qtyEditingController.text.length - 1);
                      }
                    },
                    clearButton: true,
                    isInvoiceScreen: false,
                    disableArithmetic: true,
                    onEnter: () async {
                      Navigator.pop(context);
                      await _addQtyToCart();
                    },
                    controller: qtyEditingController,
                    nextFocusTo: editingFocusNode,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    // else {
    //   KeyBoardController().showBottomDPKeyBoard(qtyEditingController,
    //       onEnter: () async {
    //     KeyBoardController().dismiss();
    //     await _addQtyToCart();
    //   }, buildContext: context);
    // }
  }

  Widget buildRHS() {
    return Column(
      children: [
        Row(
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  children: [
                    Text('First Letter Search : ',
                        style: TextStyle(
                            fontSize: 18.sp,
                            color: CurrentTheme.primaryColor,
                            fontWeight: FontWeight.bold)),
                    Switch(
                        value: firstLetterSearch,
                        onChanged: (value) => setState(() {
                              firstLetterSearch = value;
                            })),
                    Text('Combined Search : ',
                        style: TextStyle(
                            fontSize: 18.sp,
                            color: CurrentTheme.primaryColor,
                            fontWeight: FontWeight.bold)),
                    Switch(
                        value: combinedSearch,
                        onChanged: (_sortIndex == 0 || _sortIndex == 1)
                            ? (value) => setState(() {
                                  combinedSearch = value;
                                })
                            : null),
                  ],
                ),
              ),
            ),
          ],
        ),
        selectedProduct == null
            ? SizedBox.shrink()
            : Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 10.h,
                    ),
                    rhsProduct(),
                    SizedBox(
                      height: 10.h,
                    ),
                    allLocationStocks.isNotEmpty ? _stockView() : _firstView(),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _firstView() {
    final style =
        CurrentTheme.subtitle2!.copyWith(color: CurrentTheme.primaryDarkColor);
    double width = 250.w;
    double height = 100.h;
    Color color = POSConfig().primaryDarkGrayColor.toColor();
    return Column(
      children: [
        Row(
          children: [
            Container(
                width: width,
                height: height,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: color),
                    onPressed: () {
                      String text = qtyEditingController.text;
                      if (text.isEmpty) text = "1";
                      final qty = text.parseDouble();
                      ProductController().addToLostSale(selectedProduct,
                          searchEditingController.text, qty.toDouble());
                      reset();
                    },
                    child: Text("product_view.add_to_lost_sale".tr()))),
            SizedBox(
              width: 10.w,
            ),
            SizedBox(
              width: width,
              height: height,
              child: Center(
                child: TextField(
                  onTap: () => _qtyKeyboard(),
                  onSubmitted: (value) async {
                    await _addQtyToCart();
                    // Navigator.pop(context);
                  },
                  // onEditingComplete: () => _addQtyToCart,
                  controller: qtyEditingController,
                  decoration: InputDecoration(
                    filled: true,
                  ),
                  focusNode: editingFocusNode,
                  style: style,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                ),
              ),
            )
          ],
        ),
        SizedBox(
          height: 10.h,
        ),
        Row(
          children: [
            Container(
                width: width,
                height: height,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: color),
                    onPressed: () {
                      if (selectedProduct == null) return;
                      String text = qtyEditingController.text;
                      if (text.isEmpty) text = "1";
                      final qty = text.parseDouble();
                      ProductController().reorder(selectedProduct!,
                          searchEditingController.text, qty.toDouble());
                      reset();
                    },
                    child: Text("product_view.add_to_re_order".tr()))),
            SizedBox(
              width: 10.w,
            ),
            Container(
                width: width,
                height: height,
                child: ElevatedButton(
                    focusNode: addFocusNode,
                    onPressed: _addQtyToCart,
                    child: Text("product_view.qty".tr()))),
          ],
        ),
        SizedBox(
          height: 10.h,
        ),
        Container(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: () {
                  if (selectedProduct == null) return;
                  _getStock();
                },
                child: Text(
                  "product_view.stock".tr(),
                  textAlign: TextAlign.center,
                ))),
        SizedBox(
          height: 10.h,
        ),
        Container(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: () async {
                  if (selectedProduct == null) return;

                  final List<ProVariant> res = await ProductController()
                      .getLocationWiseVariantStock(
                          selectedProduct?.pLUSTOCKCODE ?? '');
                  //EasyLoading.dismiss();
                  showModalBottomSheet(
                    isScrollControlled: true,
                    enableDrag: true,
                    context: context,
                    builder: (context) {
                      return VarientSelection(
                        variantDet: res,
                        currentProduct: selectedProduct,
                      );
                    },
                  );
                },
                child: Text(
                  "product_view.varient".tr(),
                  textAlign: TextAlign.center,
                ))),
      ],
    );
  }

  Widget _stockView() {
    double width = 250.w;
    double height = 100.h;
    Color color = POSConfig().primaryDarkGrayColor.toColor();
    final myList = locationStocks;
    final titleStyle = TextStyle(fontWeight: FontWeight.bold);
    return Column(
      children: [
        TextField(
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(fontSize: 22.sp, color: CurrentTheme.primaryColor),
          onTap: () {
            KeyBoardController().dismiss();
            KeyBoardController().init(context);
            KeyBoardController().showBottomDPKeyBoard(locationSearchController,
                onEnter: () {
              searchLocation();
            }, buildContext: context);
          },
          onChanged: (String value) {
            searchLocation();
          },
          onEditingComplete: () => searchLocation(),
          controller: locationSearchController,
          decoration: InputDecoration(
              filled: true,
              prefixIcon: Icon(
                MaterialCommunityIcons.magnify,
                size: 28.sp,
              ),
              hintText: "product_view.location_search".tr(),
              hintStyle: TextStyle(
                  fontSize: 22.sp,
                  color: CurrentTheme.primaryColor,
                  fontWeight: FontWeight.w500)),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.49,
          child: Card(
            color: CurrentTheme.primaryColor,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              physics: BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: myList.length + 1,
              itemBuilder: (context, index) {
                if (index == 0)
                  return Column(
                    children: [
                      Padding(
                        padding: REdgeInsets.symmetric(vertical: 8.h),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(
                              'product_view.location'.tr(),
                              textAlign: TextAlign.center,
                              style: titleStyle,
                            )),
                            Expanded(
                                child: Text(
                              'product_view.location_stock'.tr(),
                              textAlign: TextAlign.center,
                              style: titleStyle,
                            )),
                            Expanded(
                                child: Text(
                              'product_view.location_price'.tr(),
                              textAlign: TextAlign.center,
                              style: titleStyle,
                            )),
                          ],
                        ),
                      ),
                      const Divider()
                    ],
                  );
                final location = myList[index - 1];
                try {
                  var x = location.iplUSELL?.thousandsSeparator();
                } catch (e) {
                  print(e);
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(
                          location.loCDESC ?? '',
                          textAlign: TextAlign.center,
                        )),
                        Expanded(
                            child: Text(
                          location.iplUSIH?.qtyFormatter() ?? "0.00",
                          textAlign: TextAlign.center,
                        )),
                        Expanded(
                            child: Text(
                          (location.iplUSELL?.thousandsSeparator() ?? "0.00")
                              .toString(),
                          textAlign: TextAlign.center,
                        )),
                      ],
                    ),
                    const Divider()
                  ],
                );
              },
            ),
          ),
        ),
        Container(
            width: width,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: () {
                  _resetStock();
                },
                child: Text("product_view.reset".tr()))),
      ],
    );
  }

  void searchLocation() {
    String text = locationSearchController.text.toLowerCase();
    if (text.isEmpty) {
      locationStocks = allLocationStocks;
    } else {
      locationStocks = allLocationStocks
          .where((element) =>
              element.loCDESC?.toLowerCase().contains(text) ?? false)
          .toList();
    }
    if (mounted) setState(() {});
  }

  Future<void> _getStock() async {
    //check permission first
    String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
    String refCode = selectedProduct?.pLUCODE ?? '';
    bool hasPermission = false;
    hasPermission = SpecialPermissionHandler(context: context).hasPermission(
        permissionCode: PermissionCode.viewLocationWiseStock,
        accessType: "A",
        refCode: refCode);

    //if user doesnt have the permission
    if (!hasPermission) {
      final res = await SpecialPermissionHandler(context: context)
          .askForPermission(
              permissionCode: PermissionCode.viewLocationWiseStock,
              accessType: "A",
              refCode: refCode);
      hasPermission = res.success;
      user = res.user;
    }
    if (!hasPermission) {
      return;
    }

    EasyLoading.show(status: 'please_wait'.tr());
    locationStocks = await ProductController()
        .getLocationWiseStock(selectedProduct?.pLUCODE ?? '');
    allLocationStocks = locationStocks;
    if (mounted) {
      setState(() {});
    }
    EasyLoading.dismiss();
  }

  /// new change - adding bottle prices seperately in invoice when buying liquor items or any other
  /// Author - [TM.Sakir] at 2023-11-01 11:10 AM
  /// -------------------------------------------------------------------------------------------------
  Future<void> _addQtyToCart() async {
    String text = qtyEditingController.text;
    if (text == '0') {
      EasyLoading.showError('Invalid Quantity...\ncannot add zero quantity');
      return;
    }
    double qty = 1;

    var size = MediaQuery.of(context).size;
    TextEditingController qtyController =
        TextEditingController(text: qty.toString());
    double newqty = 1;
    if (text.isNotEmpty) {
      qty = text.parseDouble();
      qtyController.text = qty.toString();
    }

    if (selectedProduct == null) return;
    EasyLoading.show(status: 'please_wait'.tr());
    final productRes = await ProductController()
        .searchProductByBarcode(selectedProduct?.pLUCODE ?? '', qty.toDouble());
    EasyLoading.dismiss();
    if (productRes?.product == null) return;

    // empty bottles can't be sell directly which means it can only be sold along with liquir products.
    // so, even if the cashier type + qty for empty bottle, I consider it as a return scenario.
    if (productRes?.product!.first.isEmptyBottle == true) {
      qty = -1 * qty.abs();
    }

    List<CartModel?>? addedItem = await POSPriceCalculator().addItemToCart(
        productRes!.product!.first,
        qty,
        context,
        productRes.prices,
        productRes.proPrices,
        productRes.proTax,
        secondApiCall: true);

// Poll Display
//===========================================================================================================================================
    var lastItem = cartBloc.currentCart?.values.last;
    if (POSConfig().enablePollDisplay == 'true' && lastItem != null) {
      usbSerial.sendToSerialDisplay(
          '${usbSerial.addSpacesBack(lastItem.posDesc, 20)}');
      usbSerial.sendToSerialDisplay(
          'x${usbSerial.addSpacesBack(lastItem.unitQty.toString(), 5)}${usbSerial.addSpacesFront(lastItem.amount.toStringAsFixed(2), 14)}');
    }
//===========================================================================================================================================

    bool isMinus = qty < 0;
    if (productRes?.product!.first.returnBottleCode != null &&
        productRes.product!.first.returnBottleCode!.isNotEmpty &&
        addedItem != null) {
      List<String> returnBottleCodes =
          productRes.product!.first.returnBottleCode!.split(',') ?? [];
      List<ProductResult?> returnProResList = [];
      for (String code in returnBottleCodes) {
        var res = await calculator.searchProduct(code);
        if (res != null && res.product != null && res.product?.length != 0) {
          returnProResList.add(res);
        }
      }
      if (returnProResList.isNotEmpty) {
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

        // for (var item in addedItem) {
        //   // qty += item?.unitQty ?? 0;
        // itemCodeFocus.unfocus();
        // await showModalBottomSheet(
        //   enableDrag: false,
        //   isScrollControlled: true,
        //   isDismissible: false,
        //   useRootNavigator: true,
        //   context: context!,
        //   builder: (context) {
        //     return ReturnBottleSelectionView(
        //       returnProResList: returnProResList,
        //       isMinus: isMinus,
        //       defaultQty: item?.unitQty ?? 1,
        //     );
        //   },
        // );
        // itemCodeFocus.requestFocus();
        // }
        if (productRes?.emptyBottles != null &&
            productRes?.emptyBottles != [] &&
            !isMinus) {
          await showModalBottomSheet(
            enableDrag: false,
            isScrollControlled: true,
            isDismissible: false,
            useRootNavigator: true,
            context: context!,
            builder: (context) {
              return ReturnBottleSelectionView(
                returnProResList: productRes.emptyBottles!,
                isMinus: true, // it is always - since it is a return bottle
                defaultQty: qty ?? 1,
              );
            },
          );
        }
      }
    }

    // if (productRes.product?.first.returnBottleCode != null &&
    //     productRes.product!.first.returnBottleCode!.isNotEmpty) {
    //   EasyLoading.show(status: 'please_wait'.tr());
    //   var returnProRes = await POSPriceCalculator()
    //       .searchProduct(productRes.product!.first.returnBottleCode!);
    //   EasyLoading.dismiss();
    //   if (returnProRes != null &&
    //       returnProRes.product != null &&
    //       returnProRes.product?.length != 0) {
    //     await showGeneralDialog(
    //         context: context,
    //         transitionDuration: const Duration(milliseconds: 200),
    //         barrierDismissible: false,
    //         barrierLabel: '',
    //         transitionBuilder: (context, a, b, _) => Transform.scale(
    //             scale: a.value,
    //             child: AlertDialog(
    //               title: Center(
    //                   child: Text('general_dialog.empty_bottle_hed'.tr())),
    //               content: Container(
    //                 child: Column(
    //                   mainAxisSize: MainAxisSize.min,
    //                   children: [
    //                     Padding(
    //                       padding: const EdgeInsets.only(top: 10.0, bottom: 30),
    //                       child: Row(
    //                         children: [
    //                           Container(
    //                             height: 100.r,
    //                             child: CachedNetworkImage(
    //                               httpHeaders: {
    //                                 'Access-Control-Allow-Origin': '*'
    //                               },
    //                               imageUrl: (POSConfig().posImageServer +
    //                                   "images/products/" +
    //                                   returnProRes.product!.first.pLUCODE! +
    //                                   '.png'),
    //                               errorWidget: (context, url, error) =>
    //                                   Image.asset(
    //                                       'assets/images/empty_bottle.png'),
    //                               imageBuilder: (context, image) {
    //                                 return Card(
    //                                   elevation: 5,
    //                                   color: CurrentTheme.primaryColor,
    //                                   child: ClipRRect(
    //                                     borderRadius: BorderRadius.only(
    //                                       bottomLeft: Radius.circular(POSConfig()
    //                                           .rounderBorderRadiusBottomLeft),
    //                                       bottomRight: Radius.circular(POSConfig()
    //                                           .rounderBorderRadiusBottomRight),
    //                                       topLeft: Radius.circular(POSConfig()
    //                                           .rounderBorderRadiusTopLeft),
    //                                       topRight: Radius.circular(POSConfig()
    //                                           .rounderBorderRadiusTopRight),
    //                                     ),
    //                                     child: Image(
    //                                       image: image,
    //                                       fit: BoxFit.contain,
    //                                     ),
    //                                   ),
    //                                 );
    //                               },
    //                             ),
    //                           ),
    //                           Padding(
    //                             padding: const EdgeInsets.only(left: 8.0),
    //                             child: Text(
    //                                 "${returnProRes.product!.first.pLUCODE} \n${returnProRes.product!.first.pLUPOSDESC}"),
    //                           )
    //                         ],
    //                       ),
    //                     ),
    //                     Row(
    //                       children: [
    //                         SizedBox(child: Text('Quantity:')),
    //                         SizedBox(
    //                           width: 10,
    //                         ),
    //                         SizedBox(
    //                           width: size.width * 0.2,
    //                           child: TextField(
    //                             controller: qtyController,
    //                             keyboardType: TextInputType.number,
    //                             onTap: () {
    //                               qtyController.clear();
    //                               KeyBoardController().init(context);
    //                               KeyBoardController().showBottomDPKeyBoard(
    //                                   qtyController, onEnter: () async {
    //                                 newqty = double.parse(qtyController.text);
    //                                 KeyBoardController().dismiss();

    //                                 //  add to cart
    //                                 await POSPriceCalculator().addItemToCart(
    //                                   returnProRes.product!.first,
    //                                   newqty,
    //                                   context,
    //                                   returnProRes.prices,
    //                                   returnProRes.proPrices,
    //                                   returnProRes.proTax,
    //                                   secondApiCall: true,
    //                                 );
    //                                 Navigator.pop(context);
    //                               });
    //                             },
    //                             onEditingComplete: () {
    //                               newqty = double.parse(qtyController.text);
    //                             },
    //                           ),
    //                         )
    //                       ],
    //                     ),
    //                     Padding(
    //                       padding: const EdgeInsets.only(top: 16.0),
    //                       child: Row(
    //                         mainAxisAlignment: MainAxisAlignment.center,
    //                         children: [
    //                           Padding(
    //                             padding: const EdgeInsets.all(8.0),
    //                             child: ElevatedButton(
    //                                 onPressed: () async {
    //                                   //  add to cart
    //                                   await POSPriceCalculator().addItemToCart(
    //                                     returnProRes.product!.first,
    //                                     newqty,
    //                                     context,
    //                                     returnProRes.prices,
    //                                     returnProRes.proPrices,
    //                                     returnProRes.proTax,
    //                                     secondApiCall: true,
    //                                   );
    //                                   Navigator.pop(context);
    //                                 },
    //                                 child: Text('Add')),
    //                           ),
    //                           Padding(
    //                             padding: const EdgeInsets.all(8.0),
    //                             child: ElevatedButton(
    //                                 onPressed: () {
    //                                   Navigator.pop(context);
    //                                 },
    //                                 child: Text(
    //                                     'general_dialog.empty_bottle_cancel'
    //                                         .tr())),
    //                           )
    //                         ],
    //                       ),
    //                     )
    //                   ],
    //                 ),
    //               ),
    //             )),
    //         pageBuilder: (context, animation, secondaryAnimation) {
    //           return SizedBox();
    //         });
    //   }
    // }
    Navigator.pop(context);
  }

//--------------------------------------------------------------------------------------------------------------
  void reset() {
    selectedProduct = null;
    searchEditingController.clear();
    qtyEditingController.clear();
    productList = [];
    searchFocus.requestFocus();
    if (mounted) setState(() {});
  }

  Widget buildCard(String text) {
    return Container(
      height: height.h,
      width: 150.w,
      child: Card(
        margin: EdgeInsets.zero,
        color: POSConfig().primaryDarkGrayColor.toColor(),
        child: Center(
            child: Text(
          text,
          style: CurrentTheme.subtitle2,
        )),
      ),
    );
  }

  Widget rhsProduct() {
    final imageSize = 150;
    final name = selectedProduct?.pLUPOSDESC ?? "";
    final sellingPrice =
        selectedProduct?.sELLINGPRICE?.thousandsSeparator() ?? "0.00";
    final sih = selectedProduct?.sIH?.qtyFormatter() ?? "0";
    final config = POSConfig();
    final inputBorderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(config.rounderBorderRadiusBottomLeft),
      bottomRight: Radius.circular(config.rounderBorderRadiusBottomRight),
      topRight: Radius.circular(config.rounderBorderRadiusTopRight),
      topLeft: Radius.circular(config.rounderBorderRadiusTopLeft),
    );
    print(selectedProduct?.image);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: imageSize.r,
          child: Card(
            color: CurrentTheme.backgroundColor,
            elevation: 5,
            child: ClipRRect(
                borderRadius: inputBorderRadius,
                child: CachedNetworkImage(
                  imageUrl: (selectedProduct?.image ?? ""),
                  httpHeaders: {'Access-Control-Allow-Origin': '*'},
                  errorWidget: (context, url, error) => SizedBox.shrink(),
                )),
          ),
        ),
        SizedBox(
          width: 15.w,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Text(
                  name,
                  style: CurrentTheme.headline6!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                height: 25.h,
              ),
              Text("product_view.selling_price"
                  .tr(namedArgs: {"price": sellingPrice})),
              Text("product_view.sih".tr(namedArgs: {"sih": sih.toString()})),
            ],
          ),
        )
      ],
    );
  }

  _sortByCode(int columnIndex, bool ascending) {
    if (columnIndex == 0) {
      if (ascending) {
        productList
            .sort((a, b) => (a.pLUCODE ?? "").compareTo(b.pLUCODE ?? ""));
      } else {
        productList
            .sort((a, b) => (b.pLUCODE ?? "").compareTo(a.pLUCODE ?? ""));
      }
      setState(() {
        _sortIndex = columnIndex;
        _sort = !_sort;
      });
    }
    searchItem();
  }

  _sortByDesc(int columnIndex, bool ascending) {
    if (columnIndex == 1) {
      if (ascending) {
        productList
            .sort((a, b) => (a.pLUPOSDESC ?? "").compareTo(b.pLUPOSDESC ?? ""));
      } else {
        productList
            .sort((a, b) => (b.pLUPOSDESC ?? "").compareTo(a.pLUPOSDESC ?? ""));
      }
      setState(() {
        _sortIndex = columnIndex;
        _sort = !_sort;
      });
    }
    searchItem();
  }

  _sortByUnit(int columnIndex, bool ascending) {
    if (columnIndex == 2) {
      if (ascending) {
        productList
            .sort((a, b) => (a.pluUnit ?? "").compareTo(b.pluUnit ?? ""));
      } else {
        productList
            .sort((a, b) => (b.pluUnit ?? "").compareTo(a.pluUnit ?? ""));
      }
      setState(() {
        _sortIndex = columnIndex;
        _sort = !_sort;
      });
    }
    searchItem();
  }

  _sortByDepartment(int columnIndex, bool ascending) {
    if (columnIndex == 5) {
      if (ascending) {
        productList
            .sort((a, b) => (a.department ?? "").compareTo(b.department ?? ""));
      } else {
        productList
            .sort((a, b) => (b.department ?? "").compareTo(a.department ?? ""));
      }
      setState(() {
        _sortIndex = columnIndex;
        _sort = !_sort;
      });
    }
    searchItem();
  }

  _sortBySubDepartment(int columnIndex, bool ascending) {
    if (columnIndex == 6) {
      if (ascending) {
        productList.sort(
            (a, b) => (a.subDepartment ?? "").compareTo(b.subDepartment ?? ""));
      } else {
        productList.sort(
            (a, b) => (b.subDepartment ?? "").compareTo(a.subDepartment ?? ""));
      }
      setState(() {
        _sortIndex = columnIndex;
        _sort = !_sort;
      });
    }
    searchItem();
  }

  _sortByPS(int columnIndex, bool ascending) {
    if (columnIndex == 3) {
      if (ascending) {
        productList
            .sort((a, b) => (a.caseSize ?? 0).compareTo(b.caseSize ?? 0));
      } else {
        productList
            .sort((a, b) => (b.caseSize ?? 0).compareTo(a.caseSize ?? 0));
      }
      setState(() {
        _sortIndex = columnIndex;
        _sort = !_sort;
      });
    }
    searchItem();
  }

  _sortByPrice(int columnIndex, bool ascending) {
    if (columnIndex == 4) {
      if (ascending) {
        productList.sort(
            (a, b) => (a.sELLINGPRICE ?? 0).compareTo(b.sELLINGPRICE ?? 0));
      } else {
        productList.sort(
            (a, b) => (b.sELLINGPRICE ?? 0).compareTo(a.sELLINGPRICE ?? 0));
      }
      setState(() {
        _sortIndex = columnIndex;
        _sort = !_sort;
      });
    }
    searchItem();
  }

  void _resetStock() {
    allLocationStocks = [];
    locationStocks = [];
    locationSearchController.clear();
    if (mounted) setState(() {});
  }
}
