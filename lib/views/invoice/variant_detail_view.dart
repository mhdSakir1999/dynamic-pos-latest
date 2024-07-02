import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/product_controller.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/variant_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../components/mypos_screen_utils.dart';
import '../../components/widgets/go_back.dart';
import '../../models/pos_config.dart';
import '../invoice/invoice_app_bar.dart';

class VariantDetails extends StatefulWidget {
  final CartModel? cartItem;
  final List<ProVariant> variantDet;

  const VariantDetails({Key? key, this.cartItem, required this.variantDet})
      : super(key: key);

  @override
  State<VariantDetails> createState() => _VariantDetailsState();
}

class _VariantDetailsState extends State<VariantDetails> {
  List<ProVariant> stk = [];
  late List<ProVariant> variantDet;
  final searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String proImage = '';
  String proCode = '';
  String prodesc = '';

  @override
  initState() {
    super.initState();
    variantDet = widget.variantDet;
    stk = variantDet;
    prodesc = widget.cartItem!.posDesc;
    proCode = widget.cartItem!.proCode;
    proImage = widget.cartItem!.image!;
    //_getVariants()
  }

  _getVariants() async {
    stk = await ProductController()
        .getLocationWiseVariantStock(widget.cartItem?.proCode ?? ''.toString());
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
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildImage(proImage, proCode),
                  ],
                ),
              ),
             const SizedBox(
                width: 10,
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding:const EdgeInsets.only(left: 20),
                      child: Container(
                        height: 50,
                        width: 500,
                        margin:const EdgeInsets.only(right: 16),
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

                          decoration:const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              filled: true,
                              hintText: "Scan the barcode to search"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding:const EdgeInsets.only(left: 20),
                      child: Container(
                        width: 610,
                        height: 40,
                        color: Colors.lightBlueAccent,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            prodesc,
                            style:const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Container(
                          height: 500,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [_buildVariantDetails()],
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ])
            //mainAxisSize: MainAxisSize.min,
            ),
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
      // child: CachedNetworkImage(
      //   httpHeaders: {'Access-Control-Allow-Origin': '*'},
      //   imageUrl: (imgUrl ?? "images/products/" + product + '.png'),
      //   errorWidget: (context, url, error) => SizedBox.shrink(),
      //   imageBuilder: (context, image) {
      //     return Card(
      //       elevation: 5,
      //       color: CurrentTheme.primaryColor,
      //       child: ClipRRect(
      //         borderRadius: BorderRadius.only(
      //           bottomLeft:
      //               Radius.circular(POSConfig().rounderBorderRadiusBottomLeft),
      //           bottomRight:
      //               Radius.circular(POSConfig().rounderBorderRadiusBottomRight),
      //           topLeft:
      //               Radius.circular(POSConfig().rounderBorderRadiusTopLeft),
      //           topRight:
      //               Radius.circular(POSConfig().rounderBorderRadiusTopRight),
      //         ),
      //         child: Image(
      //           image: image,
      //           fit: BoxFit.contain,
      //         ),
      //       ),
      //     );
      //   },
      // ),
    );
  }

  Widget _buildVariantDetails() {
    if (stk.length == 0) {
      return const Text('');
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
      var combinedRow = '$row1 $row2';
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
                          width: 150,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 1,
                                offset:
                                   const Offset(0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child:const Text(
                            'Colour/Size',
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
                                    offset:const Offset(
                                        0, 3), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: Text(columnNames[i],
                                  style:const TextStyle(
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
                                  offset:const Offset(
                                      0, 3), // changes position of shadow
                                ),
                              ],
                            ),
                            child:const Text('Total',
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
                  return ListTile(
                      dense: true,
                      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                      // onTap: () => showDialog<String>(
                      //       context: context,
                      //       builder: (BuildContext context) => AlertDialog(
                      //         title: const Text('AlertDialog Title'),
                      //         content: Text(
                      //           rowData.key,
                      //         ),
                      //         actions: <Widget>[
                      //           TextButton(
                      //             onPressed: () =>
                      //                 Navigator.pop(context, 'Cancel'),
                      //             child: const Text('Cancel'),
                      //           ),
                      //           TextButton(
                      //             onPressed: () => Navigator.pop(context, 'OK'),
                      //             child: const Text('OK'),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //height: 100,
                      title: Row(
                        children: [
                          Container(
                            width: 150,
                            height: 25,
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
                              child: Text(rowData.key,
                                  style:const TextStyle(
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
                                  style:const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                  textAlign: TextAlign.center),
                            ),
                          Container(
                            width: 100,
                            height: 20,
                            //color: Colors.grey[200],
                            child: Text(rowTotal.toString(),
                                style:const TextStyle(
                                    color: Colors.white, fontSize: 15),
                                textAlign: TextAlign.center),
                          ),
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
    _buildVariantDetails();

    if (mounted) {
      setState(() {});
    }
    EasyLoading.dismiss();
    if (mounted) {
      setState(() {});
    }
  }
}
