import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/controllers/pos_alerts/pos_error_alert.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../components/current_theme.dart';
import '../../models/pos/paid_model.dart';

class PaymentBreakdown extends StatefulWidget {
  const PaymentBreakdown({Key? key}) : super(key: key);

  @override
  State<PaymentBreakdown> createState() => _PaymentBreakdownState();
}

class _PaymentBreakdownState extends State<PaymentBreakdown> {
  @override
  Widget build(BuildContext context) {
    return _paymentDetails();
  }

  Widget _paymentDetails() {
    TextStyle style =
        CurrentTheme.bodyText1!.copyWith(color: CurrentTheme.primaryLightColor);
    return StreamBuilder(
        stream: cartBloc.paidListStream,
        builder:
            (BuildContext context, AsyncSnapshot<List<PaidModel>> snapshot) {
          List<PaidModel> list = [];
          if (snapshot.hasData) {
            list = snapshot.data ?? [];
          }
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
                        child: Text(
                          'paid_list.pay_hed'.tr(),
                          style: style,
                          textAlign: TextAlign.center,
                        )),
                    Expanded(
                        flex: 2,
                        child: Text('paid_list.pay_det'.tr(),
                            style: style, textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text('paid_list.pay_amount'.tr(),
                            style: style, textAlign: TextAlign.center)),
                    Expanded(
                        flex: 3,
                        child: Text('paid_list.pay_refno'.tr(),
                            style: style, textAlign: TextAlign.center)),
                    Expanded(
                        flex: 2,
                        child: Text('paid_list.pay_rate'.tr(),
                            style: style, textAlign: TextAlign.center)),
                    Expanded(
                        flex: 3,
                        child: Text('paid_list.pay_refdate'.tr(),
                            style: style, textAlign: TextAlign.center)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _paidListItem(list[index]);
                    },
                  ),
                ),
                const Divider(),
                AlertDialogButton(
                    onPressed: () => Navigator.pop(context),
                    text: 'paid_list.close'.tr())
              ],
            ),
          );
        });
  }

  Widget _paidListItem(PaidModel paiditem) {
    TextStyle style =
        CurrentTheme.bodyText1!.copyWith(color: CurrentTheme.primaryLightColor);
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: Text(paiditem.phDesc ?? '',
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text(paiditem.pdDesc ?? '',
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text(paiditem.paidAmount.toStringAsFixed(2),
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 3,
            child: Text((paiditem.refNo).toString(),
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text((paiditem.rate ?? 0).toString(),
                style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 3,
            child: Text((paiditem.selectedDate ?? '').toString(),
                style: style, textAlign: TextAlign.center)),
      ],
    );
  }
}
