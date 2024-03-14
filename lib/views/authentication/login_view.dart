/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/21/21, 10:50 AM
 */

import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/bloc/notification_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/mypos_screen_utils.dart';
import 'package:checkout/components/pos_platform.dart';
import 'package:checkout/components/widgets/commonUse.dart';
import 'package:checkout/controllers/activation/activation_controller.dart';
import 'package:checkout/controllers/auth_controller.dart';
import 'package:checkout/controllers/dual_screen_controller.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/otp_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/enum/pos_connectivity_status.dart';
import 'package:checkout/models/enum/signon_status.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/authentication/password_change_view.dart';
import 'package:checkout/views/landing/landing.dart';
import 'package:checkout/views/settings/settings_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../controllers/sms_controller.dart';
import '../../models/promotion_model.dart';

/// This is the login screen of the application
class LoginView extends StatefulWidget {
  static const routeName = "login";

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController usernameEditingController =
      TextEditingController();
  final TextEditingController passwordEditingController =
      TextEditingController();
  final TextEditingController otpEditingController = TextEditingController();
  String _otpCode = '-1';
  bool canShowPasswordField = false;
  bool capsLockWarning = false;
  String? currentError;
  final authController = AuthController();
  final passwordFocusNode = FocusNode();
  final userNameFocusNode = FocusNode();
  bool obscureText = true;
  List<Promotion>? promotionList;

