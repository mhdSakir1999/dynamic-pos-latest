/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 6/20/22, 11:28 AM
 */
import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/pos/inv_tax.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TaxBreakdownView extends StatefulWidget {
  const TaxBreakdownView({Key? key}) : super(key: key);

  @override
  _TaxBreakdownViewState createState() => _TaxBreakdownViewState();
}

class _TaxBreakdownViewState extends State<TaxBreakdownView> {
  @override
  Widget build(BuildContext context) {
   final TextStyle style =
        CurrentTheme.bodyText1!.copyWith(color: CurrentTheme.primaryLightColor);
    List<InvTax> invTax = cartBloc.cartSummary?.invTax ?? [];
    double taxInc = cartBloc.cartSummary?.taxInc??0;
    double taxExc = cartBloc.cartSummary?.taxExc??0;
    return SizedBox(
      height: ScreenUtil().screenHeight,
      width: ScreenUtil().screenWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('tax.inclusive'.tr() + ': ' + taxInc.thousandsSeparator()),
          Text('tax.exclusive'.tr() + ': ' + taxExc.thousandsSeparator()),
          Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Text(
                    'tax.tax_code'.tr(),
                    style: style,
                    textAlign: TextAlign.center,
                  )),
              Expanded(
                  flex: 3,
                  child: Text('tax.product_code'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 1,
                  child: Text('tax.tax_seq'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 1,
                  child: Text('tax.tax_per'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 1,
                  child: Text('tax.tax_inc'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('tax.gross'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('tax.tax_amount'.tr(),
                      style: style, textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('tax.amount'.tr(),
                      style: style, textAlign: TextAlign.center)),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: invTax.length,
              itemBuilder: (BuildContext context, int index) {
                return _taxListItem(invTax[index]);
              },
            ),
          ),
          const Divider(),
          AlertDialogButton(onPressed: ()=>Navigator.pop(context), text: 'tax.close'.tr())
        ],
      ),
    );
  }

  Widget _taxListItem(InvTax invTax) {
    TextStyle style =
        CurrentTheme.bodyText1!.copyWith(color: CurrentTheme.primaryLightColor);
    return Row(
      children: [
        Expanded(
            flex: 1,
            child: Text(
              invTax.taxCode,
              style: style,
              textAlign: TextAlign.center,
            )),
        Expanded(
            flex: 3,
            child: Text(invTax.productCode,
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 1,
            child: Text(invTax.taxSeq.toString(),
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 1,
            child: Text(invTax.taxPercentage.toStringAsFixed(2),
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 1,
            child: Text(invTax.taxInc?'Yes':'No',
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text(invTax.grossAmount.toString().parseDouble().thousandsSeparator(),
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text(invTax.taxAmount.toString().parseDouble().thousandsSeparator(),
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text(invTax.afterTax.toString().parseDouble().thousandsSeparator(),
                style: style, textAlign: TextAlign.center)),
      ],
    );
  }


}
