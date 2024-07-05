/// Author: [TM.Sakir] on 14-02-2024 02:10 PM

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/components/current_theme.dart';
import 'package:checkout/controllers/pos_alerts/pos_error_alert.dart';
import 'package:checkout/models/pos/cart_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DiscountBreakdown extends StatefulWidget {
  const DiscountBreakdown({super.key});

  @override
  State<DiscountBreakdown> createState() => _DiscountBreakdownState();
}

class _DiscountBreakdownState extends State<DiscountBreakdown> {
  double totalNetDisc = 0;
  double totalLineDisc = 0;
  double netDiscAmount = 0;
  double lineDiscAmtFromPer = 0;
  double lineDiscAmtFromAmt = 0;
  @override
  void initState() {
    super.initState();
    // giving a small refresh after the entire widgets are built -- so it refresh (total discount) widget
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
   final TextStyle style =
        CurrentTheme.bodyText1!.copyWith(color: CurrentTheme.primaryLightColor);
    List<CartModel?> item = [];
    cartBloc.currentCart?.forEach((key, value) {
      item.add(value);
    });

    return SizedBox(
      height: ScreenUtil().screenHeight,
      width: ScreenUtil().screenWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text('discount_list.disc_lineNo'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 4,
                  child: Text('discount_list.disc_pro'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 3,
                  child: Text('discount_list.disc_proSelling'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('discount_list.disc_proQty'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('discount_list.disc_lineDiscPer'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('discount_list.disc_lineDiscAmt'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('discount_list.disc_netDisc'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 3,
                  child: Text(
                    'discount_list.disc_totalLineDisc'.tr(),
                    style: style,
                    textAlign: TextAlign.center,
                  )),
              Expanded(
                  flex: 3,
                  child: Text(
                    'discount_list.disc_totalNetDisc'.tr(),
                    style: style,
                    textAlign: TextAlign.center,
                  )),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: item.length ?? 0,
              itemBuilder: (BuildContext context, int i) {
                if (item.isNotEmpty && (item[i]!.itemVoid! != true)
                    // &&
                    // (item[i]?.billDiscPer != 0 ||
                    //     item[i]?.discPer != 0 ||
                    //     item[i]?.discAmt != 0)

                    ) {
                  double grossAmount =
                      (item[i]?.unitQty ?? 0) * (item[i]?.proSelling ?? 0);
                  netDiscAmount =
                      ((item[i]?.billDiscPer ?? 0) * grossAmount) / 100;
                  lineDiscAmtFromPer =
                      ((item[i]?.discPer ?? 0) * grossAmount) / 100;
                  lineDiscAmtFromAmt = (item[i]?.discAmt ?? 0);

                  totalNetDisc += netDiscAmount;
                  totalLineDisc += (lineDiscAmtFromPer + lineDiscAmtFromAmt);

                  return _discountListItem(item[i]!);
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
          const Divider(),
          _discountSummary(),
          AlertDialogButton(
              onPressed: () => Navigator.pop(context),
              text: 'discount_list.close'.tr())
        ],
      ),
    );
  }

  Widget _discountListItem(CartModel item) {
   final TextStyle style1 =
        CurrentTheme.bodyText2!.copyWith(color: CurrentTheme.primaryLightColor);
   final TextStyle style2 = CurrentTheme.bodyText2!
        .copyWith(color: Colors.greenAccent, fontWeight: FontWeight.bold);
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: Text('${item.lineNo ?? 1}',
                style: style1, textAlign: TextAlign.center)),
        Expanded(
            flex: 4,
            child: Text('${item.posDesc ?? 'N/A'}',
                overflow: TextOverflow.ellipsis,
                style: style1,
                textAlign: TextAlign.center)),
        Expanded(
            flex: 3,
            child: Text('${item.selling ?? 'N/A'}',
                overflow: TextOverflow.ellipsis,
                style: style1,
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text('${item.unitQty ?? 'N/A'}',
                overflow: TextOverflow.ellipsis,
                style: style1,
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text('${item.discPer ?? 0} %',
                style: (item.discPer == null || item.discPer == 0)
                    ? style1
                    : style2,
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text('${item.discAmt?.toStringAsFixed(2) ?? 0}',
                style: (item.discAmt == null || item.discAmt == 0)
                    ? style1
                    : style2,
                textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text('${item.billDiscPer ?? 0} %',
                style: (item.billDiscPer == null || item.billDiscPer == 0)
                    ? style1
                    : style2,
                textAlign: TextAlign.center)),
        Expanded(
            flex: 3,
            child: Text(
                '${(lineDiscAmtFromPer + lineDiscAmtFromAmt).toStringAsFixed(2)}',
                style: ((lineDiscAmtFromPer + lineDiscAmtFromAmt) == 0)
                    ? style1
                    : style2,
                textAlign: TextAlign.center)),
        Expanded(
            flex: 3,
            child: Text('${netDiscAmount.toStringAsFixed(2)}',
                style: (netDiscAmount == 0) ? style1 : style2,
                textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _discountSummary() {
   final double promoDiscount = (cartBloc.cartSummary?.promoDiscount ?? 0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'discount_list.disc_grandTotalLineDisc'.tr() +
                  '    ${totalLineDisc.toStringAsFixed(2)}',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
                'discount_list.disc_grandTotalNetDisc'.tr() +
                    '     ${totalNetDisc.toStringAsFixed(2)}',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
                'discount_list.disc_grandTotalPromoDisc'.tr() +
                    '     ${promoDiscount.toStringAsFixed(2)}',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700)),
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
                'discount_list.disc_totalDisc'.tr() +
                    '    ${(totalLineDisc + totalNetDisc + promoDiscount).toStringAsFixed(2)}',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        const Divider(),
        const SizedBox(
          height: 20,
        )
      ],
    );
  }
}