  @override
  void initState() {
    super.initState();
    //notificationBloc.getAnnouncements();
    customerBloc.changeCurrentCustomer(null, update: false);
    if (!kReleaseMode) {
      // usernameEditingController.text = 'MYPOS';
      passwordEditingController.text = 'ADMIN';
      usernameEditingController.text = 'CAS1';
      // passwordEditingController.text = 'myPOS@1234';
    }
    //DesktopWindow.setFullScreen(true);
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
        showConnection: false,
        child: Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              getScreenSize() == ScreenSize.md
                  ? SizedBox.shrink()
                  : SizedBox(
                      height: double.infinity,
                      width: ScreenUtil().screenWidth * 0.7,
                      child: POSConfig().backgroundImage.isEmpty
                          ? buildDefaultImage()
                          : CachedNetworkImage(
                              imageUrl: POSConfig().backgroundImage,
                              // errorWidget: (context,_,s)=>buildDefaultImage(),
                              fit: BoxFit.cover),
                    ),
              Expanded(
                child: Stack(
                  children: [
                    StreamBuilder<POSConnectivityStatus>(
                        stream: posConnectivity.connectivityStream.stream,
                        builder: (BuildContext context,
                            AsyncSnapshot<POSConnectivityStatus> snapshot) {
                          return (snapshot.data == POSConnectivityStatus.Server)
                              ? buildBody()
                              : (snapshot.data == POSConnectivityStatus.Local)
                                  ? buildBody()
                                  : Stack(children: [
                                      Center(
                                        child: SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.03,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.03,
                                          child: LoadingIndicator(
                                              indicatorType:
                                                  Indicator.ballPulse,

                                              /// Required, The loading type of the widget
                                              colors: const [
                                                Colors.white,
                                                Colors.blue,
                                                Colors.white
                                              ],

                                              /// Optional, The color collections
                                              strokeWidth: 1,

                                              /// Optional, The stroke of the line, only applicable to widget which contains line
                                              backgroundColor:
                                                  Colors.transparent,

                                              /// Optional, Background of the widget
                                              pathBackgroundColor:
                                                  Colors.transparent

                                              /// Optional, the stroke backgroundColor
                                              ),
                                        ),
                                      ),
                                      Positioned(
                                          bottom: 0,
                                          right: 0,
                                          left: 0,
                                          child: Center(
                                              child: connectionWidgetData())),
                                    ]);
                        }),
                    // buildBody(),
                    Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                            icon: Icon(Icons.settings),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) {
                                  return SettingView();
                                },
                              );
                            })),
                    Positioned(
                        top: 0,
                        right: 40,
                        child: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () async {
                              try {
                                final result = await Process.run('cmd.exe', [
                                  '/c',
                                  'taskkill /F /IM Dynamic_POS_REST_API.exe'
                                ]);
                                LogWriter().saveLogsToFile(
                                    'ERROR_Log_', ['Closing previous api...']);
                              } catch (e) {
                                await LogWriter().saveLogsToFile('ERROR_Log_', [
                                  'Error Closing previous api: ${e.toString()}'
                                ]);
                                print('Error: $e');
                              }

                              SystemNavigator.pop();

                              if (POSPlatform().isDesktop()) {
                                appWindow.close();
                              } else if (kIsWeb) {
                              } else {
                                SystemNavigator.pop();
                              }
                            })),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Image buildDefaultImage() {
    return Image.asset(
      "assets/images/bg_login.jpg",
      fit: BoxFit.fill,
    );
  }

  Widget buildBody() {
    final buttonSize = 720 * getRadius();
    return POSBackground(
      showConnection: true,
      alignment: Alignment.bottomCenter,
      child: Container(
        alignment: Alignment.topCenter,
        padding: EdgeInsets.symmetric(horizontal: 20.r),
        child: SingleChildScrollView(
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (value) {
              // if (mounted)
              //   setState(() {
              //     capsLockWarning = value.logicalKey.keyId == 0x100070039;
              //   });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 150.h,
                ),
                LogoWithPoweredBy(),
                SizedBox(
                  height: 15.h,
                ),
                Center(
                  child: Text(
                    currentError ?? "",
                    style: CurrentTheme.subtitle2,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 2.5.h,
                ),
                capsLockWarning
                    ? Text(
                        "Caps lock is turned on",
                        style: CurrentTheme.subtitle2
                            ?.copyWith(color: Colors.yellow),
                      )
                    : SizedBox.shrink(),
                SizedBox(
                  height: 5.h,
                ),
                Container(
                  width: buttonSize,
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: usernameEditingController,
                    focusNode: userNameFocusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                        filled: true,
                        hintText: "login_view.user_name_field".tr(),
                        alignLabelWithHint: true,
                        suffixIcon: Icon(
                          MaterialCommunityIcons.eye_off_outline,
                          color: Colors.transparent,
                        )),
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () {
                      validateUserName();
                    },
                    onTap: () {
                      if (mounted)
                        setState(() {
                          currentError = null;
                          if (kReleaseMode) passwordEditingController.clear();
                          canShowPasswordField = false;
                          KeyBoardController().dismiss();
                        });
                      KeyBoardController().showBottomDPKeyBoard(
                          usernameEditingController,
                          onEnter: validateUserName,
                          buildContext: context);
                    },
                  ),
                ),
                SizedBox(
                  height: 12.h,
                ),
                if (!canShowPasswordField)
                  SizedBox.shrink()
                else
                  Column(
                    children: [
                      SizedBox(
                        width: buttonSize,
                        child: TextField(
                          focusNode: passwordFocusNode,
                          textAlign: TextAlign.center,
                          controller: passwordEditingController,
                          obscureText: obscureText,
                          onTap: () {
                            if (mounted)
                              setState(() {
                                currentError = null;
                                KeyBoardController().showBottomDPKeyBoard(
                                    passwordEditingController,
                                    onEnter: validatePassword,
                                    obscureText: true,
                                    buildContext: context);
                              });
                          },
                          decoration: InputDecoration(
                              filled: true,
                              hintText: "login_view.password_field".tr(),
                              alignLabelWithHint: true,
                              suffixIcon: IconButton(
                                icon: Icon(!obscureText
                                    ? MaterialCommunityIcons.eye_off_outline
                                    : MaterialCommunityIcons.eye),
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                onPressed: () {
                                  if (mounted)
                                    setState(() {
                                      obscureText = !obscureText;
                                    });
                                },
                              )),
                          onEditingComplete: () {
                            validatePassword();
                          },
                        ),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      Center(
                        child: InkWell(
                            onTap: _resetPassword,
                            child: Text(
                              'login_view.forgot_password'.tr(),
                              style: CurrentTheme.subtitle2,
                            )),
                      )
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // validate entered username
  Future validateUserName() async {
    notificationBloc.getAnnouncements();
    await POSPlatform().writePlatformInfo();
    // if (POSPlatform().isDesktop()) appWindow.maximize();
    EasyLoading.show(status: 'please_wait'.tr());
    if (mounted)
      setState(() {
        currentError = null;
      });
    final username = usernameEditingController.text;
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Username entered: $username"));
    final result =
        await authController.checkUsername(username, authorize: false);
    EasyLoading.dismiss();
    if (result == null) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.success, "Username validation success: $result"));
      KeyBoardController().dismiss();
      KeyBoardController().showBottomDPKeyBoard(passwordEditingController,
          onEnter: validatePassword, obscureText: true, buildContext: context);
      canShowPasswordField = true;
      passwordFocusNode.requestFocus();
    } else {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Username validation error: $result"));
      currentError = result;
    }
    if (mounted) setState(() {});
  }

  ///validate entered password
  Future validatePassword() async {
    KeyBoardController().dismiss();
    if (mounted)
      setState(() {
        currentError = null;
      });
    EasyLoading.show(status: 'please_wait'.tr());
    final password = passwordEditingController.text;
    final username = usernameEditingController.text;
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.info, "Password entered"));
    final result = await authController.checkPassword(
        username, password, POSConfig().locCode);
    if (result?.success == true) {
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.success, "Password validation success: $result"));

      /* Check user location and ip address*/
      /* by dinuka 2022-09-08 */
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.info, "Check terminal validations"));
      String terminalResult = 'Terminal Verification Success';

      if (POSConfig().setup?.validatePosIp == true && kReleaseMode) {
        terminalResult = await authController.checkTerminal(
            username,
            POSConfig().locCode,
            POSConfig().terminalId,
            POSConfig().setup?.validatePOSGroups ?? false);
      }

      if (terminalResult == "Terminal Verification Success") {
        EasyLoading.dismiss();
        POSLoggerController.addNewLog(
            POSLogger(POSLoggerLevel.success, "Terminal validation success"));

        POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
            "Check terminal and user wise groups validations"));
        String terminalResult = 'Terminal Verification Success';

        final route = LandingView.routeName;

        // pop up the password change window
        if (result?.data != null && result?.data?.passworDRESET == true) {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PasswordChangeView(
                  user: username,
                  passwordData: result!.data!,
                ),
              ));
          return;
        }

        EasyLoading.show(
            status:
                'Starting the system'); //this block takes ~3 seconds to execute..so I added easyloading
        //check the sign on process
        if (!authController.checkSignOff() &&
            authController.checkManagerSignOff() &&
            authController.checkUserActiveStatus() &&
            authController.checkUserAlreadySignedOn() ==
                POSConfig().terminalId) {
          await authController.checkUsername(username);
          userBloc.changeSignOnStatus(SignOnStatus.SignOn);
          await authController.getUserPermission();
        } else {
          userBloc.changeSignOnStatus(SignOnStatus.None);
        }
        // EasyLoading.dismiss();
        //process the activation validation
        if (await ActivationController().process(context)) {
          // get dual screen url

          //new change: launching windows app instead of web
          // setState(() {});
          if (POSConfig().dualScreenWebsite != "") {
            EasyLoading.show(status: 'easy_loading.launch_dual'.tr());
            print(
                'launching dual display \n Path: ${POSConfig().dualScreenWebsite}');
            // String _url =
            //     '${POSConfig().dualScreenWebsite}?token=${ApiClient.bearerToken}&uuid=${DualScreenController.uuid}';
            // debugPrint(_url);
            // print(_url);
            // await canLaunchUrl(Uri.parse(_url))
            //     ? await launchUrl(Uri.parse(_url))
            //     : throw 'Could not launch $_url';

            //closing.. if the dual display app is running
            try {
              final result = await Process.run(
                  'cmd.exe', ['/c', 'taskkill /F /IM dual_screen_windows.exe']);
              LogWriter()
                  .saveLogsToFile('ERROR_Log_', ['Closing Dual_Display...']);

              print('Exit code: ${result.exitCode}');
              print('Stdout:\n${result.stdout}');
              print('Stderr:\n${result.stderr}');
            } catch (e) {
              await LogWriter().saveLogsToFile('ERROR_Log_',
                  ['Error Closing Dual_Display: ${e.toString()}']);
              print('Error: $e');
            }

            //launching the Dual_Display
            try {
              String uuid = "test";
              // if (kReleaseMode) {
              //   uuid = POSConfig().setupLocation +
              //       POSConfig().terminalId +
              //       POSConfig().locCode +
              //       Uuid().v4();
              // }

              DualScreenController.uuid = uuid;
              if (!POSPlatform().isDesktop())
                POSConfig().webSocketUrl =
                    'wss://posbackendbeta.24x7retail.com/ws';
              print('before connect ' + POSConfig().webSocketUrl);

              dualScreenChannel = WebSocketChannel.connect(
                Uri.parse(POSConfig().webSocketUrl),
              );
              POSLoggerController.addNewLog(
                  POSLogger(POSLoggerLevel.info, "Starting Dual_Display..."));
              POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.info,
                  "Dual_Display path: ${POSConfig().dualScreenWebsite}"));

              Process.run(POSConfig().dualScreenWebsite, [], runInShell: true);
            } catch (e) {
              POSLoggerController.addNewLog(POSLogger(
                  POSLoggerLevel.error, "Error starting Dual_Display: $e"));
            }
          }
          EasyLoading.show(status: 'Completing the setup');
          //killing the crystal report instance first, if available
          try {
            final result = await Process.run(
                'cmd.exe', ['/c', 'taskkill /F /IM CrystalReport.exe']);
            LogWriter()
                .saveLogsToFile('ERROR_Log_', ['Closing CrystalReport...']);

            print('Exit code: ${result.exitCode}');
            print('Stdout:\n${result.stdout}');
            print('Stderr:\n${result.stderr}');
          } catch (e) {
            await LogWriter().saveLogsToFile(
                'ERROR_Log_', ['Error Closing CrystalReport: ${e.toString()}']);
            print('Error: $e');
          }
          // launching crystal report plugin
          try {
            POSLoggerController.addNewLog(POSLogger(
                POSLoggerLevel.info, "Starting CrystalReport API..."));
            String localCrystalPath = dotenv.env['CRYSTAL_REPORT_PATH'] ?? '';
            //  var exec = "${localAPIPath!} dotnet run --urls http://0.0.0.0:71";
            POSLoggerController.addNewLog(
                POSLogger(POSLoggerLevel.info, "path: $localCrystalPath"));

            // var command = Process.run(
            //     'cmd.exe', ['/c', 'cd $localAPIPath && CrystalReport.exe'],
            //     runInShell: true);
            var command = Process.run(
              'CrystalReport.exe',
              [],
              runInShell: true,
              workingDirectory: localCrystalPath,
            );
          } catch (e) {
            POSLoggerController.addNewLog(POSLogger(
                POSLoggerLevel.error, "Error starting CrystalReport API: $e"));
          }
          POSLoggerController.addNewLog(
              POSLogger(POSLoggerLevel.info, "Navigating to $route}"));
          print("Navigating to $route}");
          // giving a delay to finish opening dual display and start to listen to websocket..then move to loging
          await Future.delayed(Duration(milliseconds: 2500), () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => LandingView(
                          showPromotion: true,
                        )));
            EasyLoading.dismiss();
          });

          // await Navigator.pushReplacementNamed(context, route, arguments: true);
        }
      } else {
        POSLoggerController.addNewLog(
            POSLogger(POSLoggerLevel.error, terminalResult));
        currentError = terminalResult;
      }
    } else {
      EasyLoading.dismiss();
      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.error, "Password validation error: $result"));
      currentError = (result?.loginAttemptData?.blockedAt != null)
          ? (result?.message ??
                  'The combination of username and password is invalid') +
              '\nTry after ${result?.loginAttemptData?.blockedAt?.replaceAll('T', ' ')}'
          : (result?.message ??
                  'The combination of username and password is invalid') +
              ((result?.loginAttemptData == null)
                  ? ''
                  : '\nRemaining attempts: ${(result?.loginAttemptData?.maxAttempts ?? 0) - (result?.loginAttemptData?.numberOfAttempts ?? 0)}');
    }
    if (mounted) setState(() {});
  }

  Future<void> _resetPassword() async {
    String? mobile = userBloc.currentUser?.mobile;
    if (mobile != null) {
      final otp = OTPController().generateOTP();
      setState(() {
        _otpCode = otp;
      });
      EasyLoading.show(status: 'please_wait'.tr());
      await SMSController().sendOTPCashier(mobile, otp);
      EasyLoading.dismiss();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(
                  'login_view.forgot_password_title'.tr(),
                  textAlign: TextAlign.center,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('login_view.forgot_password_subtitle'.tr()),
                    SizedBox(
                      height: 15.h,
                    ),
                    TextField(
                      controller: otpEditingController,
                      onEditingComplete: _continueForgetPassword,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: 'login_view.otp'.tr(),
                      ),
                    )
                  ],
                ),
                actions: [
                  AlertDialogButton(
                    onPressed: _continueForgetPassword,
                    text: 'login_view.continue'.tr(),
                  ),
                  AlertDialogButton(
                    onPressed: () => Navigator.pop(context),
                    text: 'login_view.cancel'.tr(),
                  )
                ],
              ));
    } else {
      showDialog(
          context: context,
          builder: (context) => POSErrorAlert(
                  title: 'login_view.warning'.tr(),
                  subtitle: 'login_view.mobile_not_found'.tr(),
                  actions: [
                    AlertDialogButton(
                      onPressed: () => Navigator.pop(context),
                      text: 'login_view.okay'.tr(),
                    )
                  ]));
    }
  }

  Future<void> _continueForgetPassword() async {
    if (_otpCode == otpEditingController.text) {
      Navigator.pop(context);
      EasyLoading.show(status: 'please_wait'.tr());
      final passwordPolicy = await AuthController().getUserPasswordPolicy();
      if (passwordPolicy != null)
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PasswordChangeView(
                user: userBloc.currentUser?.uSERHEDUSERCODE ?? '',
                passwordData: passwordPolicy,
              ),
            ));
      EasyLoading.dismiss();
    } else {
      EasyLoading.showError('login_view.invalid_otp'.tr());
    }
  }

  @override
  void dispose() {
    passwordFocusNode.dispose();
    userNameFocusNode.dispose();
    super.dispose();
  }
}
