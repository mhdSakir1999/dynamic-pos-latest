/// Author: [TM.Sakir] at 2023-11-21 09:00AM

import 'package:checkout/bloc/salesRep_bloc.dart';
import 'package:checkout/components/pos_connectivity.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/models/enum/pos_connectivity_status.dart';
import 'package:checkout/models/loyalty/salesRep_list_result.dart';
import 'package:checkout/models/pos/product_result.dart';
import 'package:checkout/views/pos_functions/service_status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<Product?> selecetedVarient(BuildContext context, double width,
    double height, double fontSize, ProductResult resList) {
  return showGeneralDialog<Product>(
      context: context,
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          Transform.scale(
            scale: animation.value,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  width * 0.1, height * 0.15, width * 0.1, height * 0.15),
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
                      children: [
                        Container(
                          height: height * 0.1,
                          width: width * 0.7,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text('Varient Code',
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
                              SizedBox(
                                width: width * 0.01,
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('Selling',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: fontSize,
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: height * 0.5,
                          width: width * 0.7,
                          child: ListView.builder(
                              itemCount: resList.product?.length ?? 0,
                              itemBuilder: (context, index) {
                                var selectedProduct = resList.product![index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(context, selectedProduct);
                                  },
                                  child: Container(
                                    height: height * 0.1,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                              selectedProduct.pLUSTOCKCODE ??
                                                  '',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                        Expanded(
                                          flex: 6,
                                          child: Text(
                                              selectedProduct.pLUPOSDESC ?? '',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                        SizedBox(
                                          width: width * 0.01,
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                              selectedProduct.sELLINGPRICE
                                                      .toString() ??
                                                  '',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: fontSize,
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ));
}

Future<SalesRepResult?> selecetSalesRep(BuildContext context) {
  TextEditingController ctrl = TextEditingController();
  var q = MediaQuery.of(context).size;
  double height = q.height;
  double width = q.width;
  double fontSize = 20.sp;
  return showGeneralDialog<SalesRepResult?>(
      context: context,
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          Transform.scale(
            scale: animation.value,
            child: StatefulBuilder(builder: (context, setState) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                    width * 0.1, height * 0.15, width * 0.1, height * 0.15),
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
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              child: TextField(
                                autofocus: true,
                                controller: ctrl,
                                onTap: () {
                                  KeyBoardController().init(context);
                                  KeyBoardController().showBottomDPKeyBoard(
                                      ctrl, onEnter: () async {
                                    KeyBoardController().dismiss();
                                    await salesRepBloc.getSalesReps();
                                  });
                                },
                                onEditingComplete: () async {
                                  await salesRepBloc.getSalesReps();
                                },
                                onSubmitted: (value) async {
                                  await salesRepBloc.getSalesReps();
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              // height: height * 0.1,
                              // width: width * 0.7,
                              child: Row(
                                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text('SalesRep Code',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: fontSize,
                                            color: Colors.white)),
                                  ),
                                  Expanded(
                                    flex: 6,
                                    child: Text('Full Name',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: fontSize,
                                            color: Colors.white)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Group',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: fontSize,
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                              height: height * 0.5,
                              width: width * 0.7,
                              child: StreamBuilder(
                                  stream: salesRepBloc.currentSalesRepStream,
                                  builder: (context,
                                      AsyncSnapshot<List<SalesRepResult>?>
                                          snapshot) {
                                    List<SalesRepResult>? repList = [];
                                    if (ctrl.text.isNotEmpty) {
                                      if (snapshot.data != null &&
                                          snapshot.data!.isNotEmpty) {
                                        for (var item in (snapshot.data!)) {
                                          if ((item.sAFULLNAME ?? '')
                                              .toLowerCase()
                                              .contains(
                                                  ctrl.text.toLowerCase())) {
                                            repList.add(item);
                                          }
                                        }

                                        if (repList.isEmpty) {
                                          for (var item in (snapshot.data!)) {
                                            if ((item.sACODE ?? '')
                                                .toLowerCase()
                                                .contains(
                                                    ctrl.text.toLowerCase())) {
                                              repList.add(item);
                                            }
                                          }
                                        }
                                        if (repList.isEmpty) {
                                          repList = snapshot.data;
                                        }
                                      }
                                    } else {
                                      repList = snapshot.data;
                                    }
                                    return ListView.builder(
                                        itemCount: repList?.length ?? 0,
                                        itemBuilder: (context, index) {
                                          return InkWell(
                                            onTap: () {
                                              Navigator.pop(
                                                  context, repList?[index]);
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Container(
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: Text(
                                                          repList?[index]
                                                                  .sACODE ??
                                                              '',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize:
                                                                  fontSize,
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                    Expanded(
                                                      flex: 6,
                                                      child: Text(
                                                          repList?[index]
                                                                  .sAFULLNAME ??
                                                              '',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize:
                                                                  fontSize,
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Center(
                                                        child: Text(
                                                            repList?[index]
                                                                    .sAGROUP ??
                                                                '',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize:
                                                                    fontSize,
                                                                color: Colors
                                                                    .white)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        });
                                  })),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ));
}

Widget connectionWidgetData() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: StreamBuilder<POSConnectivityStatus>(
      stream: posConnectivity.connectivityStream.stream,
      builder: (BuildContext context,
          AsyncSnapshot<POSConnectivityStatus> snapshot) {
        String text = "";
        TextStyle style = TextStyle();
        switch (snapshot.data) {
          case POSConnectivityStatus.Local:
            text = "Local";
            style = TextStyle(color: Colors.yellowAccent);
            break;
          case POSConnectivityStatus.Server:
            text = "Server";
            style = TextStyle(color: Colors.greenAccent);
            break;
          case POSConnectivityStatus.None:
            text = "None";
            style = TextStyle(color: Colors.redAccent);
            break;
          default:
            text = "N/A";
            style = TextStyle(color: Colors.redAccent);
        }

        return GestureDetector(
          onTap: () => _checkServerStatus(context),
          child: Text(
            "Connection Mode: $text",
            style: style.copyWith(fontSize: 16),
          ),
        );
      },
    ),
  );
}

Future<void> _checkServerStatus(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) {
      return const AlertDialog(
        content: ServiceStatusView(),
      );
    },
  );
}
