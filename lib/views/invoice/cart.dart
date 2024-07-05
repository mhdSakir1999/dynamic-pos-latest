/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/23/21, 11:50 AM
 */

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/bloc/discount_bloc.dart';
import 'package:checkout/bloc/group_bloc.dart';
import 'package:checkout/bloc/lock_screen_bloc.dart';
import 'package:checkout/bloc/paymode_bloc.dart';
import 'package:checkout/bloc/price_mode_bloc.dart';
import 'package:checkout/bloc/salesRep_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/mypos_screen_utils.dart';
import 'package:checkout/components/recurringApiCalls.dart';
import 'package:checkout/components/widgets/commonUse.dart';
import 'package:checkout/components/widgets/poskeyboard.dart';
import 'package:checkout/controllers/audit_log_controller.dart';
import 'package:checkout/controllers/cart_dynamic_button_controller.dart';
import 'package:checkout/controllers/cart_dynamic_button_function.dart';
import 'package:checkout/controllers/customer_controller.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:checkout/controllers/gift_voucher_controller.dart';
import 'package:checkout/controllers/invoice_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/loyalty_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/controllers/pos_manual_print_controller.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/controllers/print_controller.dart';
import 'package:checkout/controllers/product_controller.dart';
import 'package:checkout/controllers/promotion_controller.dart';
import 'package:checkout/controllers/usb_serial_controller.dart';
import 'package:checkout/models/enum/pos_connectivity_status.dart';
import 'package:checkout/models/last_invoice_details.dart';
import 'package:checkout/models/loyalty/loyalty_summary.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:checkout/models/pos/cart_summary_model.dart';
import 'package:checkout/models/pos/gift_voucher_result.dart';
import 'package:checkout/models/pos/paid_model.dart';
import 'package:checkout/models/pos/price_mode_result.dart';
import 'package:checkout/models/pos/product_result.dart';
import 'package:checkout/models/pos/variant_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/customer/customer_helper.dart';
import 'package:checkout/views/customer/customer_profile.dart';
import 'package:checkout/views/invoice/invoice_app_bar.dart';
import 'package:checkout/views/invoice/payment_view.dart';
import 'package:checkout/views/invoice/product_search_view.dart';
import 'package:checkout/views/invoice/returnBottle_selection_view.dart';
import 'package:checkout/views/invoice/variant_detail_view.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:serial_port_win32/serial_port_win32.dart';
import 'package:supercharged/supercharged.dart';
import 'package:checkout/extension/extensions.dart';

import '../../bloc/user_bloc.dart';
import '../../controllers/activation/activation_controller.dart';
import '../../controllers/keyboard_controller.dart';
import '../../controllers/special_permission_handler.dart';
import '../../models/pos/permission_code.dart';

class Cart extends StatefulWidget {
  static const routeName = "cart";
  final Widget? replaceCart;
  final Widget? replacePayButton;
  final TextEditingController? replaceController;
  final VoidCallback? replaceOnEnter;
  final bool? openCustomerEnter;

  const Cart(
      {Key? key,
      this.replaceCart,
      this.replacePayButton,
      this.replaceController,
      this.replaceOnEnter,
      this.openCustomerEnter = true})
      : super(key: key);

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> with TickerProviderStateMixin {
  final itemCodeEditingController = TextEditingController();
  final productController = ProductController();
  final POSPriceCalculator calculator = POSPriceCalculator();
  final itemCodeFocus = FocusNode();
  final focusNode = FocusNode();
  final customerNode = FocusNode();
  ScrollController scrollController = ScrollController();
  CartModel? selectedCartItem;
  bool focus = true;
  bool active = false;
  bool gvMode = false;
  TextEditingController _remarkEditingController = TextEditingController();
  ScrollController _controller = ScrollController();
  bool proCodeEntered = false;
  //this index is used to identify the key up down
  int _tempIndex = 0;
  bool activeDynamicButton = true;

  bool payButtonPressed = false;

  PageController _pageViewController = PageController();
  late TabController _tabController;

  int _currentPageIndex = 0;

  late SerialPort port;
  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
    _tabController = TabController(length: 2, vsync: this);
    if ((cartBloc.currentCart?.length ?? 0) > 0) {
      if (POSConfig().dualScreenWebsite != "")
        DualScreenController().setView('invoice');
    }
    lockScreenBloc.lockScreenStream.listen((event) {
      if (!event && mounted) {
        itemCodeFocus.requestFocus();
        focusNode.requestFocus();
      }
    });
    if (widget.replaceCart == null)
      Future.delayed(Duration(seconds: 2)).then((value) {
        scrollToBottom();
        if (mounted)
          setState(() {
            active = true;
          });
      });
    // handle usb serial display
    // _getPortsAndOpen();

    /// new chage -- not allowing customer pick in local mode
    if (POSConfig().auto_cust_popup &&
        !POSConfig().localMode &&
        customerBloc.currentCustomer == null) {
      Future.delayed(Duration.zero).then((value) async {
        if (widget.openCustomerEnter == true)
          await CustomerController().showCustomerPicker(context);
        itemCodeFocus.requestFocus();
      });
    } else {
      Future.delayed(Duration.zero).then((value) async {
        itemCodeFocus.requestFocus();
      });
    }

    // SchedulerBinding.instance.addPostFrameCallback((_) {
    //   // Perform hit tests or interactions here.5
    //   _controller.addListener(_scroll);
    // });
    // _scroll();
  }

