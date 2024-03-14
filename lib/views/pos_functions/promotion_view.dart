/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/20/22, 12:36 PM
 */

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/controllers/pos_price_calculator.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/pos/Inv_appliedPeomotons.dart';
import 'package:checkout/models/pos/promotion_free_items.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../components/components.dart';
import '../../models/pos/cart_model.dart';
import '../../models/pos/selectable_promotion_res.dart';

class PromotionView extends StatefulWidget {
  final List<CartModel> cartList;
  final double totalBillDiscount;
  final double totalLineDiscount;
  final List<SelectablePaymentModeWisePromotions> selectablePromotions;
  final List<InvBillDiscAmountPromo> billDiscPromotions;
  const PromotionView({
    Key? key,
    required this.cartList,
    required this.totalBillDiscount,
    required this.totalLineDiscount,
    required this.selectablePromotions,
    required this.billDiscPromotions,
  }) : super(key: key);

  @override
  _PromotionViewState createState() => _PromotionViewState();
}

class _PromotionViewState extends State<PromotionView> {
  POSPriceCalculator _calculator = POSPriceCalculator();
  TextEditingController _textEditingController = TextEditingController();
  TextEditingController _GVtextEditingController = TextEditingController();
  late double width = ScreenUtil().screenWidth / 22;
  late double sPromoCode;
  late double sPromoDesc;
  late double sItemCode;
  late double sItemDesc;
  late double sPer;
  late double sAmt;
  late double sGVValue;
  late List<SelectablePaymentModeWisePromotions> selectablePromotionsList;
  SelectablePaymentModeWisePromotions? selectablePromotion;
  late List<InvBillDiscAmountPromo> billDiscountPromos;
  @override
  void initState() {
    super.initState();
    width = ScreenUtil().screenWidth / 22;
    sPromoCode = width * 2;
    sPromoDesc = width * 4;
    sItemCode = width * 2;
    sItemDesc = width * 6;
    sPer = width;
    sAmt = width * 2;
    selectablePromotionsList = widget.selectablePromotions;
    billDiscountPromos = widget.billDiscPromotions;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Row(
          //   children: [
          //     _buildScanGVField(),
          //     _buildScanItemField(),
          //   ],
          // ),
          _buildScanGVField(),
          _buildScanItemField(),
          _buildAppliedPromotions(),
          _buildBillDiscountPromo(),
          _buildEligibleItems(),
          _buildEligibleGVs(),
          _buildEligibleTickets(),
          _buildSelectablePromo(),
          SizedBox(
            height: 20.h,
          ),
          SizedBox(
            height: 20.h,
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedPromotions() {
    double subTotal = cartBloc.cartSummary?.subTotal ?? 0;
    return Column(
      children: [
        _appliedItem(),
        _buildDiscountAmount('promo.promo_total_value', subTotal),
        _buildDiscountAmount('Bill Discount', widget.totalBillDiscount),
        _buildDiscountAmount('Line Discount', widget.totalLineDiscount),
        // _buildDiscountAmount('promo.promo_discount_value',
        //     widget.totalLineDiscount + widget.totalBillDiscount),
        _buildDiscountAmount('promo.promo_net_bill_value',
            subTotal - (widget.totalLineDiscount + widget.totalBillDiscount)),
      ],
    );
  }

  Widget _appliedItem() {
    // final cart = widget.cartList
    //     .where((element) => (element.promoCode ?? '').isNotEmpty)
    //     .toList();
    final cart = widget.cartList
        .where((element) =>
            (element.promoDiscAmt ?? 0) > 0 ||
            (element.promoDiscPre ?? 0) > 0 ||
            (element.promoBillDiscPre ?? 0) > 0)
        .toList();
    if (cart.isEmpty) {
      return SizedBox.shrink();
    }
    return Column(
      children: [
        Text('promo.applied_title'.tr()),
        Divider(),
        SizedBox(
          width: double.infinity,
          child: SizedBox(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: cart.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Row(
                    children: [
                      _buildRowItem('promo.promo_code'.tr(), sPromoCode, true),
                      _buildRowItem('promo.promo_name'.tr(), sPromoDesc, true),
                      _buildRowItem('promo.item_code'.tr(), sItemCode, true),
                      _buildRowItem('promo.item_name'.tr(), sItemDesc, true),
                      _buildRowItem('promo.disc_per'.tr(), sPer, true),
                      _buildRowItem('promo.disc_amt'.tr(), sAmt, true),
                      _buildRowItem('promo.bill_per'.tr(), sAmt, true),
                    ],
                  );
                }
                CartModel item = cart[index - 1];
                return SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      _buildRowItem(item.promoCode ?? '', sPromoCode),
                      _buildRowItem(item.promoDesc ?? '', sPromoDesc),
                      _buildRowItem(item.proCode, sItemCode),
                      _buildRowItem(item.posDesc, sItemDesc),
                      _buildRowItem(
                          item.promoDiscPre?.toStringAsFixed(2) ?? '0',
                          sPer,
                          false,
                          true),
                      _buildRowItem(
                          item.promoDiscAmt?.thousandsSeparator() ?? '0.00',
                          sAmt,
                          false,
                          true),
                      _buildRowItem(
                          item.promoBillDiscPre?.toStringAsFixed(2) ?? '0.00',
                          sAmt,
                          false,
                          true),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Divider(),
      ],
    );
  }

  Widget _buildDiscountAmount(String text, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
            flex: 10,
            child: Text(
              text.tr(),
              textAlign: TextAlign.end,
            )),
        Expanded(
            child: Text(amount.toStringAsFixed(2), textAlign: TextAlign.end))
      ],
    );
  }

  Widget _buildEligibleTickets() {
    return Column(
      children: [
        StreamBuilder(
          stream: cartBloc.PromotionFreeTicket,
          builder: (BuildContext context,
              AsyncSnapshot<List<PromotionFreeTickets>> snapshot) {
            if (snapshot.data == null) {
              return SizedBox.shrink();
            }
            final List<PromotionFreeTickets> freeTicketList = snapshot.data!;
            if (freeTicketList.isEmpty) {
              return SizedBox.shrink();
            }
            return Column(
              children: [
                Text('promo.free_items_title'.tr()),
                SizedBox(
                  height: 20.h,
                ),
                SizedBox(
                  width: double.infinity,
                  child: SizedBox(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: freeTicketList.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Row(
                            children: [
                              _buildRowItem(
                                  'promo.promo_code'.tr(), sPromoCode, true),
                              _buildRowItem('promo.promo_name'.tr(),
                                  sPromoDesc * 2, true),
                              _buildRowItem('promo.free_ticket_code'.tr(),
                                  sItemCode * 1.5, true),
                              _buildRowItem('promo.value'.tr(), sPer, true),
                            ],
                          );
                        }

                        //return ListView.builder(
                        //itemCount: freeTicketList.length,
                        //physics: NeverScrollableScrollPhysics(),
                        //shrinkWrap: true,
                        //itemBuilder: (BuildContext context, int x) {
                        final item = freeTicketList[index - 1];
                        Color? textColor;
                        if (item.ticketQty > 0) {
                          textColor = Colors.greenAccent;
                        }
                        return SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              _buildRowItem(item.promotionCode, sPromoCode,
                                  false, false, textColor),
                              _buildRowItem(item.promotionDesc, sPromoDesc * 2,
                                  false, false, textColor),
                              _buildRowItem(item.ticketSerial, sItemCode * 1.5,
                                  false, false, textColor),
                              _buildRowItem(item.ticketValue.toStringAsFixed(2),
                                  sPer, false, true, textColor),
                            ],
                          ),
                        );
                        //},
                        //);
                      },
                    ),
                  ),
                ),
                Divider(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEligibleGVs() {
    return Column(
      children: [
        StreamBuilder(
          stream: cartBloc.PromotionFreeGV,
          builder: (BuildContext context,
              AsyncSnapshot<List<PromotionFreeGVs>> snapshot) {
            if (snapshot.data == null) {
              return SizedBox.shrink();
            }
            final List<PromotionFreeGVs> freeGVList = snapshot.data!;
            if (freeGVList.isEmpty) {
              return SizedBox.shrink();
            }
            return Column(
              children: [
                Text('promo.free_items_title'.tr()),
                SizedBox(
                  height: 20.h,
                ),
                SizedBox(
                  width: double.infinity,
                  child: SizedBox(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: freeGVList.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Row(
                            children: [
                              _buildRowItem(
                                  'promo.promo_code'.tr(), sPromoCode, true),
                              _buildRowItem(
                                  'promo.promo_name'.tr(), sPromoDesc, true),
                              _buildRowItem(
                                  'promo.free_gv_code'.tr(), sItemCode, true),
                              _buildRowItem(
                                  'promo.free_gv_name'.tr(), sItemDesc, true),
                              _buildRowItem('promo.qty'.tr(), sPer, true),
                              _buildRowItem(
                                  'promo.scanned_qty'.tr(), sAmt, true),
                            ],
                          );
                        }

                        return ListView.builder(
                          itemCount: freeGVList.length,
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int x) {
                            final item = freeGVList[x];
                            Color? textColor;
                            if (item.scannedQty > 0) {
                              textColor = Colors.greenAccent;
                            }
                            return SizedBox(
                              width: double.infinity,
                              child: Row(
                                children: [
                                  _buildRowItem(item.promotionCode, sPromoCode,
                                      false, false, textColor),
                                  _buildRowItem(item.promotionDesc, sPromoDesc,
                                      false, false, textColor),
                                  _buildRowItem(item.gvName.toString(),
                                      sItemCode, false, false, textColor),
                                  _buildRowItem(item.gvValue.toStringAsFixed(2),
                                      sItemDesc, false, false, textColor),
                                  _buildRowItem(
                                      item.remainingQty.toStringAsFixed(2),
                                      sPer,
                                      false,
                                      true,
                                      textColor),
                                  _buildRowItem(
                                      item.scannedQty.toStringAsFixed(2),
                                      sAmt,
                                      false,
                                      true,
                                      textColor),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Divider(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEligibleItems() {
    return Column(
      children: [
        StreamBuilder(
          stream: cartBloc.promotionFreeItem,
          builder: (BuildContext context,
              AsyncSnapshot<List<PromotionFreeItems>> snapshot) {
            if (snapshot.data == null) {
              return SizedBox.shrink();
            }
            final List<PromotionFreeItems> freeItemsList = snapshot.data!;
            if (freeItemsList.isEmpty) {
              return SizedBox.shrink();
            }
            return Column(
              children: [
                Text('promo.free_items_title'.tr()),
                SizedBox(
                  height: 20.h,
                ),
                SizedBox(
                  width: double.infinity,
                  child: SizedBox(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: freeItemsList.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Row(
                            children: [
                              _buildRowItem(
                                  'promo.promo_code'.tr(), sPromoCode, true),
                              _buildRowItem(
                                  'promo.promo_name'.tr(), sPromoDesc, true),
                              _buildRowItem(
                                  'promo.item_code'.tr(), sItemCode, true),
                              _buildRowItem(
                                  'promo.free_item_code'.tr(), sItemCode, true),
                              _buildRowItem(
                                  'promo.free_item_name'.tr(), sItemDesc, true),
                              _buildRowItem('promo.qty'.tr(), sPer, true),
                              _buildRowItem(
                                  'promo.scanned_qty'.tr(), sAmt, true),
                            ],
                          );
                        }
                        final freeItem = freeItemsList[index - 1];
                        List<PromotionFreeItemDetails> itemDetailsList =
                            freeItem.freeItemBundle;
                        return ListView.builder(
                          itemCount: itemDetailsList.length,
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int x) {
                            final item = itemDetailsList[x];
                            Color? textColor;
                            if (item.scannedQty > 0) {
                              textColor = Colors.greenAccent;
                            }
                            return SizedBox(
                              width: double.infinity,
                              child: Row(
                                children: [
                                  _buildRowItem(freeItem.promotionCode,
                                      sPromoCode, false, false, textColor),
                                  _buildRowItem(freeItem.promotionDesc,
                                      sPromoDesc, false, false, textColor),
                                  _buildRowItem(freeItem.originalItemCode,
                                      sItemCode, false, false, textColor),
                                  _buildRowItem(item.proCode, sItemCode, false,
                                      false, textColor),
                                  _buildRowItem(item.proDesc, sItemDesc, false,
                                      false, textColor),
                                  _buildRowItem(
                                      freeItem.remainingQty.toStringAsFixed(2),
                                      sPer,
                                      false,
                                      true,
                                      textColor),
                                  _buildRowItem(
                                      item.scannedQty.toStringAsFixed(2),
                                      sAmt,
                                      false,
                                      true,
                                      textColor),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Divider(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRowItem(String text,
      [double size = 1,
      bool isHeader = false,
      bool amount = false,
      Color? textColor]) {
    TextAlign textAlign = TextAlign.left;
    if (isHeader) {
      textAlign = TextAlign.center;
    }
    if (amount) {
      textAlign = TextAlign.right;
    }
    return Container(
        alignment: Alignment.center,
        width: size,
        child: Text(
          text,
          style: CurrentTheme.bodyText2!.copyWith(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: textColor),
          textAlign: textAlign,
        ));
  }

  Widget _buildScanItemField() {
    return StreamBuilder(
      stream: cartBloc.promotionFreeItem,
      builder: (BuildContext context,
          AsyncSnapshot<List<PromotionFreeItems>> snapshot) {
        if (snapshot.data == null) {
          return SizedBox();
        }
        final List<PromotionFreeItems> freeItemsList = snapshot.data!;
        List canShow = freeItemsList.where((e) => e.remainingQty > 0).toList();
        if (canShow.isEmpty) {
          return SizedBox();
        }
        return Column(
          children: [
            Row(
              children: [
                Spacer(),
                // Text('promo.scan'.tr()),
                // SizedBox(
                //   width: 15.w,
                // ),
                Expanded(
                  child: TextField(
                    cursorWidth: 0,
                    autofocus: true,
                    controller: _textEditingController,
                    onEditingComplete: () {
                      _calculator.addPromotionFreeItem(
                          _textEditingController.text, context);
                      _textEditingController.clear();
                    },
                    decoration: InputDecoration(
                        filled: true, hintText: "Scan Free Item"),
                  ),
                ),
              ],
            ),
            Divider(),
          ],
        );
      },
    );
  }

  Widget _buildScanGVField() {
    return StreamBuilder(
      stream: cartBloc.PromotionFreeGV,
      builder: (BuildContext context,
          AsyncSnapshot<List<PromotionFreeGVs>> snapshot) {
        if (snapshot.data == null) {
          return SizedBox();
        }
        final List<PromotionFreeGVs> freeGVList = snapshot.data!;
        List canShow = freeGVList.where((e) => e.remainingQty > 0).toList();
        if (canShow.isEmpty) {
          return SizedBox();
        }
        return Column(
          children: [
            Row(
              children: [
                Spacer(),
                // Text('promo.scan'.tr()),
                // SizedBox(
                //   width: 15.w,
                // ),
                Expanded(
                  child: TextField(
                    cursorWidth: 0,
                    autofocus: true,
                    controller: _GVtextEditingController,
                    onEditingComplete: () {
                      _calculator.addPromotionFreeGV(
                          _GVtextEditingController.text, context);
                      _GVtextEditingController.clear();
                    },
                    decoration: InputDecoration(
                        filled: true, hintText: "Scan Free Voucher"),
                  ),
                ),
              ],
            ),
            Divider(),
          ],
        );
      },
    );
  }

  Widget _buildSelectablePromo() {
    if (selectablePromotionsList.isEmpty) {
      return SizedBox.shrink();
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: selectablePromotionsList.length + 2,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Column(
            children: [
              Text(
                'promo.selectable_promo'.tr(),
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            ],
          );
        }
        if (index == selectablePromotionsList.length + 1) {
          return Container(
              width: 150,
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                  onPressed: selectablePromotion == null
                      ? null
                      : () async {
                          Navigator.pop(context, selectablePromotion);
                        },
                  child: Text('promo.apply'.tr())));
        }
        final promo = selectablePromotionsList[index - 1];
        TextStyle style = CurrentTheme.bodyText2!;
        bool selected = selectablePromotion == promo;
        if (selected) {
          style = style.copyWith(fontWeight: FontWeight.bold);
        }
        return ListTile(
          title: Text(
            promo.desc,
            style: style,
          ),
          onTap: () {
            if (selected) {
              selectablePromotion = null;
            } else {
              selectablePromotion = promo;
            }
            if (mounted) setState(() {});
          },
          selectedTileColor: Colors.green,
          selected: selected,
          leading: Text(
            promo.code,
            style: style,
          ),
          trailing: Text(
            promo.amount.toStringAsFixed(2),
            style: style,
          ),
        );
      },
    );
  }

  Widget _buildBillDiscountPromo() {
    if (billDiscountPromos.isEmpty) {
      return SizedBox.shrink();
    }

    final cart = widget.cartList
        .where((element) => (element.proCode) == "DISCOUNT")
        .toList();

    if (cart.isNotEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      children: [
        Text('promo.applied_title'.tr()),
        Divider(),
        SizedBox(
          width: double.infinity,
          child: SizedBox(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: billDiscountPromos.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Row(
                    children: [
                      _buildRowItem('promo.promo_code'.tr(), sPromoCode, true),
                      _buildRowItem('promo.promo_name'.tr(), sPromoDesc, true),
                      _buildRowItem('promo.disc_amt'.tr(), sAmt, true),
                    ],
                  );
                }
                InvBillDiscAmountPromo item = billDiscountPromos[index - 1];
                return SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      _buildRowItem(item.promotion_code ?? '', sPromoCode),
                      _buildRowItem(
                          '${item.promotion_name ?? ''} (Applied as a Tender mode)',
                          sPromoDesc),
                      _buildRowItem(
                          item.discount_amt?.thousandsSeparator() ?? '0.00',
                          sAmt,
                          false,
                          true),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Divider(),
      ],
    );
  }
}
