/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/29/21, 4:13 PM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/config/shared_preference_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/main.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:checkout/extension/extensions.dart';

import '../../controllers/keyboard_controller.dart';

class SettingView extends StatefulWidget {
  @override
  _SettingViewState createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  final style1 = CurrentTheme.bodyText2!.copyWith(
    color: CurrentTheme.primaryLightColor,
    fontWeight: FontWeight.w700,
  );
  final style2 = CurrentTheme.subtitle2!.copyWith(
      color: CurrentTheme.primaryLightColor, fontWeight: FontWeight.w500);

  TextEditingController topLeftBorderValue =
      TextEditingController(text: "${POSConfig().rounderBorderRadiusTopLeft}");
  TextEditingController topRightBorderValue =
      TextEditingController(text: "${POSConfig().rounderBorderRadiusTopRight}");
  TextEditingController bottomLeftBorderValue = TextEditingController(
      text: "${POSConfig().rounderBorderRadiusBottomLeft}");
  TextEditingController bottomRightBorderValue = TextEditingController(
      text: "${POSConfig().rounderBorderRadiusBottomRight}");
  TextEditingController roundedBorderRadius =
      TextEditingController(text: "${POSConfig().rounderBorderRadius2}");
  TextEditingController topAppBarHeight =
      TextEditingController(text: "${POSConfig().topAppBarSize}");
  TextEditingController containerSize =
      TextEditingController(text: "${POSConfig().containerSize}");

  //cart
  TextEditingController cardId =
      TextEditingController(text: "${POSConfig().cardIdLength}");
  TextEditingController cardName =
      TextEditingController(text: "${POSConfig().cardNameLength}");
  TextEditingController cardPrice =
      TextEditingController(text: "${POSConfig().cardPriceLength}");
  TextEditingController cardQty =
      TextEditingController(text: "${POSConfig().cardQtyLength}");
  TextEditingController cardTotalPrice =
      TextEditingController(text: "${POSConfig().cardTotalLength}");
  TextEditingController cartButtonWidth =
      TextEditingController(text: "${POSConfig().cartDynamicButtonWidth}");
  TextEditingController cartButtonHeight =
      TextEditingController(text: "${POSConfig().cartDynamicButtonHeight}");
  TextEditingController cartSpaceBetween =
      TextEditingController(text: "${POSConfig().cartDynamicButtonPadding}");
  TextEditingController cartButtonFontSize =
      TextEditingController(text: "${POSConfig().cartDynamicButtonFontSize}");
  TextEditingController cardFontSize =
      TextEditingController(text: "${POSConfig().cardFontSize}");

  TextEditingController paymentButtonWidth =
      TextEditingController(text: "${POSConfig().paymentDynamicButtonWidth}");
  TextEditingController paymentButtonHeight =
      TextEditingController(text: "${POSConfig().paymentDynamicButtonHeight}");
  TextEditingController paymentSpaceBetween =
      TextEditingController(text: "${POSConfig().paymentDynamicButtonPadding}");
  TextEditingController paymentButtonFontSize = TextEditingController(
      text: "${POSConfig().paymentDynamicButtonFontSize}");
  TextEditingController paymentFontSize = TextEditingController(
      text: "${POSConfig().paymentDynamicButtonFontSize}");
  TextEditingController dataTableFontSize =
      TextEditingController(text: "${POSConfig().checkoutDataTableFontSize}");

  TextEditingController loyaltyServer =
      TextEditingController(text: "${POSConfig().loyaltyServerCentral}");
  TextEditingController loyaltyServerImage =
      TextEditingController(text: "${POSConfig().loyaltyServerImage}");
  TextEditingController posServer =
      TextEditingController(text: "${POSConfig().server}");
  TextEditingController posServerLocal =
      TextEditingController(text: "${POSConfig().local}");
  TextEditingController posServerImage =
      TextEditingController(text: "${POSConfig().posImageServer}");
  TextEditingController terminalID =
      TextEditingController(text: "${POSConfig().terminalId}");
  TextEditingController locCode =
      TextEditingController(text: "${POSConfig().locCode}");

