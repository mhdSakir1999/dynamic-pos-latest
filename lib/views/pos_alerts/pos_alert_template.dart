/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/22/21, 5:33 PM
 */
import 'package:checkout/components/components.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supercharged/supercharged.dart';

/// This class is a template class for notifications
/// you need to pass the notification list<string>, title and icon and the
/// left and right action buttons(if the callback is null this screen will not
/// show the button)
class POSAlertTemplate extends StatelessWidget {
  final List<String>? notifications;
  final List<Widget>? widgets;
  final String? leftButtonText;
  final String? rightButtonText;
  final VoidCallback? leftButtonPressed;
  final IconData icon;
  final String title;
  final String? body;
  final VoidCallback? rightButtonPressed;
  final TextStyle? style;
  final bool expNotification;
  final bool expNotificationSpacer;
  final String? textFeild1;
  final String? textFeild2;
  final String? textFeild3;
  final TextEditingController? textEditingController1;
  final TextEditingController? textEditingController2;
  final TextEditingController? textEditingController3;
  final bool? obscure1;
  final bool? obscure2;
  final bool? obscure3;
  final bool showAppBar;
  final FocusNode text2FocusNode = FocusNode();
  final FocusNode text3FocusNode = FocusNode();
  final FocusNode buttonLeftFocusNode = FocusNode();
  final FocusNode buttonRightFocusNode = FocusNode();
  final bool hideTextField1;
  final bool hideTextField2;
  final bool hideTextField3;
  final Color? firstColor;