  @override
  void dispose() {
    _controller.dispose();
    itemCodeEditingController.dispose();
    _remarkEditingController.dispose();
    customerNode.dispose();
    scrollController.dispose();
    itemCodeFocus.dispose();
    focusNode.dispose();
    customerNode.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // void _scroll() {
  //   if (mounted) {
  //     setState(() {});
  //   }
  //   // Only call animateTo() if the scroll controller has clients.
  //   if (_controller.hasClients) {
  //     _controller.animateTo(
  //       _controller.position.maxScrollExtent,
  //       duration: Duration(milliseconds: 100),
  //       curve: Curves.easeInOut,
  //     );
  //   }

  //   // Schedule the _scroll() function to run again in one second.
  //   Future.delayed(Duration(seconds: 2), () {
  //     // if (mounted) {
  //     //   setState(() {});
  //     // }
  //     if (_controller.hasClients) {
  //       if (_controller.position.pixels ==
  //           _controller.position.maxScrollExtent) {
  //         _controller.jumpTo(0);
  //       }
  //       _scroll();
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    posConnectivity.setContext(context);
    recurringApiCalls.setContext(context);
    posConnectivity.setVoidCallback(_refresh);
    return GestureDetector(
      onTap: () {
        itemCodeFocus.requestFocus();
      },
      child: StreamBuilder(
        stream: lockScreenBloc.lockScreenStream,
        initialData: false,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          final child = POSBackground(
              child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: buildBody(),
            ),
          ));
          if (snapshot.data == true) {
            return child;
          }
          return KeyboardListener(
              autofocus: true,
              focusNode: focusNode,
              onKeyEvent: (value) async {
                if (value is KeyDownEvent) {
                  if (!HardwareKeyboard.instance.isShiftPressed &&
                      value.physicalKey == PhysicalKeyboardKey.numpadAdd) {
                    if (!payButtonPressed) {
                      payButtonPressed = true;
                      await billClose();
                      payButtonPressed = false;
                    }
                    // billClose();

                    focusNode.requestFocus();
                    itemCodeFocus.requestFocus();
                  }
                  if (!HardwareKeyboard.instance.isShiftPressed &&
                      value.logicalKey == LogicalKeyboardKey.f12 &&
                      !POSConfig().localMode) {
                    if (customerBloc.currentCustomer == null) {
                      CustomerController().showCustomerPicker(context);
                    } else {
                      currentCustomerChange(context);
                      focusNode.requestFocus();
                    }
                  }
                  if (!HardwareKeyboard.instance.isShiftPressed &&
                      value.physicalKey == PhysicalKeyboardKey.delete) {
                    await voidItem();
                    focusNode.requestFocus();
                    itemCodeFocus.requestFocus();
                  }
                  if (HardwareKeyboard.instance.isControlPressed &&
                      value.physicalKey == PhysicalKeyboardKey.keyA) {
                    final selectedRep;
                    if (cartBloc.currentCart != null &&
                        cartBloc.currentCart!.length > 0) {
                      selectedRep = await selecetSalesRep(context);
                      cartBloc.currentCart?.values.forEach((element) {
                        if (element.saleman == null || element.saleman == '') {
                          element.saleman = selectedRep?.sACODE ?? '';
                        }
                      });
                    } else {
                      EasyLoading.showError(
                          'general_dialog.sales_assist_no_products'.tr());
                    }
                  }
                  if (!itemCodeFocus.hasFocus) {
                    itemCodeFocus.requestFocus();
                  }
                  _handleKeyEvent(
                    value,
                  );
                }
              },
              child: child);
        },
      ),
    );
  }

  /// new change by [TM.Sakir] at 2023-11-14 4:33PM
  /// using keyboard keys to trigger functions

  void _handleKeyEvent(KeyDownEvent event) async {
    /// new change by [TM.Sakir]
    /// if cartBloc.cartSummary has items disabling 'special_function' button
    if (cartBloc.cartSummary?.items != 0 &&
        (!HardwareKeyboard.instance.isShiftPressed &&
            event.logicalKey == LogicalKeyboardKey.f1)) {
      EasyLoading.showError('special_functions.cant_open'.tr());
      return;
    }
    //"cartBloc.cartSummary" to check whether cart is not editable. this is used when backoffice txn is recalled.
    if (cartBloc.cartSummary?.editable != true &&
        !(!HardwareKeyboard.instance.isShiftPressed &&
            event.logicalKey == LogicalKeyboardKey.f4)) {
      EasyLoading.showError('backend_invoice_view.item_add_error'.tr());
      return;
    }

    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f7) {
      //check whether the client has the GV module license
      if (POSConfig().clientLicense?.lCMYVOUCHERS != true ||
          POSConfig().expired) {
        ActivationController().showModuleBuy(context, "myVouchers");
        return;
      }

      if (POSConfig().localMode) {
        EasyLoading.showError('local_mode_func_disable'.tr());
        return;
      }
      if (mounted) {
        setState(() {
          //Switch On or Off the GV mode
          gvMode = !gvMode;
        });
      }
      itemCodeFocus.requestFocus();
      return;
    }
    //if gv mode is enabled lets disable others
    if (gvMode) {
      return;
    }
    CartModel? lastItem;
    if (((cartBloc.currentCart?.values ?? []).length) > 0) {
      lastItem = cartBloc.currentCart?.values.last;
    }

    final selectedModel = getSelectedItem();

    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.physicalKey == PhysicalKeyboardKey.insert) {
      doWhenClicked(
          func_name: 'net_disc', cart: selectedModel, lastItem: lastItem);
    }
    if (POSConfig().localMode != true &&
        !HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f1) {
      doWhenClicked(
          func_name: 'special_function',
          cart: selectedModel,
          lastItem: lastItem);
    }
    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f2) {
      doWhenClicked(
          func_name: 'search', cart: selectedModel, lastItem: lastItem);
    }
    if (HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f2) {
      doWhenClicked(
          func_name: 'categories', cart: selectedModel, lastItem: lastItem);
    }
    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f3) {
      doWhenClicked(
          func_name: 'line_disc_per', cart: selectedModel, lastItem: lastItem);
    }
    if (HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f3) {
      doWhenClicked(
          func_name: 'line_disc_amt', cart: selectedModel, lastItem: lastItem);
    }
    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f4) {
      doWhenClicked(
          func_name: 'clear', cart: selectedModel, lastItem: lastItem);
    }
    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f5) {
      doWhenClicked(
          func_name: 'repeat_plu', cart: selectedModel, lastItem: lastItem);
    }
    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f6) {
      doWhenClicked(func_name: 'hold', cart: selectedModel, lastItem: lastItem);
    }
    if (HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f6) {
      doWhenClicked(
          func_name: 'recall', cart: selectedModel, lastItem: lastItem);
    }
    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f8) {
      doWhenClicked(
          func_name: 'cash_in', cart: selectedModel, lastItem: lastItem);
    }
    if (HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f8) {
      doWhenClicked(
          func_name: 'cash_out', cart: selectedModel, lastItem: lastItem);
    }
    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f9) {
      doWhenClicked(
          func_name: 'bill_cancel', cart: selectedModel, lastItem: lastItem);
    }
    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f10) {
      doWhenClicked(
          func_name: 'drawer_open', cart: selectedModel, lastItem: lastItem);
    }

    if (!HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.f11) {
      doWhenClicked(
          func_name: 're-print', cart: selectedModel, lastItem: lastItem);
    }
  }

  void doWhenClicked(
      {String func_name = '', CartModel? cart, CartModel? lastItem}) async {
    if (activeDynamicButton) {
      if (mounted)
        setState(() {
          activeDynamicButton = false;
        });
      await (CartDynamicButtonFunction(func_name, itemCodeEditingController)
            ..context = context)
          .handleFunction(cart: cart, lastItem: lastItem);
      scrollToBottom();
      clearSelection();
      focusNode.requestFocus();
      itemCodeFocus.requestFocus();
    }
  }

  void _refresh() {
    setState(() {});
  }

  Widget buildBody() {
    // return Column(
    //   children: [
    //     POSInvoiceAppBar(
    //       onPriceClick: _getPriceModes,
    //     ),
    //     Expanded(child: buildContent())
    //   ],
    // );
    return Stack(
      children: [
        Column(
          children: [
            POSInvoiceAppBar(
              onPriceClick: _getPriceModes,
            ),
            Expanded(child: buildContent())
          ],
        ),
        Positioned(
            top: 0,
            right: 0,
            child: POSConfig().localMode
                ? StreamContainer(
                    onUpdate: _refresh,
                  )
                : SizedBox.shrink())
      ],
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

  bool isPressed = false;
  // this is the default lhs in the app
  Widget buildDefaultLHS() {
    return Column(
      children: [
        Expanded(
          child: widget.replaceCart ??
              Column(
                children: [
                  Expanded(
                      child: Scrollbar(
                          //  thumbVisibility: true,
                          controller: scrollController,
                          thickness: 20,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: SingleChildScrollView(
                                physics: BouncingScrollPhysics(),
                                controller: scrollController,
                                child: buildCartList()),
                          ))),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        // height: MediaQuery.of(context).size.height * 0.07,
                        width: isPressed
                            ? MediaQuery.of(context).size.width * 0.3
                            : MediaQuery.of(context).size.width * 0.425,
                        // margin: EdgeInsets.only(right: 16),
                        child: TextField(
                          onTap: () {
                            itemCodeEditingController.clear();
                            KeyBoardController().dismiss();
                            KeyBoardController().init(context);
                            KeyBoardController().showBottomDPKeyBoard(
                                itemCodeEditingController, onEnter: () async {
                              KeyBoardController().dismiss();
                              if (!proCodeEntered) {
                                setState(() {
                                  proCodeEntered = true;
                                });
                                var a = await _handleScan();

                                setState(() {
                                  proCodeEntered = false;
                                });
                              }
                            });
                          },
                          readOnly: isMobile,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          focusNode: itemCodeFocus,
                          // showCursor: false,
                          controller: itemCodeEditingController,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: () async {
                            if (!proCodeEntered) {
                              setState(() {
                                proCodeEntered = true;
                              });
                              var a = await _handleScan();
                              setState(() {
                                proCodeEntered = false;
                              });
                            }
                          },
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  if (itemCodeEditingController
                                      .text.isNotEmpty) {
                                    var currentPosition =
                                        itemCodeEditingController
                                            .selection.baseOffset;
                                    itemCodeEditingController
                                        .text = itemCodeEditingController.text
                                            .substring(0, currentPosition - 1) +
                                        itemCodeEditingController.text
                                            .substring(currentPosition);
                                    itemCodeEditingController.selection =
                                        TextSelection.fromPosition(TextPosition(
                                            offset: currentPosition - 1));
                                  }

                                  itemCodeFocus.requestFocus();
                                },
                                icon: Icon(Icons.backspace_outlined),
                              ),
                              filled: true,
                              hintText: "invoice.search".tr()),
                        ),
                      ),
                      Expanded(
                        // margin: EdgeInsets.all(5),
                        // width: MediaQuery.of(context).size.width * 0.03,
                        child: Tooltip(
                          message: 'tool_tip.sales_assistant'
                              .tr(), // 'general_dialog.sales_assistant'.tr(),
                          child: Padding(
                            padding: EdgeInsets.zero,
                            // EdgeInsets.only(
                            //     left: MediaQuery.of(context).size.width *
                            //         0.01
                            //         ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.man_3_rounded,
                                color: Colors.white,
                                size: MediaQuery.of(context).size.height * 0.05,
                              ),
                              onPressed: () async {
                                // setState(() {
                                //   isPressed = !isPressed;
                                //   focusNode.requestFocus();
                                //   itemCodeFocus.requestFocus();
                                // });
                                final selectedRep;
                                if (cartBloc.currentCart != null &&
                                    cartBloc.currentCart!.length > 0) {
                                  if (salesRepBloc.currentSalesRep == null ||
                                      salesRepBloc.currentSalesRep?.length ==
                                          0) {
                                    EasyLoading.showError(
                                        'No sales assistants found');
                                    return;
                                  }
                                  selectedRep = await selecetSalesRep(context);
                                  cartBloc.currentCart?.values
                                      .forEach((element) {
                                    if (element.saleman == null ||
                                        element.saleman == '') {
                                      element.saleman =
                                          selectedRep?.sACODE ?? '';
                                    }
                                  });
                                  focusNode.requestFocus();
                                  itemCodeFocus.requestFocus();
                                } else {
                                  EasyLoading.showError(
                                      'general_dialog.sales_assist_no_products'
                                          .tr());
                                  focusNode.requestFocus();
                                  itemCodeFocus.requestFocus();
                                }
                              },
                            ),
                          ),
                        ),
                        //   isPressed
                        //       ? AnimatedContainer(
                        //           duration: Duration(seconds: 10),
                        //           width: MediaQuery.of(context).size.width * 0.15,
                        //           child: Card(
                        //               color: CurrentTheme.primaryLightColor,
                        //               child: Container(
                        //                 height:
                        //                     MediaQuery.of(context).size.height *
                        //                         0.06,
                        //                 child: Padding(
                        //                   padding:
                        //                       const EdgeInsets.only(bottom: 8.0),
                        //                   child: Row(
                        //                     crossAxisAlignment:
                        //                         CrossAxisAlignment.center,
                        //                     children: [
                        //                       Expanded(
                        //                         flex: 1,
                        //                         child: IconButton(
                        //                             onPressed: () {
                        //                               setState(() {
                        //                                 isPressed = !isPressed;
                        //                                 focusNode.requestFocus();
                        //                                 itemCodeFocus
                        //                                     .requestFocus();
                        //                               });
                        //                             },
                        //                             icon: Icon(
                        //                               Icons.arrow_forward_ios,
                        //                               color: CurrentTheme
                        //                                   .primaryColor,
                        //                               size: MediaQuery.of(context)
                        //                                       .size
                        //                                       .height *
                        //                                   0.04,
                        //                             )),
                        //                       ),
                        //                       Expanded(
                        //                         flex: 1,
                        //                         child: Tooltip(
                        //                           message:
                        //                               'tool_tip.sales_assistant'
                        //                                   .tr(),
                        //                           child: IconButton(
                        //                               onPressed: () async {
                        //                                 final selectedRep;
                        //                                 if (cartBloc.currentCart !=
                        //                                         null &&
                        //                                     cartBloc.currentCart!
                        //                                             .length >
                        //                                         0) {
                        //                                   if (salesRepBloc
                        //                                               .currentSalesRep ==
                        //                                           null ||
                        //                                       salesRepBloc
                        //                                               .currentSalesRep
                        //                                               ?.length ==
                        //                                           0) {
                        //                                     EasyLoading.showError(
                        //                                         'No sales assistants found');
                        //                                     return;
                        //                                   }
                        //                                   selectedRep =
                        //                                       await selecetSalesRep(
                        //                                           context);
                        //                                   cartBloc
                        //                                       .currentCart?.values
                        //                                       .forEach((element) {
                        //                                     if (element.saleman ==
                        //                                             null ||
                        //                                         element.saleman ==
                        //                                             '') {
                        //                                       element.saleman =
                        //                                           selectedRep
                        //                                                   ?.sACODE ??
                        //                                               '';
                        //                                     }
                        //                                   });
                        //                                   focusNode
                        //                                       .requestFocus();
                        //                                   itemCodeFocus
                        //                                       .requestFocus();
                        //                                 } else {
                        //                                   EasyLoading.showError(
                        //                                       'general_dialog.sales_assist_no_products'
                        //                                           .tr());
                        //                                   focusNode
                        //                                       .requestFocus();
                        //                                   itemCodeFocus
                        //                                       .requestFocus();
                        //                                 }
                        //                               },
                        //                               icon: Icon(
                        //                                 Icons.man_3_rounded,
                        //                                 color: CurrentTheme
                        //                                     .primaryColor,
                        //                                 size:
                        //                                     MediaQuery.of(context)
                        //                                             .size
                        //                                             .height *
                        //                                         0.04,
                        //                               )),
                        //                         ),
                        //                       ),
                        //                       Expanded(
                        //                         flex: 1,
                        //                         child: Tooltip(
                        //                           message:
                        //                               'tool_tip.promo_refresh'
                        //                                   .tr(),
                        //                           child: IconButton(
                        //                               onPressed: () async {
                        // EasyLoading.show(
                        //     status: 'please_wait'
                        //         .tr());
                        // var res =
                        //     await PromotionController(
                        //             context)
                        //         .getPromotions();
                        // EasyLoading.dismiss();
                        // res?.success == true
                        //     ? EasyLoading.showSuccess(
                        //         'invoice.promo_loaded'
                        //             .tr())
                        //     : EasyLoading.showError(
                        //         'No new promotions available');
                        // setState(() {
                        //   focusNode
                        //       .requestFocus();
                        //   itemCodeFocus
                        //       .requestFocus();
                        // });
                        //                               },
                        //                               icon: Icon(
                        //                                 Icons.refresh_rounded,
                        //                                 color: CurrentTheme
                        //                                     .primaryColor,
                        //                                 size:
                        //                                     MediaQuery.of(context)
                        //                                             .size
                        //                                             .height *
                        //                                         0.04,
                        //                               )),
                        //                         ),
                        //                       )
                        //                     ],
                        //                   ),
                        //                 ),
                        //               )),
                        //         )
                        //       : Tooltip(
                        //           message:
                        //               '', // 'general_dialog.sales_assistant'.tr(),
                        //           child: Padding(
                        //             padding: EdgeInsets.zero,
                        //             // EdgeInsets.only(
                        //             //     left: MediaQuery.of(context).size.width *
                        //             //         0.01
                        //             //         ),
                        //             child: IconButton(
                        //               padding: EdgeInsets.zero,
                        //               icon: Icon(
                        //                 Icons.functions_rounded,
                        //                 color: Colors.white,
                        //                 size: MediaQuery.of(context).size.height *
                        //                     0.05,
                        //               ),
                        //               onPressed: () async {
                        //                 setState(() {
                        //                   isPressed = !isPressed;
                        //                   focusNode.requestFocus();
                        //                   itemCodeFocus.requestFocus();
                        //                 });
                        //                 // final selectedRep;
                        //                 // if (cartBloc.currentCart != null &&
                        //                 //     cartBloc.currentCart!.length > 0) {
                        //                 //   if (salesRepBloc.currentSalesRep == null ||
                        //                 //       salesRepBloc.currentSalesRep?.length ==
                        //                 //           0) {
                        //                 //     EasyLoading.showError(
                        //                 //         'No sales assistants found');
                        //                 //     return;
                        //                 //   }
                        //                 //   selectedRep = await selecetSalesRep(context);
                        //                 //   cartBloc.currentCart?.values
                        //                 //       .forEach((element) {
                        //                 //     if (element.saleman == null ||
                        //                 //         element.saleman == '') {
                        //                 //       element.saleman =
                        //                 //           selectedRep?.sACODE ?? '';
                        //                 //     }
                        //                 //   });
                        //                 //   focusNode.requestFocus();
                        //                 //   itemCodeFocus.requestFocus();
                        //                 // } else {
                        //                 //   EasyLoading.showError(
                        //                 //       'general_dialog.sales_assist_no_products'
                        //                 //           .tr());
                        //                 //   focusNode.requestFocus();
                        //                 //   itemCodeFocus.requestFocus();
                        //                 // }
                        //               },
                        //             ),
                        //           ),
                        //         ),
                      )
                    ],
                  ),
                ],
              ),
        ),
        Container(
            margin: EdgeInsets.only(top: 8, right: 16),
            child: buildBottomCard()),
      ],
    );
  }

  DateTime lastVoid = DateTime.now();

  //this method used to void an item
  Future voidItem() async {
    if (!mounted) {
      return;
    }
    if (cartBloc.cartSummary?.editable != true) {
      EasyLoading.showError('backend_invoice_view.item_add_error'.tr());
      return;
    }
    final selected = getSelectedItem();

    if (selected != null && selected.itemVoid == false) {
      final dateTime = DateTime.now();
      final afterLastVoid = lastVoid.add(Duration(seconds: 3));
      if (dateTime.isAfter(afterLastVoid)) {
        calculator.voidItem(selected, context);
        selectedCartItem = null;
        var gross = cartBloc.cartSummary?.grossTotal ?? 0;
        if (POSConfig().enablePollDisplay == 'true') {
          usbSerial.sendToSerialDisplay(
              '${usbSerial.addSpacesBack('GROSS AMOUNT', 20)}');
          usbSerial.sendToSerialDisplay(
              '${usbSerial.addSpacesFront('${gross}', 20)}');
        }
      }
      // scrollToBottom();
      itemCodeFocus.requestFocus();
      if (mounted) setState(() {});
    }
  }

  CartModel? getSelectedItem() {
    CartModel? lastItem;
    if (((cartBloc.currentCart?.values ?? []).length) > 0) {
      lastItem = cartBloc.currentCart?.values.last;
    }
    final selectedModel = selectedCartItem ?? lastItem;
    return selectedModel;
  }

  void clearSelection() {
    selectedCartItem = null;
    activeDynamicButton = true;
    if (mounted) setState(() {});
  }

  /// new change - invoicing empty bottles as considering them as new product when buying liquor items or any other
  /// Author - [TM.Sakir] at 2023-11-01 11:10 AM
  /// -------------------------------------------------------------------------------------------------
  Future _handleProductSearch() async {
    double qty = 1;
    String temp = itemCodeEditingController.text;
    String code = temp;
    final symbol = "*";
    bool isScaleBarcode = false;
    var size = MediaQuery.of(context).size;
    TextEditingController qtyController =
        TextEditingController(text: qty.toString());
    double newqty = 1;
    ProductResult? returnProRes;
    List<bool> selected;
    if (code.contains(symbol)) {
      //  split it lhs is qty
      final split = code.split(symbol);
      code = split.last;
      qty = double.tryParse(split.first) ?? 1;
      if (qty == 0) {
        EasyLoading.showError('Invalid quantity... \ncannot add zero quantity');
        return;
      }
      qtyController.text = qty.toString();
    } else if (POSConfig().setup?.setuPSCALESYMBOL != null) {
      // check if the . is available or not (scale barcode separator)
      String scaleSymbol = POSConfig().setup!.setuPSCALESYMBOL!;
      if (code.contains(scaleSymbol)) {
        final split = code.split(scaleSymbol);
        code = split.first;
        isScaleBarcode = true;

        double? quantity;

        if (POSConfig().setup?.setuPSCALEDIGIT != null) {
          int digit = POSConfig().setup!.setuPSCALEDIGIT!;
          if (scaleSymbol != '#' && scaleSymbol != '_') {
            try {
              //quantity = split.last.substring(0, (split.last).length - digit).toDouble();
              split.last = split.last.substring(0, (split.last).length - digit);
              split.last = split.last.substring(0, (split.last).length - 3) +
                  '.' +
                  split.last.substring(
                      split.last.substring(0, (split.last).length - 3).length);
              quantity = split.last.toDouble();
            } catch (e) {
              return;
            }
          }
        } else {
          quantity = split.last.toDouble();
        }
        qty = (quantity != null) ? quantity : 0;
        qtyController.text = qty.toString();
      }
    }

    DateTime before = DateTime.now();
    //  check if the * available or not
    final resList =
        await calculator.searchProduct(itemCodeEditingController.text);
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double fontSize = 20.sp;
    String tempItemCode = itemCodeEditingController.text;
    itemCodeEditingController.clear();
    Product? res;
    if (resList != null &&
        resList.product != null &&
        resList.product!.length != 0) {
      if (resList.product!.length > 1) {
        res = await selecetedVarient(context, width, height, fontSize, resList);
      } else {
        res = resList.product!.first;
      }

      //  add to cart
      if (res != null) {
        // new change: spar barcode handling
        // getting product type (weighted or piece) then qty handling from barcode
        if (!tempItemCode.contains(symbol) &&
            tempItemCode.contains('#') &&
            (POSConfig().setup!.setuPSCALESYMBOL ?? '') == '#') {
          String fullQty = '';
          String deci = '';
          String qtyCode = tempItemCode.split('#').last;

          if (res.pluDecimal == true) {
            int digit = POSConfig().setup!.setuPSCALEDIGIT!;

            fullQty = qtyCode.substring(0, (qtyCode).length - digit);
            deci =
                qtyCode.substring((qtyCode).length - digit, (qtyCode).length);
            qtyCode = fullQty + '.' + deci;
            qty = qtyCode.toDouble() ?? 0;
          } else {
            qty = qtyCode.toDouble() ?? 0;
          }
        }

        // scale barcode handeling for OKD -- in here, underscore represents space
        if (!tempItemCode.contains(symbol) &&
            tempItemCode.contains(' ') &&
            (POSConfig().setup!.setuPSCALESYMBOL ?? '') == '_') {
          String fullQty = '';
          String deci = '';
          String qtyCode = tempItemCode.split(' ').last;

          if (res.pluDecimal == true) {
            int digit = POSConfig().setup!.setuPSCALEDIGIT!;

            fullQty = qtyCode.substring(0, (qtyCode).length - digit);
            deci =
                qtyCode.substring((qtyCode).length - digit, (qtyCode).length);
            qtyCode = fullQty + '.' + deci;
            qty = qtyCode.toDouble() ?? 0;
          } else {
            qty = qtyCode.toDouble() ?? 0;
          }
        }

        // empty bottles can't be sell directly which means it can only be sold along with liquir products.
        // so, even if the cashier type + qty for empty bottle, I consider it as a return scenario.
        if (res.isEmptyBottle == true) {
          qty = -1 * qty.abs();
        }

        itemCodeFocus.unfocus();
        List<CartModel?>? addedItem = await calculator.addItemToCart(res, qty,
            context, resList.prices, resList.proPrices, resList.proTax,
            secondApiCall: true, scaleBarcode: isScaleBarcode);
        itemCodeFocus.requestFocus();

        bool isMinus = qty < 0;
        if (res.returnBottleCode != null &&
            res.returnBottleCode!.isNotEmpty &&
            addedItem != null) {
          List<String> returnBottleCodes =
              res.returnBottleCode!.split(',') ?? [];
          List<ProductResult?> returnProResList = [];
          for (String code in returnBottleCodes) {
            var res = await calculator.searchProduct(code);
            if (res != null &&
                res.product != null &&
                res.product?.length != 0) {
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
            if (resList?.emptyBottles != null &&
                resList?.emptyBottles != [] &&
                !isMinus) {
              itemCodeFocus.unfocus();
              await showModalBottomSheet(
                enableDrag: false,
                isScrollControlled: true,
                isDismissible: false,
                useRootNavigator: true,
                context: context!,
                builder: (context) {
                  return ReturnBottleSelectionView(
                    returnProResList: resList.emptyBottles!,
                    isMinus: true, // it is always - since it is a return bottle
                    defaultQty: qty ?? 1,
                  );
                },
              );
              itemCodeFocus.requestFocus();
            }

            // ProductResult? returnProRes =
            // await showGeneralDialog(
            //     context: context,
            //     transitionDuration: const Duration(milliseconds: 200),
            //     barrierDismissible: true,
            //     barrierLabel: '',
            //     pageBuilder: (context, animation, secondaryAnimation) {
            //       return SizedBox();
            //     },
            //     transitionBuilder: (context, a, b, _) => Transform.scale(
            //           scale: a.value,
            //           child: StatefulBuilder(
            //             builder: (context, setState) => AlertDialog(
            //               title: Center(
            //                   child: Text(
            //                       'general_dialog.empty_bottle_select'.tr())),
            //               content: Row(
            //                 children: [
            //                   Container(
            //                     width: MediaQuery.of(context).size.width * 0.5,
            //                     height: MediaQuery.of(context).size.width * 0.5,
            //                     child: ListView.builder(
            //                         itemCount: returnProResList.length,
            //                         itemBuilder: (context, index) {
            //                           var pro = returnProResList[index];
            //                           selected = List.generate(
            //                               returnProResList.length,
            //                               (index) => pro == returnProRes);
            //                           return InkWell(
            //                             onTap: () {
            //                               setState(() {
            //                                 returnProRes = pro;
            //                                 selected[index] = true;
            //                               });

            //                               _qtyKeyboard(qtyController,
            //                                   returnProRes, isScaleBarcode);
            //                             },
            //                             child: ListTile(
            //                               selected: selected[index],
            //                               selectedTileColor:
            //                                   CurrentTheme.primaryColor,
            //                               title: Row(
            //                                 children: [
            //                                   Text(
            //                                     pro!.product!.first
            //                                             .pLUSTOCKCODE ??
            //                                         'N/A',
            //                                     overflow: TextOverflow.ellipsis,
            //                                     style: TextStyle(
            //                                         fontWeight:
            //                                             FontWeight.bold),
            //                                   ),
            //                                   SizedBox(
            //                                     width: 20,
            //                                   ),
            //                                   Text(
            //                                     (pro!.product!.first
            //                                                 .pLUPOSDESC ??
            //                                             'N/A') +
            //                                         '   -   ' +
            //                                         pro!.product!.first
            //                                             .sELLINGPRICE!
            //                                             .toStringAsFixed(2),
            //                                     overflow: TextOverflow.ellipsis,
            //                                     style: TextStyle(
            //                                         fontWeight:
            //                                             FontWeight.bold),
            //                                   ),
            //                                 ],
            //                               ),
            //                             ),
            //                           );
            //                         }),
            //                   ),
            //                   (returnProRes == null)
            //                       ? SizedBox.shrink()
            //                       : Padding(
            //                           padding:
            //                               const EdgeInsets.only(right: 16.0),
            //                           child: VerticalDivider(
            //                             width: 2,
            //                           ),
            //                         ),
            //                   (returnProRes == null)
            //                       ? SizedBox.shrink()
            //                       : Expanded(
            //                           // width: MediaQuery.of(context).size.width *
            //                           //     0.3,
            //                           child: Container(
            //                             child: Column(
            //                               mainAxisSize: MainAxisSize.min,
            //                               children: [
            //                                 Padding(
            //                                   padding: const EdgeInsets.only(
            //                                       top: 10.0, bottom: 30),
            //                                   child: Row(
            //                                     children: [
            //                                       Container(
            //                                         height: 100.r,
            //                                         child: CachedNetworkImage(
            //                                           httpHeaders: {
            //                                             'Access-Control-Allow-Origin':
            //                                                 '*'
            //                                           },
            //                                           imageUrl: (POSConfig()
            //                                                   .posImageServer +
            //                                               "images/products/" +
            //                                               returnProRes!.product!
            //                                                   .first.pLUCODE! +
            //                                               '.png'),
            //                                           errorWidget: (context,
            //                                                   url, error) =>
            //                                               Image.asset(
            //                                                   'assets/images/empty_bottle.png'),
            //                                           imageBuilder:
            //                                               (context, image) {
            //                                             return Card(
            //                                               elevation: 5,
            //                                               color: CurrentTheme
            //                                                   .primaryColor,
            //                                               child: ClipRRect(
            //                                                 borderRadius:
            //                                                     BorderRadius
            //                                                         .only(
            //                                                   bottomLeft: Radius
            //                                                       .circular(
            //                                                           POSConfig()
            //                                                               .rounderBorderRadiusBottomLeft),
            //                                                   bottomRight: Radius
            //                                                       .circular(
            //                                                           POSConfig()
            //                                                               .rounderBorderRadiusBottomRight),
            //                                                   topLeft: Radius
            //                                                       .circular(
            //                                                           POSConfig()
            //                                                               .rounderBorderRadiusTopLeft),
            //                                                   topRight: Radius
            //                                                       .circular(
            //                                                           POSConfig()
            //                                                               .rounderBorderRadiusTopRight),
            //                                                 ),
            //                                                 child: Image(
            //                                                   image: image,
            //                                                   fit: BoxFit
            //                                                       .contain,
            //                                                 ),
            //                                               ),
            //                                             );
            //                                           },
            //                                         ),
            //                                       ),
            //                                       Padding(
            //                                         padding:
            //                                             const EdgeInsets.only(
            //                                                 left: 8.0),
            //                                         child: Text(
            //                                           "${returnProRes?.product!.first.pLUCODE} \n${returnProRes?.product!.first.pLUPOSDESC}",
            //                                           overflow:
            //                                               TextOverflow.ellipsis,
            //                                         ),
            //                                       )
            //                                     ],
            //                                   ),
            //                                 ),
            //                                 Row(
            //                                   children: [
            //                                     SizedBox(
            //                                         child: Text('Quantity:')),
            //                                     SizedBox(
            //                                       width: 10,
            //                                     ),
            //                                     SizedBox(
            //                                       width: size.width * 0.2,
            //                                       child: TextField(
            //                                         autofocus: true,
            //                                         controller: qtyController,
            //                                         keyboardType:
            //                                             TextInputType.number,
            //                                         onTap: () {
            //                                           qtyController.clear();
            //                                           _qtyKeyboard(
            //                                               qtyController,
            //                                               returnProRes,
            //                                               isScaleBarcode);
            //                                         },
            //                                         onEditingComplete: () {
            //                                           newqty = double.parse(
            //                                               qtyController.text);
            //                                         },
            //                                       ),
            //                                     )
            //                                   ],
            //                                 ),
            //                                 Center(
            //                                   child: Padding(
            //                                     padding: const EdgeInsets.only(
            //                                         top: 16.0),
            //                                     child: Row(
            //                                       mainAxisAlignment:
            //                                           MainAxisAlignment.center,
            //                                       crossAxisAlignment:
            //                                           CrossAxisAlignment.center,
            //                                       children: [
            //                                         Padding(
            //                                           padding:
            //                                               const EdgeInsets.all(
            //                                                   8.0),
            //                                           child: ElevatedButton(
            //                                               onPressed: () async {
            //                                                 Navigator.pop(
            //                                                     context);
            //                                                 //  add to cart
            //                                                 await calculator.addItemToCart(
            //                                                     returnProRes!
            //                                                         .product!
            //                                                         .first,
            //                                                     newqty,
            //                                                     context,
            //                                                     returnProRes!
            //                                                         .prices,
            //                                                     returnProRes!
            //                                                         .proPrices,
            //                                                     returnProRes!
            //                                                         .proTax,
            //                                                     secondApiCall:
            //                                                         false,
            //                                                     scaleBarcode:
            //                                                         isScaleBarcode);
            //                                               },
            //                                               child: Text('Add')),
            //                                         ),
            //                                       ],
            //                                     ),
            //                                   ),
            //                                 )
            //                               ],
            //                             ),
            //                           ),
            //                         ),
            //                 ],
            //               ),
            //               actions: [
            //                 ElevatedButton(
            //                     onPressed: () => Navigator.pop(context, null),
            //                     child: Text('Cancel'))
            //               ],
            //             ),
            //           ),
            //         ));
          }
        }
      }
// ---------------------------------------------------------------------------------------------------------------------------------------------
      DateTime after = DateTime.now();

      print('+++++++++++++++++++++++++++++++++++++++++++++++++++');
      print('+++++++++++++++++++++++++++++++++++++++++++++++++++');
      print(
          '${res?.sCANCODE} Product added within ${after.millisecondsSinceEpoch - before.millisecondsSinceEpoch}');
      print('+++++++++++++++++++++++++++++++++++++++++++++++++++');
      print('+++++++++++++++++++++++++++++++++++++++++++++++++++');
      return true;
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return ProductSearchView(keyword: temp);
        },
      );
      // Navigator.push(context, MaterialPageRoute(builder: (context)=>ProductSearchView(keyword: temp)));
    }
  }

  void _qtyKeyboard(TextEditingController qtyController, var returnProRes,
      bool isScaleBarcode) async {
    // KeyBoardController().dismiss();
    if (POSConfig().touchKeyboardEnabled) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            alignment: Alignment.bottomCenter,
            content: SizedBox(
              width: 450.w,
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
                        await calculator.addItemToCart(
                            returnProRes!.product!.first,
                            double.parse(qtyController.text),
                            context,
                            returnProRes!.prices,
                            returnProRes!.proPrices,
                            returnProRes!.proTax,
                            secondApiCall: false,
                            scaleBarcode: isScaleBarcode);
                        Navigator.pop(context);
                      },
                      controller: qtyController,
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
                      if (qtyController.text.length != 0) {
                        qtyController.text = qtyController.text
                            .substring(0, qtyController.text.length - 1);
                      }
                    },
                    clearButton: true,
                    isInvoiceScreen: false,
                    disableArithmetic: true,
                    onEnter: () async {
                      Navigator.pop(context);
                      await calculator.addItemToCart(
                          returnProRes!.product!.first,
                          double.parse(qtyController.text),
                          context,
                          returnProRes!.prices,
                          returnProRes!.proPrices,
                          returnProRes!.proTax,
                          secondApiCall: false,
                          scaleBarcode: isScaleBarcode);
                      Navigator.pop(context);
                    },
                    controller: qtyController,
                    // nextFocusTo: editingFocusNode,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  //handle gv
  Future _handleGiftVoucher() async {
    //  check if the * available or not
    double qty = 1;
    String code = itemCodeEditingController.text;
    final symbol = "*";
    if (code.contains(symbol)) {
      //  split it lhs is qty
      final split = code.split(symbol);
      code = split.last;
      qty = double.tryParse(split.first) ?? 1;
    }

    qty = qty > 0 ? 1 : -1;

    //check the code contains in list
    if ((cartBloc.currentCart?.values.toList().indexWhere((element) =>
                element.isVoucher == true && element.proCode == code) ??
            -1) !=
        -1) {
      itemCodeEditingController.clear();
      _gvError('gv_error.already_added'.tr());
      return;
    }

    if (code.isEmpty) {
      _gvError('gv_error.empty'.tr());
    } else {
      proCodeEntered = false;
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
            _gvError(voucherRes?.message ?? 'gv_error.sold'.tr());
          } else {
            calculator.addGv(voucherRes!.giftVoucher!, qty, context);
            itemCodeEditingController.clear();
          }
        } else {
          _gvError(voucherRes?.message ?? 'gv_error.not_found'.tr());
          itemCodeEditingController.clear();
        }
        return;
      } else {
        // oh this is a valid gv
        calculator.addGv(voucherRes.giftVoucher!, qty, context);
        itemCodeEditingController.clear();
      }
    }
  }

  void _gvError(String error) {
    showDialog(
      context: context,
      builder: (context) => POSErrorAlert(
          title: 'gv_error.title'.tr(),
          subtitle: error,
          actions: <Widget>[
            AlertDialogButton(
              onPressed: () => Navigator.pop(context),
              text: 'gv_error.okay'.tr(),
            )
          ]),
    );
  }

  Future _handleScan() async {
    if (cartBloc.cartSummary?.editable != true) {
      EasyLoading.showError('backend_invoice_view.item_add_error'.tr());
      return;
    }
    if ((cartBloc.currentCart?.length ?? 0) == 0) {
      if (POSConfig().dualScreenWebsite != "")
        DualScreenController().setView('invoice');
    }
    if (gvMode) {
      await _handleGiftVoucher();
      setState(() {
        proCodeEntered = false;
        itemCodeFocus.requestFocus();
      });
    } else {
      await _handleProductSearch();
      setState(() {
        proCodeEntered = false;
        itemCodeFocus.requestFocus();
      });
      var lastItem = cartBloc.currentCart?.values.last;
      if (POSConfig().enablePollDisplay == 'true' && lastItem != null) {
        usbSerial.sendToSerialDisplay(
            '${usbSerial.addSpacesBack(lastItem.posDesc, 20)}');
        usbSerial.sendToSerialDisplay(
            'x${usbSerial.addSpacesBack(lastItem.unitQty.toString(), 5)}${usbSerial.addSpacesFront(lastItem.amount.toStringAsFixed(2), 14)}');
      }
    }
    scrollToBottom();
  }

  // this will handle which card to show on lhs bottom
  Widget buildBottomCard() {
    return StreamBuilder(
      stream: cartBloc.currentCartSnapshot,
      builder: (BuildContext context,
          AsyncSnapshot<Map<String, CartModel>> snapshot) {
        if (snapshot.data != null && (snapshot.data?.length ?? 0) > 0)
          return buildPriceCard();
        return buildLastInvoiceInfo();
      },
    );
  }

  // this will return the lhs bottom price card
  Widget buildPriceCard() {
    final style1 =
        CurrentTheme.bodyText1!.copyWith(color: CurrentTheme.primaryLightColor);
    final style1Bold = style1.copyWith(
        fontWeight: FontWeight.bold, fontSize: style1.fontSize! * 1.5);
    final style2 =
        CurrentTheme.headline4!.copyWith(color: CurrentTheme.primaryLightColor);
    final style2Bold = style2.copyWith(fontWeight: FontWeight.bold);
    return StreamBuilder<CartSummaryModel>(
        stream: cartBloc.cartSummarySnapshot,
        builder: (context, AsyncSnapshot<CartSummaryModel> snapshot) {
          final data = snapshot.data;
          String items = "${data?.items ?? 0}";
          String qty = data?.qty.qtyFormatter() ?? "0.0";
          String subtotal = "${(data?.subTotal ?? 0).thousandsSeparator()}";
          String lines = (cartBloc.currentCart)?.length.toString() ?? '0';

          return Card(
              color: CurrentTheme.primaryColor,
              margin: EdgeInsets.zero,
              child: Container(
                // width: double.maxFinite,
                // height: 50,
                padding: EdgeInsets.only(
                    top: 8.r, bottom: 8.r, right: 12.r, left: 12.r),
                child:

                    // Marquee(
                    //   text: 'Total Lines: $lines    ' +
                    //       'invoice.item'.tr() +
                    //       ': $items    ' +
                    //       'invoice.quantity'.tr() +
                    //       ': $qty    ' +
                    //       'invoice.sub_total'.tr() +
                    //       ': $subtotal   ||',
                    //   velocity: 30,
                    //   blankSpace: 20,
                    // ),

                    Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Spacer(),
                    Row(
                      children: [
                        Text(
                          'invoice.line'.tr() + ':',
                          style: style1,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          lines,
                          style: style1Bold,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'invoice.item'.tr() + ':',
                          style: style1,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          items,
                          style: style1Bold,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Text(
                          'invoice.quantity'.tr() + ':',
                          style: style1,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          qty,
                          style: style1Bold,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'invoice.sub_total'.tr() + ':',
                          style: style1,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          subtotal,
                          style: style1Bold,
                        ),
                      ],
                    )

                    // Spacer(),
                  ],
                ),
              ));
        });
  }

  // this will return the lhs bottom previous invoice card
  Widget buildLastInvoiceInfo() {
    final style1 =
        CurrentTheme.bodyText1!.copyWith(color: CurrentTheme.primaryLightColor);
    final style1Bold = style1.copyWith(
        fontWeight: FontWeight.bold, fontSize: style1.fontSize! * 1.5);
    final style2 =
        CurrentTheme.headline4!.copyWith(color: CurrentTheme.primaryLightColor);
    final style2Bold = style2.copyWith(fontWeight: FontWeight.bold);
    return StreamBuilder<LastInvoiceDetails>(
        stream: cartBloc.lastInvoiceDetails,
        builder: (context, AsyncSnapshot<LastInvoiceDetails> snapshot) {
          final data = snapshot.data;
          if (data == null) return buildPriceCard();
          return Card(
              color: CurrentTheme.primaryColor,
              margin: EdgeInsets.zero,
              child: Container(
                padding: EdgeInsets.all(8.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Spacer(),
                    HideWidgetOnScreenSize(
                      md: true,
                      child: Text(
                        'invoice.invoice_no'.tr() + ':',
                        style: style1,
                      ),
                    ),
                    HideWidgetOnScreenSize(
                      md: true,
                      child: SizedBox(
                        width: 3,
                      ),
                    ),
                    HideWidgetOnScreenSize(
                      md: true,
                      child: Text(
                        data.invoiceNo,
                        style: style1Bold,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'invoice.sub_total'.tr() + ':',
                      style: style1,
                    ),
                    SizedBox(
                      width: 3,
                    ),
                    Text(
                      data.billAmount.parseDouble().thousandsSeparator(),
                      style: style1Bold,
                    ),
                    Spacer(),
                    Text(
                      'invoice.paid_amount'.tr() + ':',
                      style: style1,
                    ),
                    SizedBox(
                      width: 3,
                    ),
                    Text(
                      data.paidAmount.parseDouble().thousandsSeparator(),
                      style: style1Bold,
                    ),
                    Spacer(),
                    Text(
                      'invoice.balance'.tr() + ':',
                      style: style1,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      data.dueAmount.parseDouble().thousandsSeparator(),
                      style: style1Bold,
                    ),
                    Spacer(),
                  ],
                ),
              ));
          // return Card(
          //     color: CurrentTheme.primaryColor,
          //     margin: EdgeInsets.zero,
          //     child: SingleChildScrollView(
          //       scrollDirection: Axis.horizontal,
          //       controller: _controller,
          //       child: AnimatedBuilder(
          //           animation: _controller,
          //           builder: (context, child) {
          //             return Container(
          //               height: MediaQuery.of(context).size.height * 0.05,
          //               width: MediaQuery.of(context).size.width,
          //               padding: EdgeInsets.all(8.r),
          //               child: Row(
          //                 mainAxisAlignment: MainAxisAlignment.center,
          //                 crossAxisAlignment: CrossAxisAlignment.center,
          //                 children: [
          //                   Spacer(),
          //                   HideWidgetOnScreenSize(
          //                     md: true,
          //                     child: Text(
          //                       'invoice.invoice_no'.tr(),
          //                       style: style1,
          //                     ),
          //                   ),
          //                   HideWidgetOnScreenSize(
          //                     md: true,
          //                     child: SizedBox(
          //                       width: 3,
          //                     ),
          //                   ),
          //                   HideWidgetOnScreenSize(
          //                     md: true,
          //                     child: Text(
          //                       data.invoiceNo,
          //                       style: style1Bold,
          //                     ),
          //                   ),
          //                   // SizedBox(
          //                   //   width: 10,
          //                   // ),
          //                   Text(
          //                     'invoice.sub_total'.tr(),
          //                     style: style1,
          //                   ),
          //                   SizedBox(
          //                     width: 3,
          //                   ),
          //                   Text(
          //                     data.billAmount
          //                         .parseDouble()
          //                         .thousandsSeparator(),
          //                     style: style1Bold,
          //                   ),
          //                   // Spacer(),
          //                   Text(
          //                     'invoice.paid_amount'.tr(),
          //                     style: style1,
          //                   ),
          //                   SizedBox(
          //                     width: 3,
          //                   ),
          //                   Text(
          //                     data.paidAmount
          //                         .parseDouble()
          //                         .thousandsSeparator(),
          //                     style: style1Bold,
          //                   ),
          //                   //Spacer(),
          //                   Text(
          //                     'invoice.balance'.tr(),
          //                     style: style2,
          //                   ),
          //                   SizedBox(
          //                     width: 5,
          //                   ),
          //                   Text(
          //                     data.dueAmount.parseDouble().thousandsSeparator(),
          //                     style: style2Bold,
          //                   ),
          //                   // Spacer(),
          //                 ],
          //               ),
          //             );
          //           }),
          //     ));
        });
  }

  // this method return the cart list
  Widget buildCartList() {
    final headingStyle = TextStyle(
        fontSize: POSConfig().cartDynamicButtonFontSize.sp,
        fontWeight: FontWeight.bold,
        color: CurrentTheme.primaryLightColor);
    final dataStyle = TextStyle(
        fontSize: POSConfig().cartDynamicButtonFontSize.sp,
        color: CurrentTheme.primaryLightColor);

    return StreamBuilder<Map<String, CartModel>>(
        stream: cartBloc.currentCartSnapshot,
        builder: (context, AsyncSnapshot<Map<String, CartModel>> snapshot) {
          // scrollToBottom();
          final map = snapshot.data;
          int length = 0;
          if (map != null) {
            length = map.values.length;
          }
          // if (POSConfig().checkoutTableView) {
          //   return DataTable(
          //       dataTextStyle: dataStyle,
          //       headingTextStyle: headingStyle,
          //       // sortAscending: true,
          //       // sortColumnIndex: 1,
          //       headingRowColor: MaterialStateColor.resolveWith(
          //         (states) {
          //           return CurrentTheme.primaryColor!;
          //         },
          //       ),
          //       columns: [
          //         DataColumn(
          //             label: Text(
          //           "invoice.plu".tr(),
          //         )),
          //         DataColumn(label: Text("invoice.description".tr())),
          //         DataColumn(
          //           label: Text("invoice.price".tr()),
          //           numeric: true,
          //         ),
          //         DataColumn(label: Text("invoice.disc".tr()), numeric: true),
          //         DataColumn(
          //             label: Text("invoice.disc_amt".tr()), numeric: true),
          //         DataColumn(label: Text("invoice.qty".tr()), numeric: true),
          //         DataColumn(label: Text("invoice.amount".tr()), numeric: true),
          //       ],
          //       rows: map?.values
          //               .map((e) => buildTableRow(e.lineNo ?? 1, e))
          //               .toList() ??
          //           []);
          // }
          return ListView.builder(
            itemCount: length,
            shrinkWrap: true,
            reverse: false,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) =>
                buildCartCard(map!.values.toList()[index]),
          );
        });
  }

  // This is the single row of the data table
  DataRow buildTableRow(int index, CartModel cart) {
    bool selected = cart.key == (selectedCartItem?.key ?? "null:D");
    bool voided = cart.itemVoid ?? false;
    return DataRow(
        selected: selected,
        color: MaterialStateColor.resolveWith(
          (states) {
            if (voided)
              return Colors.redAccent;
            else if (selected) return CurrentTheme.primaryColor!;
            return CurrentTheme.backgroundColor!;
          },
        ),
        onSelectChanged: (value) {
          if (voided) return;
          if (mounted)
            setState(() {
              selectedCartItem = selected ? null : cart;
            });
        },
        cells: [
          DataCell(Text(
            "${cart.proCode}",
          )),
          DataCell(Text(
            "${cart.noDisc ? "*" : ""}${cart.posDesc}",
          )),
          DataCell(Text("${cart.proSelling}", textAlign: TextAlign.center)),
          DataCell(Container(
              width: POSConfig().cartDynamicButtonFontSize.sp * 3,
              child: Text("${cart.discPer?.toStringAsFixed(2) ?? 0}",
                  textAlign: TextAlign.center))),
          DataCell(Container(
              width: POSConfig().cartDynamicButtonFontSize.sp * 3.5,
              child: Text(
                "${((cart.discAmt ?? 0) * -1).toStringAsFixed(2)}",
              ))),
          DataCell(
              Text(
                cart.unitQty.qtyFormatter(),
                textAlign: TextAlign.center,
              ), onTap: () {
            POSLoggerController.addNewLog(
                POSLogger(POSLoggerLevel.info, "qty editing field pressed"));
          }),
          DataCell(Text(
            "${cart.amount.thousandsSeparator()}",
          )),
        ]);
  }

  /// left side background of dismissible widget
  Widget _slideLeftBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.only(
          bottomLeft:
              Radius.circular(POSConfig().rounderBorderRadiusBottomLeft),
          bottomRight:
              Radius.circular(POSConfig().rounderBorderRadiusBottomRight),
          topLeft: Radius.circular(POSConfig().rounderBorderRadiusTopLeft),
          topRight: Radius.circular(POSConfig().rounderBorderRadiusTopRight),
        ),
      ),
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 20,
            ),
            Icon(
              Icons.delete,
              color: Colors.white,
            ),
            Text(
              " ${"invoice.void".tr()}",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
        alignment: Alignment.centerRight,
      ),
    );
  }

  /// right side background of dismissible widget
  Widget _slideRightBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.lightBlue,
        borderRadius: BorderRadius.only(
          bottomLeft:
              Radius.circular(POSConfig().rounderBorderRadiusBottomLeft),
          bottomRight:
              Radius.circular(POSConfig().rounderBorderRadiusBottomRight),
          topLeft: Radius.circular(POSConfig().rounderBorderRadiusTopLeft),
          topRight: Radius.circular(POSConfig().rounderBorderRadiusTopRight),
        ),
      ),
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            SizedBox(
              width: 20,
            ),
            Icon(
              Icons.edit,
              color: Colors.white,
            ),
            Text(
              " ${"invoice.remark".tr()}",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.left,
            ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  _handleCartItemDoubleTap(CartModel cartModel) async {
    //EasyLoading.show(status: 'please_wait'.tr());
    final List<ProVariant> res = await ProductController()
        .getLocationWiseVariantStock(cartModel.proCode);
    //EasyLoading.dismiss();
    showModalBottomSheet(
      isScrollControlled: true,
      enableDrag: true,
      context: context,
      builder: (context) {
        return VariantDetails(
          cartItem: cartModel,
          variantDet: res,
        );
      },
    );
    setState(() {
      focus = true;
    });
  }

  // this method build the card based cart item list
  Widget buildCartCard(CartModel cartModel) {
    bool selected = cartModel.key == (selectedCartItem?.key ?? "null:D");

    bool voided = (cartModel.itemVoid ?? false);
    final style = CurrentTheme.bodyText1!.copyWith(
        color: CurrentTheme.primaryLightColor,
        fontSize: (POSConfig().cardFontSize).sp);

    String? discountText;

    final zero = 0;
    if ((cartModel.discPer ?? zero) > zero) {
      discountText = "${cartModel.discPer?.toStringAsFixed(2)}%";
    } else if ((cartModel.discAmt ?? zero) != zero) {
      // discountText = "Rs. ${cartModel.discAmt?.abs().toStringAsFixed(2)}";
      discountText =
          "${POSConfig().currencyCode} ${cartModel.discAmt?.abs().toStringAsFixed(2)}";
    } else if ((cartModel.billDiscPer ?? zero) > zero) {
      discountText = "${cartModel.billDiscPer?.toStringAsFixed(2)}%";
    }
    String code =
        (cartModel.varientEnabled == true || cartModel.batchEnabled == true)
            ? cartModel.stockCode
            : cartModel.proCode;
    if (code.isEmpty) {
      code = cartModel.proCode;
    }
    return Dismissible(
      key: Key(cartModel.key),
      background: _slideLeftBackground(),
      secondaryBackground: _slideRightBackground(),
      onDismissed: (direction) {},
      confirmDismiss: (direction) async {
        if (!voided) {
          if (direction == DismissDirection.endToStart) {
            _remarkPopUp(cartModel);
          } else {
            selectedCartItem = cartModel;
            if (mounted) {
              setState(() {});
            }
            voidItem();
          }
        }
        return false;
      },
      child: InkWell(
        onDoubleTap: () {
          _handleCartItemDoubleTap(cartModel);
        },
        onTap: () {
          if (voided) return;
          if (selected)
            selectedCartItem = null;
          else
            selectedCartItem = cartModel;
          if (mounted) {
            setState(() {
              focusNode.requestFocus();
            });
          }
        },
        child: Card(
            color: selected
                ? CurrentTheme.backgroundColor
                : voided
                    ? Colors.redAccent
                    : CurrentTheme.primaryColor,
            child: Padding(
              padding: EdgeInsets.all(5.r),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                        width: POSConfig().cardIdLength.w,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            "$code",
                                            style: style,
                                          ),
                                        )),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Container(
                                          width: POSConfig().cardNameLength == 0
                                              ? double.infinity
                                              : POSConfig().cardNameLength.w,
                                          child: Text(
                                            "${cartModel.noDisc ? "* " : ""}${cartModel.posDesc}",
                                            style: style,
                                          )),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Spacer(),
                                    // SizedBox(width: POSConfig().cardIdLength.w,
                                    //     ),
                                    Container(
                                        width: POSConfig().cardPriceLength.w,
                                        child: Text(
                                          "${(cartModel.selling).thousandsSeparator()}",
                                          style: style,
                                          textAlign: TextAlign.end,
                                        )),
                                    Container(
                                        width: POSConfig().cardQtyLength.w,
                                        child: Text(
                                          cartModel.unitQty.qtyFormatter(),
                                          style: style,
                                          textAlign: TextAlign.end,
                                        )),
                                    Container(
                                        width: POSConfig().cardTotalLength.w,
                                        child: Text(
                                          "${(cartModel.amount).thousandsSeparator()}",
                                          style: style,
                                          textAlign: TextAlign.end,
                                        )),
                                  ],
                                ),
                              ],
                            ),
                            discountText == null
                                ? SizedBox.shrink()
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
                      Container(
                        height: 80.r,
                        child: CachedNetworkImage(
                          httpHeaders: {'Access-Control-Allow-Origin': '*'},
                          imageUrl: (cartModel.image ??
                              "images/products/" + cartModel.proCode + '.png'),
                          errorWidget: (context, url, error) =>
                              SizedBox.shrink(),
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
                    ],
                  ),
                ],
              ),
            )),
      ),
    );
  }

  ///remark pop up
  Future<void> _remarkPopUp(CartModel cartModel) async {
    _remarkEditingController.clear();
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('invoice.remark'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                      width: ScreenUtil().screenWidth * 0.5,
                      child: ListView.builder(
                        itemCount: cartModel.lineRemark.length,
                        itemBuilder: (context, index) => Dismissible(
                          confirmDismiss: (_) =>
                              _removeRemark(cartModel, index),
                          key: Key(index.toString()),
                          child: SizedBox(
                              child: Text(
                                  '${index + 1}.${cartModel.lineRemark[index]}')),
                        ),
                      )),
                ),
                SizedBox(
                  width: 600.w,
                  child: TextField(
                    onTap: () {
                      KeyBoardController().dismiss();
                      KeyBoardController().showBottomDPKeyBoard(
                          _remarkEditingController, onEnter: () {
                        KeyBoardController().dismiss();
                        _updateRemark(cartModel);
                      });
                    },
                    controller: _remarkEditingController,
                    maxLength: 60,
                    decoration:
                        InputDecoration(hintText: 'invoice.enter_remark'.tr()),
                  ),
                ),
              ],
            ),
            actions: [
              AlertDialogButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  text: 'invoice.cancel'.tr()),
              AlertDialogButton(
                  onPressed: () {
                    _updateRemark(cartModel);
                  },
                  text: 'invoice.add_remark'.tr())
            ],
          );
        });
  }

  void _updateRemark(CartModel cartModel) {
    final String remark = _remarkEditingController.text;
    cartModel.lineRemark.add(remark);
    cartBloc.updateCartItem(cartModel);
    Navigator.pop(context);
  }

  Future<bool> _removeRemark(CartModel cartModel, int index) async {
    cartModel.lineRemark.removeAt(index);
    cartBloc.updateCartItem(cartModel);
    Navigator.pop(context);
    return true;
  }

