/// Author: [TM.Sakir] at 2023-11-28 4:03PM
/// Used to view varients of a product and pick a desired varient

import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/controllers/product_controller.dart';
import 'package:checkout/models/pos/product_result.dart';
import 'package:checkout/models/pos/variant_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/mypos_screen_utils.dart';
import '../../components/widgets/go_back.dart';
import '../../models/pos_config.dart';
import '../invoice/invoice_app_bar.dart';

class VarientSelection extends StatefulWidget {
  final List<ProVariant> variantDet;
  final Product? currentProduct;

  const VarientSelection(
      {Key? key, required this.variantDet, this.currentProduct})
      : super(key: key);

  @override
  State<VarientSelection> createState() => _VarientSelectionState();
}

class _VarientSelectionState extends State<VarientSelection> {
  List<ProVariant> stk = [];
  late List<ProVariant> variantDet;
  final searchController = TextEditingController();
  final qtyController = TextEditingController();
  double qty = 1;
  final ScrollController _scrollController = ScrollController();
  String proImage = '';
  String proCode = '';
  String prodesc = '';
  ProVariant? selectedProduct;

  @override
  initState() {
    super.initState();
    variantDet = widget.variantDet;
    stk = variantDet;
    selectedProduct = stk.firstWhere(
        (element) => element.ipLUPRODUCTCODE == widget.currentProduct?.pLUCODE);
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
      child: SafeArea(
        child: SingleChildScrollView(
            child: Column(children: [
          POSInvoiceAppBar(),
          Card(
            color: CurrentTheme.primaryColor,
            margin: EdgeInsets.zero,
            child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 8,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    GoBackIconButton(),
                    const Spacer(),
                  ],
                )),
          ),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Container(
                            height: 50,
                            width: 500,
                            margin: EdgeInsets.only(right: 16),
                            child: TextField(
                              onTap: () {
                                KeyBoardController().dismiss();
                                KeyBoardController().init(context);
                                KeyBoardController().showBottomDPKeyBoard(
                                    searchController, onEnter: () {
                                  searchItem();
                                  KeyBoardController().dismiss();
                                });
                              },
                              onEditingComplete: () => searchItem(),
                              readOnly: isMobile,
                              textAlign: TextAlign.center,
                              autofocus: true,
                              controller: searchController,
                              // showCursor: false,

                              textInputAction: TextInputAction.done,

                              decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  filled: true,
                                  hintText: "Scan the barcode to search"),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 16),
                          height: 50,
                          width: 250,
                          child: Row(
                            children: [
                              const Text('Qty: '),
                              const Spacer(),
                              Container(
                                height: 50,
                                width: 200,
                                child: TextField(
                                  onTap: () {
                                    KeyBoardController().dismiss();
                                    KeyBoardController().init(context);
                                    KeyBoardController().showBottomDPKeyBoard(
                                        qtyController, onEnter: () {
                                      KeyBoardController().dismiss();
                                    });
                                  },
                                  onEditingComplete: () {
                                    qty = double.tryParse(qtyController.text) ??
                                        1;
                                  },
                                  readOnly: isMobile,
                                  textAlign: TextAlign.center,
                                  autofocus: true,
                                  controller: qtyController,
                                  // showCursor: false,

                                  textInputAction: TextInputAction.done,

                                  decoration: const InputDecoration(
                                      filled: true,
                                      hintText: "Enter the quantity"),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Container(
                          height: 500,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [_buildVarientSelection()],
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ])),
      ),
    );
  }

  Container _buildImage(String imgUrl, String product) {
    return Container(
      height: 600,
      child: Card(
        elevation: 5,
        color: CurrentTheme.primaryColor,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft:
                Radius.circular(POSConfig().rounderBorderRadiusBottomLeft),
            bottomRight:
                Radius.circular(POSConfig().rounderBorderRadiusBottomRight),
            topLeft: Radius.circular(POSConfig().rounderBorderRadiusTopLeft),
            topRight: Radius.circular(POSConfig().rounderBorderRadiusTopRight),
          ),
          child: Image(
            image: NetworkImage(imgUrl),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildVarientSelection() {
    if (stk.length == 0) {
      return Text('');
    }

    Map<String, Map<String, double>> pivotData = {};
    List<String> columns = [];

    for (var i = 0; i < stk.length; i++) {
      int columnIndex = columns.indexOf(stk[i].loCDESC);
      if (columnIndex == -1) {
        columns.add(stk[i].loCDESC);
      }
    }

    for (var i = 0; i < stk.length; i++) {
      var column = stk[i].loCDESC;
      var row1 = stk[i].v1;
      var row2 = stk[i].v2;
      var value = stk[i].ipLUSIH;
      var proCode = stk[i].ipLUPRODUCTCODE;
      var combinedRow = '$proCode   $row1 $row2';

      if (!pivotData.containsKey(combinedRow)) {
        pivotData[combinedRow] = {};
      }
      for (var x = 0; x < columns.length; x++) {
        double? qty = pivotData[combinedRow]![columns[x]] ?? 0;
        pivotData[combinedRow]![columns[x]] = (qty == 0 ? 0 : qty);
      }
      pivotData[combinedRow]![column] = value!;
    }

    List<String> columnNames = pivotData.values.last.keys.toList();
    return Container(
      //flex: 6,
      child: SizedBox(
        height: 500.0,
        width: double.maxFinite,
        child: Scrollbar(
          controller: _scrollController,
          scrollbarOrientation: ScrollbarOrientation.left,
          child: Scrollbar(
            controller: _scrollController,
            //scrollbarOrientation: ScrollbarOrientation.top,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: pivotData.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    title: Row(
                      children: [
                        Container(
                          width: 200,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 1,
                                offset: const Offset(
                                    0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: const Text(
                            'Code/Colour/Size',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        for (int i = 0; i < columnNames.length; i++)
                          Container(
                              width: 100,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 3), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: Text(columnNames[i],
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center)),
                        Container(
                            width: 100,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 1,
                                  offset: const Offset(
                                      0, 3), // changes position of shadow
                                ),
                              ],
                            ),
                            child: const Text('Total',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center)),
                      ],
                    ),
                  );
                } else {
                  var rowData = pivotData.entries.elementAt(index - 1);
                  var rowTotal = rowData.value.values
                      .reduce((value, element) => value + element);
                  var code = rowData.key.toString().split(' ')[0];
                  return ListTile(
                      // onTap: () => _selectItem(code),

                      // () {
                      //   if (mounted) {
                      //     setState(() {
                      //       selectedProduct = stk.firstWhere(
                      //           (element) => element.ipLUPRODUCTCODE == code);
                      //     });
                      //   }
                      //   Navigator.pop(context);
                      // },
                      selected: code == selectedProduct?.ipLUPRODUCTCODE,
                      selectedTileColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                      // dense: true,
                      // visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                      title: Row(
                        children: [
                          Container(
                            width: 200,
                            height: 25,
                            // color: CurrentTheme.primaryColor,
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
                              child: Text(rowData.key,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal),
                                  textAlign: TextAlign.center),
                            ),
                          ),
                          for (int i = 0; i < columnNames.length; i++)
                            Container(
                              width: 100,
                              height: 20,
                              //color: Colors.blue[100 * (i % 9)],
                              child: Text(
                                  rowData.value[columnNames[i]].toString(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                  textAlign: TextAlign.center),
                            ),
                          Container(
                            width: 100,
                            height: 20,
                            //color: Colors.grey[200],
                            child: Text(rowTotal.toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                                textAlign: TextAlign.center),
                          ),
                          ElevatedButton(
                              onPressed: () async {
                                if (mounted) {
                                  setState(() {
                                    selectedProduct = stk.firstWhere(
                                        (element) =>
                                            element.ipLUPRODUCTCODE == code);
                                  });
                                }
                                await _addQtyToCart();
                                Navigator.pop(context);
                              },
                              child: const Text('select'))
                        ],
                      ));
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // void _selectItem(String code) {
  //   if (mounted) {
  //     setState(() {
  //       selectedProduct =
  //           stk.where((element) => element.ipLUPRODUCTCODE == code).first;
  //     });
  //   }
  //   Navigator.pop(context);
  // }

  /// new change - adding bottle prices seperately in invoice when buying liquor items or any other
  /// Author - [TM.Sakir] at 2023-11-01 11:10 AM
  /// -------------------------------------------------------------------------------------------------
  Future<void> _addQtyToCart() async {
    qty = double.tryParse(qtyController.text) ?? 1;
    final size = MediaQuery.of(context).size;
    TextEditingController newQtyController =
        TextEditingController(text: qty.toString());
    double newqty = 1;

    newQtyController.text = qty.toString();

    if (selectedProduct == null) return;
    EasyLoading.show(status: 'please_wait'.tr());
    final productRes = await ProductController().searchProductByBarcode(
        selectedProduct!.ipLUPRODUCTCODE, qty.toDouble());
    EasyLoading.dismiss();
    if (productRes?.product == null) return;
    await POSPriceCalculator().addItemToCart(
        productRes!.product!.first, qty, context, null, null, null,
        secondApiCall: true);
    if (productRes.product?.first.returnBottleCode != null &&
        productRes.product!.first.returnBottleCode!.isNotEmpty) {
      EasyLoading.show(status: 'please_wait'.tr());
      var returnProRes = await POSPriceCalculator()
          .searchProduct(productRes.product!.first.returnBottleCode!);
      EasyLoading.dismiss();
      if (returnProRes != null && returnProRes.product != null) {
        await showGeneralDialog(
            context: context,
            transitionDuration: const Duration(milliseconds: 200),
            barrierDismissible: false,
            barrierLabel: '',
            transitionBuilder: (context, a, b, _) => Transform.scale(
                scale: a.value,
                child: AlertDialog(
                  title: Center(
                      child: Text('general_dialog.empty_bottle_hed'.tr())),
                  content: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 30),
                          child: Row(
                            children: [
                              Container(
                                height: 100.r,
                                child: CachedNetworkImage(
                                  httpHeaders: {
                                    'Access-Control-Allow-Origin': '*'
                                  },
                                  imageUrl: (POSConfig().posImageServer +
                                      "images/products/" +
                                      returnProRes.product!.first.pLUCODE! +
                                      '.png'),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                          'assets/images/empty_bottle.png'),
                                  imageBuilder: (context, image) {
                                    return Card(
                                      elevation: 5,
                                      color: CurrentTheme.primaryColor,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(POSConfig()
                                              .rounderBorderRadiusBottomLeft),
                                          bottomRight: Radius.circular(POSConfig()
                                              .rounderBorderRadiusBottomRight),
                                          topLeft: Radius.circular(POSConfig()
                                              .rounderBorderRadiusTopLeft),
                                          topRight: Radius.circular(POSConfig()
                                              .rounderBorderRadiusTopRight),
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
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                    "${returnProRes.product!.first.pLUCODE} \n${returnProRes.product!.first.pLUPOSDESC}"),
                              )
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const SizedBox(child: Text('Quantity:')),
                            const SizedBox(
                              width: 10,
                            ),
                            SizedBox(
                              width: size.width * 0.2,
                              child: TextField(
                                controller: newQtyController,
                                keyboardType: TextInputType.number,
                                onTap: () {
                                  newQtyController.clear();
                                  KeyBoardController().init(context);
                                  KeyBoardController().showBottomDPKeyBoard(
                                      newQtyController, onEnter: () async {
                                    newqty =
                                        double.parse(newQtyController.text);
                                    KeyBoardController().dismiss();

                                    //  add to cart
                                    await POSPriceCalculator().addItemToCart(
                                      returnProRes.product!.first,
                                      newqty,
                                      context,
                                      null,
                                      null,
                                      null,
                                      // returnProRes.prices,
                                      // returnProRes.proPrices,
                                      // returnProRes.proTax,
                                      secondApiCall: true,
                                    );
                                    Navigator.pop(context);
                                  });
                                },
                                onEditingComplete: () {
                                  newqty = double.parse(newQtyController.text);
                                },
                              ),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                    onPressed: () async {
                                      //  add to cart
                                      await POSPriceCalculator().addItemToCart(
                                        returnProRes.product!.first,
                                        newqty,
                                        context,
                                        null,
                                        null,
                                        null,
                                        // returnProRes.prices,
                                        // returnProRes.proPrices,
                                        // returnProRes.proTax,
                                        secondApiCall: true,
                                      );
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Add')),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                        'general_dialog.empty_bottle_cancel'
                                            .tr())),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )),
            pageBuilder: (context, animation, secondaryAnimation) {
              return const SizedBox();
            });
      }
    }
    Navigator.pop(context);
  }

  void searchItem() async {
    EasyLoading.show(status: 'please_wait'.tr());
    final List<ProVariant> res = await ProductController()
        .getLocationWiseVariantStock(searchController.text);
    stk = res;
    if (stk.length == 0) {
      proImage = '';
      proCode = '';
      prodesc = 'No Data found..!';
    } else {
      proImage = stk.first.plUPICTURE ?? '';
      proCode = stk.first.ipLUCODE;
      prodesc = stk.first.ipLUDESC;
    }
    _buildImage(proImage, proCode);
    if (mounted) {
      setState(() {});
    }
    _buildVarientSelection();

    if (mounted) {
      setState(() {});
    }
    EasyLoading.dismiss();
    if (mounted) {
      setState(() {});
    }
  }
}