  Color primaryColor = POSConfig().primaryColor.toColor;
  Color primaryColorDark = POSConfig().primaryDarkColor.toColor;
  Color primaryColorLight = POSConfig().primaryLightColor.toColor;
  Color primaryColorGrey = POSConfig().primaryDarkGrayColor.toColor;
  Color backgroundColor = POSConfig().backgroundColor.toColor;
  Color? tempColor;
  bool touchKeyBoard = POSConfig().touchKeyboardEnabled;
  bool lhsMode = POSConfig().defaultCheckoutLSH;
  bool tableView = POSConfig().checkoutTableView;
  bool cartBatchItem = POSConfig().cartBatchItem;
  bool reportBasedInvoice = POSConfig().reportBasedInvoice;
  bool ecr = POSConfig().ecr;
  bool isTraining = POSConfig().trainingMode;
  bool auto_cust_popup = POSConfig().auto_cust_popup;
  bool disablePromotions = POSConfig().disablePromotions;
  bool disableCartImageLoad = POSConfig().disableCartImageLoad;
  bool saveInvoiceLocal = POSConfig().saveInvoiceLocal;
  final passwordController = TextEditingController();

  //keyboard colors
  Color posKeyBoardBackgroundColor =
      POSConfig().posKeyBoardBackgroundColor.toColor;
  Color posKeyBoardGradient1 = POSConfig().posKeyBoardGradient1.toColor;
  Color posKeyBoardGradient2 = POSConfig().posKeyBoardGradient2.toColor;
  Color posKeyBoardGradient3 = POSConfig().posKeyBoardGradient3.toColor;
  Color posKeyBoardBorderColor = POSConfig().posKeyBoardBorderColor.toColor;
  Color posKeyBoardEnterColor = POSConfig().posKeyBoardEnterColor.toColor;
  Color posKeyBoardEnterTxtColor = POSConfig().posKeyBoardEnterTxtColor.toColor;
  Color posKeyBoardVoidColor = POSConfig().posKeyBoardVoidColor.toColor;
  Color posKeyBoardVoidTxtColor = POSConfig().posKeyBoardVoidTxtColor.toColor;
  Color posKeyBoardExactColor = POSConfig().posKeyBoardExactColor.toColor;
  Color posKeyBoardExactTxtColor = POSConfig().posKeyBoardExactTxtColor.toColor;
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return POSBackground(
        child: Scaffold(
      body: buildBody(),
    ));
  }

  Widget buildBody() {
    return Center(
      child: Container(
        width: POSConfig().containerSize,
        child: Scrollbar(
          controller: scrollController,
          thickness: 25,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: scrollController,
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                // POSAppBar(),
                buildPOSKeyboardSettings(),
                buildItemCard("settings.pos_settings".tr(), buildPosSettings()),
                buildItemCard(
                    "settings.touch_keyboard".tr(),
                    buildSwitch(
                        title: touchKeyBoard
                            ? "settings.enabled".tr()
                            : "settings.disabled".tr(),
                        value: touchKeyBoard,
                        onChanged: (bool val) {
                          setState(() {
                            touchKeyBoard = val;
                          });
                        })),
                buildPOSColor(),
                buildItemCard(
                    "settings.rounded_square_button".tr(), buildSquareButton()),
                buildItemCard(
                  "settings.rounded_border_radius".tr(),
                  cardItemWithSlider(
                      "settings.border_radius_all".tr(), roundedBorderRadius),
                ),
                buildItemCard("settings.components".tr(), buildComponent()),
                buildItemCard("settings.cart".tr(), buildCardConfig()),
                buildItemCard(
                    "settings.cart_display_mode".tr(), cartOtherConfig()),
                buildItemCard("settings.cart_dynamic_button_settings".tr(),
                    buildCartButtonConfig()),
                buildItemCard("settings.payment_settings".tr(),
                    buildCartPaymentButtonConfig()),
                // buildItemCard(
                //   'Training Mode',
                //   buildSwitch(
                //       title: 'Training Mode',
                //       value: isTraining,
                //       onChanged: (bool val) {
                //         setState(() {
                //           isTraining = val;
                //         });
                //       }),
                // ),
                buildItemCard('Functional Settings', buildFunctionalSettings()),
                const SizedBox(
                  height: 5,
                ),
                buildButtonSet(),
                const SizedBox(
                  height: 40,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget cartOtherConfig() {
    return Column(
      children: [
        buildSwitch(
            title: "settings.lhs".tr(),
            value: lhsMode,
            onChanged: (bool val) {
              setState(() {
                lhsMode = val;
              });
            }),
        buildSwitch(
            title: "settings.cart_batch".tr(),
            value: cartBatchItem,
            onChanged: (bool val) {
              setState(() {
                cartBatchItem = val;
              });
            }),
        // buildSwitch(
        //     title: "settings.table_view".tr(),
        //     value: tableView,
        //     onChanged: (bool val) {
        //       setState(() {
        //         tableView = val;
        //       });
        //     }),
        cardItemWithSlider(
            "settings.checkout_data_table_font_size".tr(), dataTableFontSize,
            max: 30, min: 8),
      ],
    );
  }

  Widget buildFunctionalSettings() {
    return Container(
      child: Column(
        children: [
          buildSwitch(
              title: 'Disable Promotions',
              value: disablePromotions,
              onChanged: (bool val) {
                setState(() {
                  disablePromotions = val;
                });
              }),
          buildSwitch(
              title: 'Automatic Customer Popup',
              value: auto_cust_popup,
              onChanged: (bool val) {
                setState(() {
                  auto_cust_popup = val;
                });
              }),
          buildSwitch(
              title: 'Disable Product Images (Invoice Page)',
              value: disableCartImageLoad,
              onChanged: (bool val) {
                setState(() {
                  disableCartImageLoad = val;
                });
              }),
          buildSwitch(
              title: 'Save Invoices Locally',
              value: saveInvoiceLocal,
              onChanged: (bool val) {
                setState(() {
                  saveInvoiceLocal = val;
                });
              }),
        ],
      ),
    );
  }

  Widget buildCardConfig() {
    return Container(
      child: Column(
        children: [
          cardItemWithSlider("settings.card_id".tr(), cardId,
              max: 200, min: 100),
          cardItemWithSlider("settings.card_name".tr(), cardName,
              max: 300, min: 0),
          cardItemWithSlider("settings.card_price".tr(), cardPrice,
              max: 200, min: 100),
          cardItemWithSlider("settings.card_qty".tr(), cardQty,
              max: 200, min: 50),
          cardItemWithSlider("settings.card_total_price".tr(), cardTotalPrice,
              max: 200, min: 50),
          cardItemWithSlider("settings.font_size".tr(), cardFontSize,
              max: 30, min: 10),
        ],
      ),
    );
  }

  Widget buildCartButtonConfig() {
    return Container(
      child: Column(
        children: [
          cardItemWithSlider("settings.button_width".tr(), cartButtonWidth,
              max: 200, min: 50),
          cardItemWithSlider("settings.button_height".tr(), cartButtonHeight,
              max: 150, min: 50),
          cardItemWithSlider(
              "settings.space_between_buttons".tr(), cartSpaceBetween,
              max: 25, min: 0),
          cardItemWithSlider("settings.font_size".tr(), cartButtonFontSize,
              max: 30, min: 8),
        ],
      ),
    );
  }

  Widget buildCartPaymentButtonConfig() {
    return Container(
      child: Column(
        children: [
          cardItemWithSlider("settings.button_width".tr(), paymentButtonWidth,
              max: 300, min: 50),
          cardItemWithSlider("settings.button_height".tr(), paymentButtonHeight,
              max: 150, min: 50),
          cardItemWithSlider(
              "settings.space_between_buttons".tr(), paymentSpaceBetween,
              max: 25, min: 0),
          cardItemWithSlider("settings.font_size".tr(), paymentButtonFontSize,
              max: 30, min: 8),
        ],
      ),
    );
  }

  Widget buildSwitch({required String title, required bool value, onChanged}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            // width: 130.w,
            child: Text(
              title,
              style: style2,
            ),
          ),
        ),
        const Spacer(),
        Switch(
            activeColor: Colors.redAccent, value: value, onChanged: onChanged)
      ],
    );
  }

  //pos keyboard settings
  Widget buildPOSKeyboardSettings() {
    return buildItemCard(
        "settings.pos_keyboard_settings".tr(),
        Column(
          children: [
            posColorItem("settings.pos_keyboard_background".tr(),
                posKeyBoardBackgroundColor, () async {
              final res = await colorPickerDialog(posKeyBoardBackgroundColor);
              if (res)
                setState(() {
                  posKeyBoardBackgroundColor = tempColor!;
                });
            }),
            posColorItem(
                "settings.pos_keyboard_gradient1".tr(), posKeyBoardGradient1,
                () async {
              final res = await colorPickerDialog(posKeyBoardGradient1);
              if (res)
                setState(() {
                  posKeyBoardGradient1 = tempColor!;
                });
            }),
            posColorItem(
                "settings.pos_keyboard_gradient2".tr(), posKeyBoardGradient2,
                () async {
              final res = await colorPickerDialog(posKeyBoardGradient2);
              if (res)
                setState(() {
                  posKeyBoardGradient2 = tempColor!;
                });
            }),
            posColorItem(
                "settings.pos_keyboard_gradient3".tr(), posKeyBoardGradient3,
                () async {
              final res = await colorPickerDialog(posKeyBoardGradient3);
              if (res)
                setState(() {
                  posKeyBoardGradient3 = tempColor!;
                });
            }),
            posColorItem(
                "settings.pos_keyboard_border".tr(), posKeyBoardBorderColor,
                () async {
              final res = await colorPickerDialog(posKeyBoardBorderColor);
              if (res)
                setState(() {
                  posKeyBoardBorderColor = tempColor!;
                });
            }),
            posColorItem(
                "settings.pos_keyboard_enter".tr(), posKeyBoardEnterColor,
                () async {
              final res = await colorPickerDialog(posKeyBoardEnterColor);
              if (res)
                setState(() {
                  posKeyBoardEnterColor = tempColor!;
                });
            }),
            posColorItem("settings.pos_keyboard_enter_txt".tr(),
                posKeyBoardEnterTxtColor, () async {
              final res = await colorPickerDialog(posKeyBoardEnterTxtColor);
              if (res)
                setState(() {
                  posKeyBoardEnterTxtColor = tempColor!;
                });
            }),
            posColorItem(
                "settings.pos_keyboard_void".tr(), posKeyBoardVoidColor,
                () async {
              final res = await colorPickerDialog(posKeyBoardVoidColor);
              if (res)
                setState(() {
                  posKeyBoardVoidColor = tempColor!;
                });
            }),
            posColorItem(
                "settings.pos_keyboard_void_txt".tr(), posKeyBoardVoidTxtColor,
                () async {
              final res = await colorPickerDialog(posKeyBoardVoidTxtColor);
              if (res)
                setState(() {
                  posKeyBoardVoidTxtColor = tempColor!;
                });
            }),
            posColorItem(
                "settings.pos_keyboard_exact".tr(), posKeyBoardExactColor,
                () async {
              final res = await colorPickerDialog(posKeyBoardExactColor);
              if (res)
                setState(() {
                  posKeyBoardExactColor = tempColor!;
                });
            }),
            posColorItem("settings.pos_keyboard_exact_txt".tr(),
                posKeyBoardExactTxtColor, () async {
              final res = await colorPickerDialog(posKeyBoardExactTxtColor);
              if (res)
                setState(() {
                  posKeyBoardExactTxtColor = tempColor!;
                });
            }),
          ],
        ));
  }

  //
  Widget buildPOSColor() {
    return buildItemCard(
        "settings.pos_colors".tr(),
        Column(
          children: [
            posColorItem("settings.primary_color".tr(), primaryColor, () async {
              final res = await colorPickerDialog(primaryColor);
              if (res)
                setState(() {
                  primaryColor = tempColor!;
                });
            }),
            posColorItem("settings.primary_dark_color".tr(), primaryColorDark,
                () async {
              final res = await colorPickerDialog(primaryColorDark);
              if (res)
                setState(() {
                  primaryColorDark = tempColor!;
                });
            }),
            posColorItem("settings.primary_light_color".tr(), primaryColorLight,
                () async {
              final res = await colorPickerDialog(primaryColorLight);
              if (res)
                setState(() {
                  primaryColorLight = tempColor!;
                });
            }),
            posColorItem("settings.primary_grey_color".tr(), primaryColorGrey,
                () async {
              final res = await colorPickerDialog(primaryColorGrey);
              if (res)
                setState(() {
                  primaryColorGrey = tempColor!;
                });
            }),
            posColorItem("settings.background_color".tr(), backgroundColor,
                () async {
              final res = await colorPickerDialog(backgroundColor);
              if (res)
                setState(() {
                  backgroundColor = tempColor!;
                });
            }),
            //
          ],
        ));
  }

  Widget posColorItem(String title, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 130.w,
            child: Text(
              title,
              style: style2,
            ),
          ),
          const Spacer(),
          Material(
            elevation: 10,
            child: InkWell(
              onTap: onTap,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(2),
                child: AnimatedContainer(
                  color: color,
                  duration: Duration(milliseconds: 500),
                  width: 60.w,
                  height: 40.h,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<bool> colorPickerDialog(Color color) async {
    return ColorPicker(
      // Use the dialogPickerColor as start color.
      color: color,
      // Update the dialogPickerColor using the callback.
      onColorChanged: (Color color) => setState(() => tempColor = color),
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        'Select color',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subheading: Text(
        'Select color shade',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      wheelSubheading: Text(
        'Selected color and its shades',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
    ).showPickerDialog(
      context,
      constraints:
          const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
    );
  }

  // This method builds the components
  Widget buildComponent() {
    return Column(
      children: [
        cardItemWithSlider("settings.toolbar_size".tr(), topAppBarHeight,
            min: 50, max: 100),
        cardItemWithSlider("settings.container_size".tr(), containerSize,
            min: ScreenUtil().screenWidth * 0.25,
            max: ScreenUtil().screenWidth),
      ],
    );
  }

  // This method builds the square buttons
  Widget buildSquareButton() {
    return Column(
      children: [
        cardItemWithSlider("settings.top_left".tr(), topLeftBorderValue),
        cardItemWithSlider("settings.top_right".tr(), topRightBorderValue),
        cardItemWithSlider("settings.bottom_left".tr(), bottomLeftBorderValue),
        cardItemWithSlider(
            "settings.bottom_right".tr(), bottomRightBorderValue),
      ],
    );
  }

  Widget cardItemWithSlider(String title, TextEditingController controller,
      {double min = 0, double max = 30}) {
    final width = 80.w;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 130.w,
            child: Text(
              title,
              style: style2,
            ),
          ),
          Expanded(child: appSlider(controller, max: max, min: min)),
          Container(
            width: width,
            child: textField(controller, max: max, min: min),
          )
        ],
      ),
    );
  }

  //This is the app slider
  Widget appSlider(TextEditingController editingController,
      {double min = 0, double max = 30}) {
    return Slider(
      value: editingController.text.parseDouble(),
      min: min,
      max: max,
      label: "${editingController.text}",
      divisions: max.toInt(),
      onChanged: (value) {
        setState(() {
          editingController.text = value.toString();
        });
      },
    );
  }

  //This is the text field used in cardWithSlider method
  Widget textField(TextEditingController controller,
      {double min = 0, double max = 30}) {
    return TextField(
      textAlign: TextAlign.center,
      onTap: () {
        if (mounted)
          setState(() {
            KeyBoardController().showBottomDPKeyBoard(
              controller,
            );
          });
      },
      onChanged: (value) {
        if (value.isNotEmpty) setState(() {});
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CustomRangeTextInputFormatter(min, max),
      ],
      decoration: InputDecoration(
        filled: true,
      ),
      style: TextStyle(color: CurrentTheme.primaryColor),
      controller: controller,
    );
  }

  //This is the card of the items
  Widget buildItemCard(String title, Widget child) {
    return Card(
      color: CurrentTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: ListTile(
          title: Text(
            title,
            style: style1,
          ),
          subtitle: child,
        ),
      ),
    );
  }

  // This is the bottom button set
  Widget buildButtonSet() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          // Expanded(child: appButton(() {}, "settings.cancel".tr())),
          // SizedBox(
          //   width: 15.r,
          // ),
          Expanded(child: appButton(() => save(), "settings.save".tr())),
        ],
      ),
    );
  }

  //This is the single button
  Widget appButton(VoidCallback onPressed, String text) {
    return Container(
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
            textStyle: CurrentTheme.bodyText2,
            backgroundColor: POSConfig().primaryDarkGrayColor.toColor),
      ),
    );
  }

  Widget buildPosSettings() {
    return Container(
      child: Column(
        children: [
          displayOnlyTile("settings.com_name".tr(), POSConfig().comName),
          displayOnlyTile(
              "settings.setup_location".tr(), POSConfig().setupLocation),
          displayOnlyTile(
              "settings.location".tr(), POSConfig().setupLocationName),
          displayOnlyTile("settings.com_code".tr(), POSConfig().comCode),
          customListTile(controller: locCode, title: "settings.loc_code".tr()),
          customListTile(
              controller: terminalID, title: "settings.terminal_id".tr()),
          // customListTile(controller: posServer, title: "settings.server".tr()),
          // customListTile(
          //     controller: posServerLocal, title: "settings.local_server".tr()),
          // customListTile(
          //     controller: posServerImage,
          //     title: "settings.pos_image_server".tr()),
          // customListTile(
          //     controller: loyaltyServer, title: "settings.loyalty_server".tr()),
          // customListTile(
          //     controller: loyaltyServerLocal,
          //     title: "settings.loyalty_local_server".tr()),
          // customListTile(
          //     controller: loyaltyServerImage,
          //     title: "settings.loyalty_image_server".tr()),
          // buildSwitch(
          //     title: "settings.report_based_invoice".tr(),
          //     value: reportBasedInvoice,
          //     onChanged: (bool val) {
          //       setState(() {
          //         reportBasedInvoice = val;
          //       });
          //     }),
          buildSwitch(
              title: "settings.ecr".tr(),
              value: ecr,
              onChanged: (bool val) {
                setState(() {
                  ecr = val;
                });
              }),
        ],
      ),
    );
  }

  Widget displayOnlyTile(String title, String subtitle) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
            color: POSConfig().primaryLightColor.toColor,
            fontSize: 20.sp,
            fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
            color: POSConfig().primaryLightColor.toColor, fontSize: 18.sp),
      ),
    );
  }

  Widget customListTile(
      {required TextEditingController controller, required String title}) {
    final border = InputBorder.none;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
            color: POSConfig().primaryLightColor.toColor,
            fontSize: 20.sp,
            fontWeight: FontWeight.w500),
      ),
      subtitle: TextField(
        controller: controller,
        onTap: () {
          if (mounted)
            setState(() {
              KeyBoardController().dismiss();
              KeyBoardController().showBottomDPKeyBoard(controller,
                  onEnter: () => KeyBoardController().dismiss());
            });
        },
        cursorColor: Colors.white,
        style: TextStyle(
            color: POSConfig().primaryLightColor.toColor, fontSize: 18.sp),
        decoration: InputDecoration(
            border: border,
            enabledBorder: border,
            errorBorder: border,
            disabledBorder: border,
            focusedBorder: border,
            focusedErrorBorder: border),
      ),
    );
  }

  void save() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Text(
              "settings.are_you_sure".tr(),
              textAlign: TextAlign.center,
            ),
            content: Container(
                width: ScreenUtil().screenWidth * 0.25,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 200.h,
                      child: const FlareActor(
                        "assets/flare/waring.flr",
                        animation: "animate",
                      ),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    TextField(
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      controller: passwordController,
                      obscureText: true,
                      onTap: () {
                        KeyBoardController().dismiss();
                        KeyBoardController().showBottomDPKeyBoard(
                            passwordController, onEnter: () {
                          KeyBoardController().dismiss();
                          _passwordValidation();
                        }, obscureText: true, buildContext: context);
                      },
                      decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                              color: POSConfig().primaryDarkColor.toColor)),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Text("settings.warning".tr()),
                    SizedBox(
                      height: 20.h,
                    ),
                  ],
                )),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: POSConfig().primaryDarkGrayColor.toColor),
                onPressed: () {
                  _passwordValidation();
                },
                child: Text(
                  "settings.yes".tr(),
                  style: Theme.of(context).dialogTheme.contentTextStyle,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: POSConfig().primaryDarkGrayColor.toColor),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "settings.no".tr(),
                  style: Theme.of(context).dialogTheme.contentTextStyle,
                ),
              ),
            ]);
      },
    );
  }

  Future<void> _passwordValidation() async {
    Navigator.pop(context);
    final res = POSConfig().password == passwordController.text;
    if (res)
      saveConfig();
    else {
      showDialog(
        context: context,
        builder: (context) {
          return POSErrorAlert(
              title: "invalid_password_error.title".tr(),
              subtitle: "invalid_password_error.subtitle".tr(),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          POSConfig().primaryDarkGrayColor.toColor),
                  onPressed: () {
                    Navigator.pop(context);
                    save();
                  },
                  child: Text(
                    "invalid_password_error.okay".tr(),
                    style: Theme.of(context).dialogTheme.contentTextStyle,
                  ),
                ),
              ]);
        },
      );
    }
  }

  void saveConfig() async {
    POSConfig posConfig = POSConfig()
      ..rounderBorderRadiusBottomRight =
          bottomRightBorderValue.text.parseDouble()
      ..rounderBorderRadiusBottomLeft = bottomLeftBorderValue.text.parseDouble()
      ..rounderBorderRadiusTopRight = topRightBorderValue.text.parseDouble()
      ..rounderBorderRadiusTopLeft = topLeftBorderValue.text.parseDouble()
      ..rounderBorderRadius2 = roundedBorderRadius.text.parseDouble()
      ..topAppBarSize = topAppBarHeight.text.parseDouble()
      ..containerSize = containerSize.text.parseDouble()
      ..cardIdLength = cardId.text.parseDouble()
      ..cardNameLength = cardName.text.parseDouble()
      ..cardPriceLength = cardPrice.text.parseDouble()
      ..cardTotalLength = cardTotalPrice.text.parseDouble()
      ..cardQtyLength = cardQty.text.parseDouble()
      ..cardFontSize = cardFontSize.text.parseDouble()
      ..cartDynamicButtonHeight = cartButtonHeight.text.parseDouble()
      ..cartDynamicButtonWidth = cartButtonWidth.text.parseDouble()
      ..cartDynamicButtonFontSize = cartButtonFontSize.text.parseDouble()
      ..cartDynamicButtonPadding = cartSpaceBetween.text.parseDouble()
      ..paymentDynamicButtonHeight = paymentButtonHeight.text.parseDouble()
      ..paymentDynamicButtonWidth = paymentButtonWidth.text.parseDouble()
      ..paymentDynamicButtonFontSize = paymentButtonFontSize.text.parseDouble()
      ..paymentDynamicButtonPadding = paymentSpaceBetween.text.parseDouble()
      ..primaryColor = primaryColor.hex
      ..backgroundColor = backgroundColor.hex
      ..primaryDarkColor = primaryColorDark.hex
      ..primaryLightColor = primaryColorLight.hex
      ..primaryDarkGrayColor = primaryColorGrey.hex
      ..touchKeyboardEnabled = touchKeyBoard
      ..defaultCheckoutLSH = lhsMode
      ..checkoutTableView = tableView
      ..cartBatchItem = cartBatchItem
      ..terminalId = terminalID.text
      ..server = posServer.text
      ..local = posServerLocal.text
      ..posImageServer = posServerImage.text
      ..loyaltyServerCentral = loyaltyServer.text
      ..loyaltyServerImage = loyaltyServerImage.text
      ..locCode = locCode.text
      ..checkoutDataTableFontSize = dataTableFontSize.text.parseDouble()
      ..reportBasedInvoice = reportBasedInvoice
      ..posKeyBoardBackgroundColor = posKeyBoardBackgroundColor.hex
      ..posKeyBoardBorderColor = posKeyBoardBorderColor.hex
      ..posKeyBoardGradient1 = posKeyBoardGradient1.hex
      ..posKeyBoardGradient2 = posKeyBoardGradient2.hex
      ..posKeyBoardGradient3 = posKeyBoardGradient3.hex
      ..posKeyBoardEnterColor = posKeyBoardEnterColor.hex
      ..posKeyBoardEnterTxtColor = posKeyBoardEnterTxtColor.hex
      ..posKeyBoardVoidColor = posKeyBoardVoidColor.hex
      ..posKeyBoardVoidTxtColor = posKeyBoardVoidTxtColor.hex
      ..posKeyBoardExactColor = posKeyBoardExactColor.hex
      ..posKeyBoardExactTxtColor = posKeyBoardExactTxtColor.hex
      ..trainingMode = isTraining
      ..auto_cust_popup = auto_cust_popup
      ..disablePromotions = disablePromotions
      ..disableCartImageLoad = disableCartImageLoad
      ..saveInvoiceLocal = saveInvoiceLocal;

    SharedPreferenceController controller = SharedPreferenceController();
    await controller.saveConfig(posConfig);
    RestartWidget.restartApp(context);
  }
}