// this is the default rhs in the app
  Widget buildDefaultRHS() {
    return Container(
      child: Column(
        children: [
          Expanded(
              child: AbsorbPointer(
                  absorbing: widget.replaceCart != null,
                  child: buildButtonSet())),
          Expanded(child: buildRHSBottom())
        ],
      ),
    );
  }

  // This is the dynamic button set
  Widget buildButtonSet() {
    final dynamicButtonList = CartDynamicButtonController().getButtonList();
    final dynamicButtonList2 = CartDynamicButtonController().getButtonList2();
    final config = POSConfig();
    return Container(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageViewController,
                  onPageChanged: _handlePageViewChanged,
                  children: [
                    ResponsiveGridList(
                      scroll: false,
                      desiredItemWidth: config.cartDynamicButtonWidth.w,
                      children: dynamicButtonList.map((posButton) {
                        Color? textColor = posButton.textColor?.toColor() ??
                            CurrentTheme.primaryDarkColor;
                        if (gvMode && posButton.functionName != 'gv') {
                          textColor = Colors.blueGrey;
                        }

                        return Container(
                          margin: EdgeInsets.all(
                              POSConfig().cartDynamicButtonPadding),
                          height: config.cartDynamicButtonHeight.h,
                          child: MaterialButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(
                                  config.rounderBorderRadiusBottomLeft),
                              bottomRight: Radius.circular(
                                  config.rounderBorderRadiusBottomRight),
                              topRight: Radius.circular(
                                  config.rounderBorderRadiusTopRight),
                              topLeft: Radius.circular(
                                  config.rounderBorderRadiusTopLeft),
                            )),
                            color: posButton.buttonNormalColor.toColor(),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                "functions.${posButton.functionName}".tr(),
                                style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // style: ElevatedButton.styleFrom(
                            //     primary: posButton.buttonNormalColor.toColor()),
                            onPressed: () async {
                              /// new change by [TM.Sakir]
                              if (POSConfig().localMode == true &&
                                  posButton.functionName ==
                                      'special_function') {
                                EasyLoading.showError(
                                    'special_functions.cant_open_local'.tr());
                                return;
                              }

                              /// if cartBloc.cartSummary has items disabling 'special_function' button
                              if (cartBloc.cartSummary?.items != 0 &&
                                  posButton.functionName ==
                                      'special_function') {
                                EasyLoading.showError(
                                    'special_functions.cant_open'.tr());
                                return;
                              }
                              //"cartBloc.cartSummary" to check whether cart is not editable. this is used when backoffice txn is recalled.
                              if (cartBloc.cartSummary?.editable != true &&
                                  posButton.functionName != 'clear') {
                                EasyLoading.showError(
                                    'backend_invoice_view.item_add_error'.tr());
                                return;
                              }
                              //this is gv mode button
                              if (posButton.functionName == 'gv') {
                                //check whether the client has the GV module license
                                if (POSConfig().clientLicense?.lCMYVOUCHERS !=
                                        true ||
                                    POSConfig().expired) {
                                  ActivationController()
                                      .showModuleBuy(context, "myVouchers");
                                  return;
                                }

                                if (config.localMode) {
                                  EasyLoading.showError(
                                      'local_mode_func_disable'.tr());
                                  return;
                                }
                                if (mounted) {
                                  setState(() {
                                    //Switch On or Off the GV mode
                                    gvMode = !gvMode;
                                  });
                                }
                                itemCodeFocus.requestFocus();
                                return;
                              }

                              //if gv mode is enabled lets disable others
                              if (gvMode) {
                                return;
                              }

                              CartModel? lastItem;
                              if (((cartBloc.currentCart?.values ?? [])
                                      .length) >
                                  0) {
                                lastItem = cartBloc.currentCart?.values.last;
                              }

                              final selectedModel = getSelectedItem();
                              POSLoggerController.addNewLog(POSLogger(
                                  POSLoggerLevel.info,
                                  "${posButton.buttonName}(${posButton.functionName}) button pressed"));
                              final func = CartDynamicButtonFunction(
                                  posButton.functionName,
                                  itemCodeEditingController)
                                ..context = context;
                              if (activeDynamicButton) {
                                if (mounted)
                                  setState(() {
                                    activeDynamicButton = false;
                                  });
                                try {
                                  await func.handleFunction(
                                      cart: selectedModel, lastItem: lastItem);
                                } catch (e) {
                                  LogWriter().saveLogsToFile(
                                      'ERROR_LOG_', [e.toString()]);
                                }
                                scrollToBottom();
                                clearSelection();
                                focusNode.requestFocus();
                                itemCodeFocus.requestFocus();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    ResponsiveGridList(
                      scroll: false,
                      desiredItemWidth: config.cartDynamicButtonWidth.w,
                      children: dynamicButtonList2.map((posButton) {
                        Color? textColor = posButton.textColor?.toColor() ??
                            CurrentTheme.primaryDarkColor;
                        if (gvMode && posButton.functionName != 'gv') {
                          textColor = Colors.blueGrey;
                        }

                        return Container(
                          margin: EdgeInsets.all(
                              POSConfig().cartDynamicButtonPadding),
                          height: config.cartDynamicButtonHeight.h,
                          child: MaterialButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(
                                  config.rounderBorderRadiusBottomLeft),
                              bottomRight: Radius.circular(
                                  config.rounderBorderRadiusBottomRight),
                              topRight: Radius.circular(
                                  config.rounderBorderRadiusTopRight),
                              topLeft: Radius.circular(
                                  config.rounderBorderRadiusTopLeft),
                            )),
                            color: posButton.buttonNormalColor.toColor(),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                "functions.${posButton.functionName}".tr(),
                                style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // style: ElevatedButton.styleFrom(
                            //     primary: posButton.buttonNormalColor.toColor()),
                            onPressed: () async {
                              POSLoggerController.addNewLog(POSLogger(
                                  POSLoggerLevel.info,
                                  "${posButton.buttonName}(${posButton.functionName}) button pressed"));
                              final func = CartDynamicButtonFunction(
                                  posButton.functionName,
                                  itemCodeEditingController)
                                ..context = context;
                              if (activeDynamicButton) {
                                if (mounted)
                                  setState(() {
                                    activeDynamicButton = false;
                                  });
                                await func
                                    .handleFunction(cart: null, lastItem: null)
                                    .then((value) {
                                  scrollToBottom();
                                  clearSelection();
                                  focusNode.requestFocus();
                                  itemCodeFocus.requestFocus();
                                  if (posButton.functionName ==
                                      'local_switch') {
                                    _pageViewController.animateToPage(0,
                                        duration: Duration(milliseconds: 500),
                                        curve: Curves.easeInOut);
                                  }
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Positioned(
          //     left: 0,
          //     top: 0,
          //     bottom: 0,
          //     child: IconButton(
          //         onPressed: () {}, icon: Icon(Icons.arrow_back_ios))),
          // Positioned(
          //     right: 0,
          //     top: 0,
          //     bottom: 0,
          //     child: IconButton(
          //         onPressed: () {}, icon: Icon(Icons.arrow_forward_ios)))
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PageIndicator(
              tabController: _tabController,
              currentPageIndex: _currentPageIndex,
              onUpdateCurrentPageIndex: _updateCurrentPageIndex,
              isOnDesktopAndWeb: _isOnDesktopAndWeb,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePageViewChanged(int currentPageIndex) {
    if (!_isOnDesktopAndWeb) {
      return;
    }
    _tabController.index = currentPageIndex;
    setState(() {
      _currentPageIndex = currentPageIndex;
    });
  }

  void _updateCurrentPageIndex(int index) {
    _tabController.index = index;
    _pageViewController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  bool get _isOnDesktopAndWeb {
    if (kIsWeb) {
      return true;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  void scrollToBottom() async {
    // scrollController.animateTo(0,
    //     duration: Duration(milliseconds: 100), curve: Curves.linear);
    // await Future.delayed(Duration(milliseconds: 100));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      } else {
        if (mounted) setState(() => null);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scrollToBottom();
  } // This is the bottom screen of rhs

  Widget buildRHSBottom() {
    return Column(
      children: [
        Expanded(
          child: Container(
            child: POSKeyBoard(
                onPressed: () async {
                  if (widget.replaceController == null) {
                    await voidItem();
                  }
                },
                onEnter: widget.replaceOnEnter ??
                    () async {
                      if (mounted) {
                        setState(() {
                          active = false;
                        });
                        await _handleScan();
                        setState(() {
                          active = true;
                        });
                      }
                    },
                isInvoiceScreen: false,
                controller:
                    widget.replaceController ?? itemCodeEditingController,
                nextFocusTo: itemCodeFocus),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
            width: double.infinity,
            child: widget.replacePayButton ??
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            POSConfig().primaryDarkGrayColor.toColor()),
                    onPressed: () async {
                      if (!payButtonPressed) {
                        payButtonPressed = true;
                        await billClose();
                        payButtonPressed = false;
                      }
                      // billClose();

                      itemCodeFocus.requestFocus();
                    },
                    child: Text("invoice.bill_close".tr())))
      ],
    );
  }

  Future<void> billClose() async {
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "pay & complete button pressed"));
    final route = PaymentView.routeName;

    if (mounted)
      setState(() {
        active = false;
      });

    /// new change-by [TM.Sakir] this [taxCalculation()] is moved to here from payment view.
    /// reason: when customer return the product, we should calculate tax and return the paid tax of that product to the customer.
    POSPriceCalculator().taxCalculation();
    //check void
    final cartList = cartBloc.currentCart?.values.toList() ?? [];
    final voidCount =
        cartList.where((element) => element.itemVoid == true).length;

    final zero = 0;
    bool zeroLineAmountError = false;
    double totalAmount = 0;

    for (int i = 0; i < cartList.length; i++) {
      final element = cartList[i];
      final voidItem = element.itemVoid ?? false;
      final discPer = element.discPer ?? 0;
      final discAmt = element.discAmt ?? 0;
      final billDisc = element.billDiscPer ?? 0;
      final billAmt = element.billDiscAmt ?? 0;
      final lineAmt = element.amount;

      if (!voidItem) {
        totalAmount += lineAmt;
      }

      if (!voidItem &&
          discPer <= zero &&
          discAmt <= zero &&
          lineAmt == zero &&
          billAmt == zero &&
          billDisc == zero) {
        final item = await ProductController()
            .searchProductByBarcode(element.proCode, 1);

        final open = item?.product?.first.pluOpen ?? false;
        if (!open) {
          zeroLineAmountError = true;
          break;
        }
      }
    }

    if (zeroLineAmountError) {
      await showAlert("line_amount_zero");
      return;
    }

    if (cartList.length == voidCount) {
      await showAlert("nothing_to_save");
      return;
    }
    //validate the system end date
    if (!POSConfig().bypassEodValidation) {
      DateTime eodDate = POSConfig().setup?.setupEndDate ?? DateTime.now();
      int validationDuration = POSConfig().setup?.eodValidationDuration ?? -1;
      if (validationDuration <= 0) {
        POSConfig().bypassEodValidation = true;
      } else {
        if (DateTime.now()
            .isAfter(eodDate.add(Duration(hours: validationDuration)))) {
          final bool? canByPassEod = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'invoice.eod_exceed_title'.tr(),
                  textAlign: TextAlign.center,
                ),
                content: Text('invoice.eod_exceed_content'.tr()),
                actions: [
                  AlertDialogButton(
                      onPressed: () async {
                        String user =
                            userBloc.currentUser?.uSERHEDUSERCODE ?? "";
                        String refCode =
                            '${POSConfig().locCode}-${POSConfig().terminalId}-@$user';
                        bool hasPermission = false;
                        hasPermission =
                            SpecialPermissionHandler(context: context)
                                .hasPermission(
                                    permissionCode:
                                        PermissionCode.byPassEodTimeframe,
                                    accessType: "A",
                                    refCode: refCode);

                        //if user doesnt have the permission
                        if (!hasPermission) {
                          final res =
                              await SpecialPermissionHandler(context: context)
                                  .askForPermission(
                                      permissionCode:
                                          PermissionCode.byPassEodTimeframe,
                                      accessType: "A",
                                      refCode: refCode);
                          hasPermission = res.success;
                          user = res.user;
                        }
                        if (hasPermission) {
                          POSConfig().bypassEodValidation = true;
                          Navigator.pop(context, true);
                        } else {
                          Navigator.pop(context, false);
                        }
                      },
                      text: 'invoice.eod_exceed_yes'.tr()),
                  AlertDialogButton(
                      onPressed: () => Navigator.pop(context, false),
                      text: 'invoice.eod_exceed_no'.tr()),
                ],
              );
            },
          );
          if (canByPassEod != true) {
            return;
          }
        }
      }
    }

    EasyLoading.show(status: 'please_wait'.tr());

    if (totalAmount <= zero) {
      EasyLoading.dismiss();
      _exchangeVoucher(totalAmount);
      payButtonPressed = false;
      active = true;
      return;
    }

    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Navigate to the $route"));
    // Navigator.pushNamed(context, route);
    focus = false;
    clearSelection();

    EasyLoading.dismiss();

    /// For checking the sih again when proceed to pay - by [TM.Sakir]
    List<CartModel> minusNotAllowedItems = [];
    cartList.forEach((element) {
      if (element.allowMinus != true &&
          element.userAllowedMinus != true &&
          element.itemVoid != true) {
        minusNotAllowedItems.add(element);
      }
    });

    if (minusNotAllowedItems.length != 0) {
      List<Map<String, dynamic>> minusNotAllowedItemsMap = List.generate(
          minusNotAllowedItems.length,
          (index) => {
                "stock_code": minusNotAllowedItems[index].stockCode,
                "qty": minusNotAllowedItems[index].unitQty
              });
      // <--- apicall for getting sih --->
      List res = await ProductController()
          .getStockInHandDetails(minusNotAllowedItemsMap);
      if (res.length != 0) {
        String proDetails = '';
        res.forEach((element) {
          proDetails += '\n' +
              '[Code: ${element['stockCode']}  Qty: ${element['qty']}  SIH: ${element['sih']}]';
        });
        final bool? skipMinusProductInfoDialog = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'invoice.no_stock'.tr(),
                  textAlign: TextAlign.center,
                ),
                content: Text(
                  'invoice.no_stock_detail'.tr() + '\n$proDetails',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  AlertDialogButton(
                      onPressed: () => Navigator.pop(context, false),
                      text: 'invoice.stock_no'.tr()),
                  AlertDialogButton(
                      onPressed: () => Navigator.pop(context, true),
                      text: 'invoice.stock_yes'.tr()),
                ],
              );
            });

        bool allowMinusRes = false;

        if (skipMinusProductInfoDialog == true) {
          allowMinusRes = await allowMinusAlert(context,
              cartBloc.cartSummary?.invoiceNo ?? '${res.toString()}', '', 0);
          if (allowMinusRes == true) {
            for (int i = 0; i < res.length; i++) {
              if (res[i]['sih'] < res[i]['qty']) {
                AuditLogController().updateAuditLog(
                    PermissionCode.stockBypass,
                    'A',
                    '${cartBloc.cartSummary?.invoiceNo}@${res[i]['stockCode']}@${res[i]['qty'].toString()}',
                    'Permission approved through reason and password.',
                    userBloc.currentUser?.uSERHEDUSERCODE ?? "");
              }
            }
          } else {
            return;
          }
        } else {
          return;
        }
      }
    }

    ///------------------------------------------------------------------------------------------------------------

    //load promotions
    // EasyLoading.dismiss();
    await PromotionController(context).applyPromotion();

    await showModalBottomSheet(
      isScrollControlled: true,
      enableDrag: false,
      context: context,
      builder: (context) {
        return PaymentView();
      },
    );
    setState(() {
      focus = true;
      payButtonPressed = false;
    });
  }

  Future<bool> allowMinusAlert(BuildContext context, String invNo,
      String proStockCode, double qty) async {
    // handle permission
    SpecialPermissionHandler handler =
        SpecialPermissionHandler(context: context);
    String code = PermissionCode.stockBypass;
    String type = "A";
    String refCode =
        invNo + "@" + (proStockCode ?? "") + "@" + qty.toDouble().toString();
    bool permissionStatus = handler.hasPermission(
        permissionCode: code, accessType: type, refCode: refCode);
    if (!permissionStatus) {
      bool success = (await handler.askForPermission(
              accessType: type, permissionCode: code, refCode: refCode))
          .success;
      return success;
    }
    return permissionStatus;
  }

  Future _exchangeVoucher(double totalAmount) async {
    double subTotal = cartBloc.cartSummary?.subTotal ?? 0;
    cartBloc.cartSummarySnapshot.listen((event) {
      subTotal = event.subTotal;
      if (mounted) setState(() {});
    });
    totalAmount = subTotal;
    totalAmount = totalAmount * -1;
    double zero = 0;
    bool isZero = totalAmount == 0;

    final double? res = await showDialog<double?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('exchange_voucher.title'.tr()),
          content: Text('exchange_voucher.subtitle'.tr()),
          actions: [
            if (isZero)
              AlertDialogButton(
                  onPressed: () => Navigator.pop(context, zero),
                  text: 'exchange_voucher.okay'.tr())
            else
              Row(
                children: [
                  AlertDialogButton(
                      onPressed: () => Navigator.pop(context, totalAmount * -1),
                      text: 'exchange_voucher.cash'.tr(namedArgs: {
                        'value': totalAmount.toStringAsFixed(2)
                      })),
                  const SizedBox(
                    width: 25,
                  ),
                  AlertDialogButton(
                      onPressed: () async {
                        Navigator.pop(context, zero);
                      },
                      text: 'exchange_voucher.exchange'.tr(namedArgs: {
                        'value': totalAmount.toStringAsFixed(2)
                      })),
                ],
              )
          ],
        );
      },
    );
    if (res != null) {
      if (!isZero && res == zero) {
        final voucher = GiftVoucher(
            vCDESC: 'Exchange Voucher',
            vCNO: 'exchange_999999_voucher',
            vCVAlUE: totalAmount);
        totalAmount = 0;
        String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
        String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';

        String refCode = '$invoiceNo@${user}Ex$totalAmount';
        bool hasPermission = false;
        hasPermission = SpecialPermissionHandler(context: context)
            .hasPermission(
                permissionCode: PermissionCode.generateExchangeVoucher,
                accessType: "A",
                refCode: refCode);

        //if user doesnt have the permission
        if (!hasPermission) {
          final res = await SpecialPermissionHandler(context: context)
              .askForPermission(
                  permissionCode: PermissionCode.generateExchangeVoucher,
                  accessType: "A",
                  refCode: refCode);
          hasPermission = res.success;
          user = res.user;
        }
        if (hasPermission) {
          await calculator.addGv(voucher, 1, context, permission: false);
        } else {
          return;
        }
      } else if (!isZero && res < zero) {
        totalAmount = res;
        String user = userBloc.currentUser?.uSERHEDUSERCODE ?? "";
        String invoiceNo = cartBloc.cartSummary?.invoiceNo ?? '';

        String refCode = '$invoiceNo@${user}Ex$totalAmount';
        bool hasPermission = false;
        hasPermission = SpecialPermissionHandler(context: context)
            .hasPermission(
                permissionCode: PermissionCode.cashRefund,
                accessType: "A",
                refCode: refCode);

        //if user doesnt have the permission
        if (!hasPermission) {
          final res = await SpecialPermissionHandler(context: context)
              .askForPermission(
                  permissionCode: PermissionCode.generateExchangeVoucher,
                  accessType: "A",
                  refCode: refCode);
          hasPermission = res.success;
          user = res.user;
        }
        if (!hasPermission) {
          return;
        }
      }
      //save payment
      cartBloc.addPayment(PaidModel(
          // temp < 0 ? balanceDueTemp : entered,
          res,
          totalAmount,
          false,
          'CSH',
          'CSH',
          '',
          null,
          zero,
          'Cash',
          'Cash'));
      final invRes =
          await InvoiceController().billClose(invoiced: true, context: context);
      if (invRes.success) {
        String invoice = cartBloc.cartSummary?.invoiceNo ?? "";

        //added to update the latest saved invoice number to the local storage
        InvoiceController().setInvoiceNo(invoice);

        LastInvoiceDetails lastInvoice = LastInvoiceDetails(
            invoiceNo: invoice,
            billAmount: totalAmount.toStringAsFixed(2),
            dueAmount: totalAmount.toStringAsFixed(2),
            paidAmount: '0');
        cartBloc.updateLastInvoice(lastInvoice);
        await cartBloc.resetCart();

        // print invoice
        // await PrintController().printHandler(
        //     invoice,
        //     PrintController()
        //         .printInvoice(invoice, invRes.earnedPoints, 0, false, null),
        //     context);

        if (POSConfig.crystalPath != '') {
          await PrintController().printHandler(
              invoice,
              PrintController()
                  .printInvoice(invoice, invRes.earnedPoints, 0, false, null),
              context);
        } else {
          POSConfig.localPrintData = invRes.resReturn ?? '';
          var stopwatch = Stopwatch();

          stopwatch.start();
          POSManualPrint().printInvoice(
              data: invRes.resReturn!, points: invRes.earnedPoints);
          stopwatch.stop();
          print(stopwatch.elapsed.toString());
        }
        // await PrintController().printHandler(
        //     invoice, PrintController().printExchangeVoucher(invoice), context);
      }
    }
  }

  Future showAlert(String key) async {
    EasyLoading.dismiss();
    showDialog(
      context: context,
      builder: (context) {
        return POSErrorAlert(
            title: "$key.title".tr(),
            subtitle: "$key.subtitle".tr(),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("$key.okay".tr()),
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        POSConfig().primaryDarkGrayColor.toColor()),
              )
            ]);
      },
    ).then((value) {
      setState(() {
        active = true;
      });
    });
  }

  /// get price modes
  Future<void> _getPriceModes() async {
    if (mounted) {
      setState(() {
        _tempIndex = 0;
      });
    }
    if ((cartBloc.currentCart?.length ?? -1) != 0) {
      focusNode.requestFocus();
      return;
    }
    final List<PriceModes> priceModeList = priceModeBloc.priceModes;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'price_modes.price_modes'.tr(),
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              height: ScreenUtil().screenHeight * 0.65,
              width: ScreenUtil().screenWidth * 0.35,
              child: KeyboardListener(
                autofocus: true,
                onKeyEvent: (KeyEvent value) {
                  if (value.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _tempIndex++;
                    if (_tempIndex >= priceModeList.length) {
                      _tempIndex = 0;
                    }
                  } else if (value.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _tempIndex--;
                    if (_tempIndex < 0) {
                      _tempIndex = priceModeList.length - 1;
                    }
                  }
                  if (mounted) {
                    setState(() {});
                  }
                },
                focusNode: FocusNode(),
                child: ListView.builder(
                  itemCount: priceModeList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      selected: index == _tempIndex,
                      onTap: () => _selectPriceMode(priceModeList[index]),
                      title: Row(
                        children: <Widget>[
                          Text(
                            priceModeList[index].prMDESC ?? '',
                            style: CurrentTheme.headline6,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        });
      },
    );
    focusNode.requestFocus();
  }

  ///select a price mode
  Future<void> _selectPriceMode(PriceModes priceMode) async {
    final summary = cartBloc.cartSummary ?? cartBloc.defaultSummary;
    summary.priceMode = priceMode.prMCODE;
    summary.priceModeDesc = priceMode.prMDESC;
    cartBloc.updateCartSummary(summary);
    await InvoiceController().updateTempCartSummary(summary);
    focusNode.requestFocus();
    Navigator.pop(context, priceMode);
  }

  /// added by [TM.Sakir] -- to trigger the f12 customer change function
  Future<bool> hasPermission(String code) async {
    final res = await CustomerHelper(context).hasCustomerMasterPermission(code);
    return res;
  }

  Future<Object?> currentCustomerChange(BuildContext context) {
    customerNode.requestFocus();
    return showGeneralDialog(
        context: context,
        transitionDuration: const Duration(milliseconds: 200),
        barrierDismissible: true,
        barrierLabel: '',
        transitionBuilder: (context, a, b, _) => KeyboardListener(
              focusNode: customerNode,
              onKeyEvent: (value) async {
                if (value is KeyDownEvent) {
                  if (value.physicalKey == PhysicalKeyboardKey.keyV) {
                    LoyaltySummary? res;
                    bool permission = await hasPermission("A");
                    //ask

                    if (permission) {
                      EasyLoading.show(status: 'please_wait'.tr());
                      res = await LoyaltyController().getLoyaltySummary(
                          customerBloc.currentCustomer?.cMCODE ?? "");
                      EasyLoading.dismiss();

                      await showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (context) {
                          return CustomerProfile(
                            customerBloc.currentCustomer,
                            loyaltySummary: res,
                          );
                        },
                      );
                      Navigator.pop(
                          context); //closing the showdialog box at the end
                    }
                  }
                  if (value.physicalKey == PhysicalKeyboardKey.keyN) {
                    Navigator.pop(context);
                  }
                  if (value.physicalKey == PhysicalKeyboardKey.keyY) {
                    Navigator.pop(context);
                    var cartSum = cartBloc.cartSummary;
                    if (cartSum != null) {
                      cartSum.customerCode = '';
                      cartBloc.updateCartSummary(cartSum);
                    }
                    customerBloc.changeCurrentCustomer(null);
                    CustomerController().showCustomerPicker(context);
                  }
                }
              },
              child: Transform.scale(
                scale: a.value,
                child: AlertDialog(
                    title: Text('general_dialog.handle_cust'.tr()),
                    content: Text('general_dialog.handle_cust_desc'.tr()),
                    actions: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  POSConfig().primaryDarkGrayColor.toColor()),
                          onPressed: () async {
                            LoyaltySummary? res;
                            bool permission = await hasPermission("A");
                            //ask

                            if (permission) {
                              EasyLoading.show(status: 'please_wait'.tr());
                              res = await LoyaltyController().getLoyaltySummary(
                                  customerBloc.currentCustomer?.cMCODE ?? "");
                              EasyLoading.dismiss();

                              await showModalBottomSheet(
                                isScrollControlled: true,
                                context: context,
                                builder: (context) {
                                  return CustomerProfile(
                                    customerBloc.currentCustomer,
                                    loyaltySummary: res,
                                  );
                                },
                              );
                              Navigator.pop(
                                  context); //closing the showdialog box at the end
                            }
                          },
                          child: RichText(
                              text: TextSpan(text: '', children: [
                            TextSpan(
                                text: 'general_dialog.view_profile'
                                    .tr()
                                    .substring(0, 1),
                                style: TextStyle(
                                    decoration: TextDecoration.underline)),
                            TextSpan(
                                text: 'general_dialog.view_profile'
                                    .tr()
                                    .substring(1))
                          ]))),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  POSConfig().primaryDarkGrayColor.toColor()),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: RichText(
                              text: TextSpan(text: '', children: [
                            TextSpan(
                                text: 'general_dialog.no'.tr().substring(0, 1),
                                style: TextStyle(
                                    decoration: TextDecoration.underline)),
                            TextSpan(
                                text: 'general_dialog.no'.tr().substring(1))
                          ]))),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  POSConfig().primaryDarkGrayColor.toColor()),
                          onPressed: () {
                            Navigator.pop(context);
                            var cartSum = cartBloc.cartSummary;
                            if (cartSum != null) {
                              cartSum.customerCode = '';
                              cartBloc.updateCartSummary(cartSum);
                            }
                            customerBloc.changeCurrentCustomer(null);
                            CustomerController().showCustomerPicker(context);
                          },
                          child: RichText(
                              text: TextSpan(text: '', children: [
                            TextSpan(
                                text: 'general_dialog.yes'.tr().substring(0, 1),
                                style: TextStyle(
                                    decoration: TextDecoration.underline)),
                            TextSpan(
                                text: 'general_dialog.yes'.tr().substring(1))
                          ])))
                    ]),
              ),
            ),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SizedBox();
        });
  }
}

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.tabController,
    required this.currentPageIndex,
    required this.onUpdateCurrentPageIndex,
    required this.isOnDesktopAndWeb,
  });

  final int currentPageIndex;
  final TabController tabController;
  final void Function(int) onUpdateCurrentPageIndex;
  final bool isOnDesktopAndWeb;

  @override
  Widget build(BuildContext context) {
    if (!isOnDesktopAndWeb) {
      return const SizedBox.shrink();
    }
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // IconButton(
          //   splashRadius: 8.0,
          //   padding: EdgeInsets.zero,
          //   onPressed: () {
          //     if (currentPageIndex == 0) {
          //       return;
          //     }
          //     onUpdateCurrentPageIndex(currentPageIndex - 1);
          //   },
          //   icon: const Icon(
          //     Icons.arrow_left_rounded,
          //     size: 35.0,
          //   ),
          // ),
          TabPageSelector(
            controller: tabController,
            color: colorScheme.surface,
            selectedColor: colorScheme.secondary,
          ),
          // IconButton(
          //   splashRadius: 8.0,
          //   padding: EdgeInsets.zero,
          //   onPressed: () {
          //     if (currentPageIndex == 2) {
          //       return;
          //     }
          //     onUpdateCurrentPageIndex(currentPageIndex + 1);
          //   },
          //   icon: const Icon(
          //     Icons.arrow_right_rounded,
          //     size: 35.0,
          //   ),
          // ),
        ],
      ),
    );
  }
}

