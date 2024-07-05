/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Dinuka Kulathunga
 * Created At: 12/09/22, 10:06 AM
 */
import 'package:checkout/bloc/utility_bill_setup_bloc.dart';
import 'package:checkout/bloc/utility_bill_sub_category_bloc.dart';
import 'package:checkout/models/utility_bill/utility_bill_sub_category.dart';
import 'package:checkout/views/pos_functions/utility_bill/utility_bill_list_view.dart';
import 'package:flutter/material.dart';
import 'package:responsive_grid/responsive_grid.dart';
import '../../../components/current_theme.dart';
import '../../../components/widgets/go_back.dart';
import '../../../components/widgets/pos_app_bar.dart';
import '../../../components/widgets/pos_background.dart';
import '../../../models/pos_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

class UtilityBillSubcategoryView extends StatelessWidget {
  static const String routeName =
      'special_functions.utility_bill_subcategories';

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
                        "special_functions.utility_bill_subcategories".tr()),
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
        stream:
            utilityBillSubCategoryBloc.currentUtilityBillSubcategorySnapshot,
        builder: (BuildContext context,
            AsyncSnapshot<List<UtilityBillSubcategory>> snapshot) {
          if (snapshot.hasData) {
            return ResponsiveGridList(
              scroll: true,
              desiredItemWidth: ScreenUtil().screenWidth / 4,
              children: snapshot.data!
                  .map((e) => _buildSetupItem(e, context))
                  .toList(),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSetupItem(
      UtilityBillSubcategory utilityBillSubcategory, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Tooltip(
        message: (utilityBillSubcategory.ubSCName ?? '').trim(),
        child: ElevatedButton(
          onPressed: () async {
            await utilityBillSetupBloc.getUtilityBillSetupBySubId(
                utilityBillSubcategory.ubSCode ?? '');
            if (utilityBillSetupBloc.currentUtilityBillSetup != null &&
                utilityBillSetupBloc.currentUtilityBillSetup!.isNotEmpty) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UtilityBillListView(),
                  ));
            }
          },
          child: Text((utilityBillSubcategory.ubSCName ?? '').trim(),
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
              const Spacer(),
              Text(
                text,
                style: CurrentTheme.headline6!
                    .copyWith(color: CurrentTheme.primaryColor),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