  POSAlertTemplate(
      {Key? key,
      this.notifications,
      this.leftButtonText,
      this.body,
      this.showAppBar = true,
      this.style,
      this.firstColor,
      this.rightButtonText,
      this.leftButtonPressed,
      required this.icon,
      required this.title,
      this.rightButtonPressed,
      required this.expNotification,
      this.textFeild1,
      this.textFeild2,
      this.textFeild3,
      this.textEditingController1,
      this.textEditingController2,
      this.textEditingController3,
      this.obscure1,
      this.obscure2,
      this.obscure3,
      this.hideTextField1 = false,
      this.hideTextField2 = false,
      this.hideTextField3 = true,
      this.expNotificationSpacer = true,
      this.widgets})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final containerWidth = POSConfig().containerSize.w;
    return POSBackground(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Container(
          width: containerWidth,
          child: Column(
            children: [
              SizedBox(
                height: POSConfig().topMargin.h,
              ),
              if (showAppBar) POSAppBar(),
              SizedBox(
                height: 8.h,
              ),
              // user card and time
              const Row(
                children: [
                  const Expanded(
                      child: UserCard(
                    welcome: false,
                    text: "",
                    shift: true,
                  )),
                  const POSClock(),
                ],
              ),
              //Title
              if (widgets != null)
                Expanded(
                    child: Scrollbar(
                        // isAlwaysShown: true,
                        thickness: 25,
                        child: SingleChildScrollView(
                            child: Column(
                          children: widgets!,
                        )))),
              body != null
                  ? Container(
                      height: 350.h,
                      margin: EdgeInsets.symmetric(vertical: 25.r),
                      child: Card(
                        color: CurrentTheme.primaryColor,
                        child: Center(
                          child: Text(
                            body!,
                            style: style,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              //Notifications
              notifications == null
                  ? const SizedBox.shrink()
                  : Card(
                      color: CurrentTheme.primaryColor,
                      child: Padding(
                        padding: EdgeInsets.all(25.r),
                        child: Column(
                          children: notifications!.map((e) {
                            int index = notifications!
                                .indexWhere((element) => e == element);
                            String splitter = '"';
                            final list = e.split(splitter);
                            var txtStyle = CurrentTheme.bodyText2!.copyWith(
                                color: index == 0 && firstColor != null
                                    ? firstColor
                                    : CurrentTheme.primaryLightColor);
                            Widget wi = Text(e, style: txtStyle);
                            if (list.length > 2) {
                              wi = RichText(
                                  text: TextSpan(style: txtStyle, children: [
                                TextSpan(text: list[0]),
                                TextSpan(
                                    text: list[1],
                                    style: txtStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.greenAccent)),
                                TextSpan(text: list[2]),
                              ]));
                            }
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: wi,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // child: ListView.builder(
                      //   itemCount:  notifications.length,
                      //   itemBuilder: (context, index) {
                      //     final item = notifications[index];
                      //     return Center(
                      //       child: Text(item,style: CurrentTheme.bodyText1!.copyWith(
                      //         color: CurrentTheme.primaryDarkColor
                      //       ),),
                      //     );
                      //   },
                      // ),
                    ),
              expNotification
                  ? Center(
                      child: Container(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 15.h,
                            ),
                            if (!hideTextField1)
                              TextField(
                                textAlign: TextAlign.center,
                                obscureText: obscure1 ?? false,
                                autofocus: true,
                                controller: textEditingController1,
                                decoration: InputDecoration(
                                  filled: true,
                                  hintText: textFeild1,
                                  alignLabelWithHint: true,
                                ),
                                textInputAction: TextInputAction.next,
                                onEditingComplete: () {
                                  if (hideTextField2)
                                    buttonRightFocusNode.requestFocus();
                                  else
                                    text2FocusNode.requestFocus();
                                },
                                onTap: () {
                                  // KeyBoardController().dismiss();
                                  KeyBoardController().showBottomDPKeyBoard(
                                      textEditingController1!,
                                      obscureText: obscure1, onEnter: () {
                                    KeyBoardController().dismiss();
                                  }, buildContext: context);
                                },
                              ),
                            SizedBox(
                              height: 15.h,
                            ),
                            hideTextField2
                                ? const SizedBox.shrink()
                                : TextField(
                                    focusNode: text2FocusNode,
                                    textAlign: TextAlign.center,
                                    controller: textEditingController2,
                                    obscureText: obscure2 ?? false,
                                    decoration: InputDecoration(
                                      filled: true,
                                      hintText: textFeild2,
                                      alignLabelWithHint: true,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    onEditingComplete: () {
                                      if (hideTextField3)
                                        buttonRightFocusNode.requestFocus();
                                      else
                                        text3FocusNode.requestFocus();
                                    },
                                    onTap: () {
                                      // KeyBoardController().dismiss();
                                      KeyBoardController().showBottomDPKeyBoard(
                                          textEditingController2!,
                                          obscureText: obscure2, onEnter: () {
                                        KeyBoardController().dismiss();
                                      }, buildContext: context);
                                    },
                                  ),
                            SizedBox(
                              height: 15.h,
                            ),
                            hideTextField3
                                ? const SizedBox.shrink()
                                : TextField(
                                    focusNode: text3FocusNode,
                                    textAlign: TextAlign.center,
                                    controller: textEditingController3,
                                    obscureText: obscure3 ?? false,
                                    decoration: InputDecoration(
                                      filled: true,
                                      hintText: textFeild3,
                                      alignLabelWithHint: true,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    onEditingComplete: () {
                                      buttonRightFocusNode.requestFocus();
                                    },
                                    onTap: () {
                                      KeyBoardController().dismiss();
                                      KeyBoardController().showBottomDPKeyBoard(
                                          textEditingController3!,
                                          obscureText: obscure3, onEnter: () {
                                        KeyBoardController().dismiss();
                                      }, buildContext: context);
                                    },
                                  ),
                            SizedBox(
                              height: 15.h,
                            ),
                          ],
                        ),
                      ),
                    )
                  : expNotificationSpacer
                      ? const Spacer()
                      : const SizedBox.shrink(),
              Row(
                children: [
                  Expanded(
                      child: appButton(leftButtonPressed, leftButtonText,
                          buttonLeftFocusNode)),
                  SizedBox(
                    width: 15.w,
                  ),
                  Expanded(
                      child: appButton(rightButtonPressed, rightButtonText,
                          buttonRightFocusNode)),
                ],
              ),
              SizedBox(
                height: POSConfig().topMargin.h,
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget appButton(VoidCallback? onPressed, String? text, FocusNode focusNode) {
    if (onPressed != null && text != null)
      return Container(
        height: 95.h,
        child: ElevatedButton(
          focusNode: focusNode,
          onPressed: onPressed,
          child: RichText(
              text: TextSpan(text: "", children: [
            TextSpan(
              text: text.substring(0, 1),
              style: TextStyle(
                decoration: TextDecoration
                    .underline, // Apply underline to the first letter
              ),
            ),
            TextSpan(
              text: text.substring(1),
            ),
          ])),
          //     Text(
          //   text,
          //   textAlign: TextAlign.center,
          // ),
          style: ElevatedButton.styleFrom(
              textStyle: CurrentTheme.bodyText2,
              backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
        ),
      );
    else {
      return const SizedBox.shrink();
    }
  }
}