class StreamContainer extends StatefulWidget {
  final VoidCallback onUpdate;

  StreamContainer({Key? key, required this.onUpdate}) : super(key: key);
  @override
  _StreamContainerState createState() => _StreamContainerState();
}

class _StreamContainerState extends State<StreamContainer> {
  final StreamController<String> _streamController = StreamController<String>();
  bool _isExpanded = false;
  String _message = '';
  bool opened = false;
  bool stop = false;

  @override
  void initState() {
    super.initState();
    // Simulate receiving data from a stream after 2 seconds
    // Future.delayed(Duration(seconds: 3), () {
    //   _streamController.add('SERVER MODE AVAILABLE');
    // });
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  void _handleNewData(String data) async {
    setState(() {
      _isExpanded = true;
      _message = data;
      stop = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _message = '';
        });
      }
    });
    Future.delayed(Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          opened = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return StreamBuilder(
      stream: posConnectivity
          .connectionAvailabilityStream, //_streamController.stream,
      builder: (context, snapshot) {
        bool status = false;
        if (snapshot.hasData) {
          status = snapshot.data == POSConnectivityStatus.Server;
        }
        if (!stop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (status && !opened) {
              _handleNewData('Server Connection is Available');
            }
          });
        } else if (!status && stop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _isExpanded = false;
              opened = false;
              stop = false;
            });
          });
        }

        return AnimatedContainer(
          duration: Duration(milliseconds: 500),
          width: _isExpanded
              ? width * 0.25
              : opened
                  ? width * 0.03
                  : 0,
          height: width * 0.03,
          decoration: BoxDecoration(
            color: Colors.blue[800],
            borderRadius: BorderRadius.circular(_isExpanded ? 15 : 50),
          ),
          alignment: Alignment.center,
          child: _isExpanded
              ? Container(
                  width: width * 0.25,
                  height: width * 0.03,
                  child: Text(
                    _message,
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                )
              : opened
                  ? CircleAvatar(
                      radius: width * 0.015,
                      backgroundColor: const Color.fromARGB(255, 90, 255, 68),
                      child: IconButton(
                          onPressed: () async {
                            if (!POSConfig().localMode) {
                              EasyLoading.showInfo('');
                              return;
                            }
                            if (cartBloc.cartSummary?.items != 0) {
                              EasyLoading.showError(
                                  'Finish the current invoicing process first \nto switch sever mode');
                              return;
                            }
                            bool isSwitched = false;
                            cartBloc.context = context;
                            EasyLoading.show(status: 'please_wait'.tr());
                            bool serverRes =
                                await POSConnectivity().pingToServer(time: 2);
                            EasyLoading.dismiss();
                            if (serverRes) {
                              isSwitched = await serverConnectionPopup();
                            }

                            if (isSwitched) {
                              InvoiceController().uploadBillData();

                              payModeBloc.getPayModeList();
                              payModeBloc.getCardDetails();
                              discountBloc.getDiscountTypes();
                              groupBloc.getDepartments();
                              priceModeBloc.fetchPriceModes();
                              salesRepBloc.getSalesReps();
                              await cartBloc.resetCart();
                            }
                            widget.onUpdate.call();
                          },
                          icon: Tooltip(
                            message: 'Click to switch server mode',
                            child: Icon(
                              Icons.wifi,
                              size: width * 0.013,
                            ),
                          )),
                    )
                  : SizedBox.shrink(),
        );
      },
    );
  }

  Future<bool> serverConnectionPopup() async {
    if (context != null) {
      bool? res = await showDialog<bool>(
        barrierDismissible: false,
        context: context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title:
                Text('payment_view.server_connection_confirmation_title'.tr()),
            content: Text('payment_view.server_connection_confirmation'.tr()),
            actions: [
              AlertDialogButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  text: 'payment_view.no'.tr()),
              AlertDialogButton(
                  onPressed: () {
                    posConnectivity.localConfirmed = false;
                    POSConfig().localMode = false;
                    posConnectivity.handleConnection();
                    Navigator.pop(context, true);
                  },
                  text: 'payment_view.yes'.tr())
            ],
          );
        },
      );
      return res == true;
    } else {
      return false;
    }
  }
}
