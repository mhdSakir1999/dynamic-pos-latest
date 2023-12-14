/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/1/22, 3:34 PM
 */
import 'package:checkout/bloc/utility_bill_setup_bloc.dart';
import 'package:checkout/controllers/utility_bill_setup_controller.dart';
import 'package:checkout/views/pos_functions/utility_bill/utility_bill_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:responsive_grid/responsive_grid.dart';
import '../../../components/current_theme.dart';
import '../../../components/widgets/go_back.dart';
import '../../../components/widgets/pos_app_bar.dart';
import '../../../components/widgets/pos_background.dart';
import '../../../models/pos_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../models/utility_bill/utility_bill_setup.dart';

class UtilityBillListView extends StatelessWidget {
  static const String routeName = 'special_functions.utility_bill_payments';

  @override
  Widget build(BuildContext context) {
    return POSBackground(
        child: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.0.w),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                child: Column(
                  children: [
                    SizedBox(
                      height: POSConfig().topMargin.h,
                    ),
                    POSAppBar(),
                    SizedBox(
                      height: 8.h,
                    ),
                    // Container(
                    //   child: Row(
                    //     children: [
                    //       Expanded(
                    //           child: UserCard(
                    //         text: "",
                    //         shift: true,
                    //       )),
                    //       POSClock(),
                    //     ],
                    //   ),
                    // ),
                    SizedBox(
                      height: 8.h,
                    ),
                    specialFuctionElementTitle(
                        "special_functions.utility_bill_payments".tr()),
                  ],
                ),
              ),
              Expanded(child: _buildUtilityBillModes()),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildUtilityBillModes() {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 25,
      child: StreamBuilder(
        stream: utilityBillSetupBloc.currentUtilityBillSetupSnapshot,
        builder: (BuildContext context,
            AsyncSnapshot<List<UtilityBillSetup>> snapshot) {
          if (snapshot.hasData) {
            return ResponsiveGridList(
              scroll: true,
              desiredItemWidth: ScreenUtil().screenWidth / 4,
              children: snapshot.data!
                  .map((e) => _buildSetupItem(e, context))
                  .toList(),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSetupItem(
      UtilityBillSetup utilityBillSetup, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Tooltip(
        message: (utilityBillSetup.uBDESC ?? '').trim(),
        child: ElevatedButton(
          onPressed: () async {
            EasyLoading.show(status: 'please_wait'.tr());
            final res = await UtilityBillSetupController()
                .getUtilityUi(utilityBillSetup.uBTYPE ?? '');
            EasyLoading.dismiss();
            if ((res?.utilityUi ?? []).length > 0) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UtilityBillView(
                        utilityUiList: res!.utilityUi!,
                        utilityBillSetup: utilityBillSetup),
                  ));
            }
          },
          child: Text((utilityBillSetup.uBDESC ?? '').trim(),
              textAlign: TextAlign.center, maxLines: 1),
        ),
      ),
    );
  }

  Container specialFuctionElementTitle(text) {
    return Container(
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              SizedBox(
                width: 20.r,
              ),
              GoBackIconButton(),
              Spacer(),
              Text(
                text,
                style: CurrentTheme.headline6!
                    .copyWith(color: CurrentTheme.primaryColor),
                textAlign: TextAlign.center,
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
