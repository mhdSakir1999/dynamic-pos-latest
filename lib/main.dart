/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan, TM.Sakir & Pubudu Wijethunga
 * Created At: 4/21/21, 10:47 AM
 * Editted,Migrated & Further developments by: TM.Sakir
 */

import 'dart:async';
import 'dart:ui';

import 'package:checkout/components/recurringApiCalls.dart';
import 'package:checkout/controllers/config/shared_preference_controller.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/controllers/usb_serial_controller.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:checkout/views/authentication/login_view.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supercharged/supercharged.dart';
import 'components/components.dart';
import 'components/mypos_screen_utils.dart';
import 'components/pos_platform.dart';
import 'pos_router.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await EasyLocalization.ensureInitialized();
      await SharedPreferenceController.init();
    } catch (e) {
      LogWriter().saveLogsToFile("ERROR_LOG_", [e.toString()]);
    }
    await SharedPreferenceController()
        .openAPI(); // opening the local api && printer plugin
    await SharedPreferenceController().getConfig(false);
    await SharedPreferenceController().getConfigLocal();
    await SharedPreferenceController().getConfig(false);
    posConnectivity.startListen();
    usbSerial.initSerialPort();
    recurringApiCalls.listenPhysicalCash();
    // this section is moved (websocket initialization) to the login screen. because there is a delay in initializing api/s

    //get unique id for dual display set up
    // String uuid = "test";
    // // if (kReleaseMode) {
    // //   uuid = POSConfig().setupLocation +
    // //       POSConfig().terminalId +
    // //       POSConfig().locCode +
    // //       Uuid().v4();
    // // }

    // DualScreenController.uuid = uuid;
    // if (!POSPlatform().isDesktop())
    //   POSConfig().webSocketUrl = 'wss://posbackendbeta.24x7retail.com/ws';
    // print('before connect ' + POSConfig().webSocketUrl);

    // dualScreenChannel = WebSocketChannel.connect(
    //   Uri.parse(POSConfig().webSocketUrl),
    // );
    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.error, errorDetails.exception.toString()));
    };

    runApp(
      RestartWidget(
        child: EasyLocalization(
            supportedLocales: [Locale('en', 'US'), Locale('si', 'LK')],
            path: 'assets/translations',
            // fallbackLocale: Locale('si', 'LK'),
            // fallbackLocale: Locale('en', 'US'),
            // startLocale: Locale('si', 'LK'),
            child: MyApp()),
      ),
    );
    if (POSPlatform().isDesktop())
      doWhenWindowReady(() {
        print(kReleaseMode);

        double scWidth =
            POSConfig().screen_width == 0 ? 1024 : POSConfig().screen_width;
        double scHeight =
            POSConfig().screen_height == 0 ? 768 : POSConfig().screen_height;
        bool defaultSize = POSConfig().default_size;

        if (!kReleaseMode /* || (scWidth == 1 && scHeight == 1) */) {
          final initialSize = Size(scWidth, scHeight);
          appWindow.minSize = initialSize;
          appWindow.size = initialSize;
          // appWindow.maximize();
          // DesktopWindow.setFullScreen(true);
        } else {
          if (defaultSize) {
            final initialSize = Size(scWidth, scHeight);
            appWindow.minSize = initialSize;
            appWindow.size = initialSize;
          } else {
            appWindow.maximize();
            DesktopWindow.setFullScreen(true);
          }
        }
        // appWindow.alignment = Alignment.center;

        appWindow.show();
      });
  }, (error, stackTrace) {
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.error, error.toString()));
    POSLoggerController.addNewLog(
        POSLogger(POSLoggerLevel.error, stackTrace.toString()));
  });

  configLoading();
}

void configLoading() {
  EasyLoading.instance
    // ..displayDuration = const Duration(milliseconds: 1000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = false
    ..displayDuration = Duration(milliseconds: 1100)
    ..dismissOnTap = false;
}

final inputBorderRadius = BorderRadius.only(
  bottomLeft: Radius.circular(POSConfig().rounderBorderRadiusBottomLeft),
  bottomRight: Radius.circular(POSConfig().rounderBorderRadiusBottomRight),
  topRight: Radius.circular(POSConfig().rounderBorderRadiusTopRight),
  topLeft: Radius.circular(POSConfig().rounderBorderRadiusTopLeft),
);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    posConnectivity.setContext(context);
    print('saas: ' + POSConfig().saas.toString());
    setConfig();
    final config = POSConfig();
    // posConnectivity.context = context;
    // POSConnectivity().context = context;
    return ScreenUtilInit(
      builder: (buildContext, child) {
        return MaterialApp(
          scrollBehavior: ScrollBehaviour(),
          onGenerateRoute: POSRouter.generateRoute,
          title: '24x7Retail | POS',
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          builder: EasyLoading.init(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: false,
            colorScheme: ThemeData.light().colorScheme.copyWith(
                surface: POSConfig()
                    .backgroundColor
                    .toColor()), // background: POSConfig().backgroundColor.toColor() --deprecated
            primaryColor: POSConfig().primaryColor.toColor(),
            scaffoldBackgroundColor: Colors.transparent,
            elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 50.w, vertical: 25.h),
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                      bottomLeft:
                          Radius.circular(config.rounderBorderRadiusBottomLeft),
                      bottomRight: Radius.circular(
                          config.rounderBorderRadiusBottomRight),
                      topRight:
                          Radius.circular(config.rounderBorderRadiusTopRight),
                      topLeft:
                          Radius.circular(config.rounderBorderRadiusTopLeft),
                    )),
                    textStyle: TextStyle(fontSize: 20.sp))),
            inputDecorationTheme: InputDecorationTheme(
                fillColor: config.primaryLightColor.toColor(),
                border: OutlineInputBorder(
                    borderRadius: inputBorderRadius,
                    borderSide:
                        BorderSide(color: config.primaryLightColor.toColor())),
                errorBorder:
                    OutlineInputBorder(borderRadius: inputBorderRadius),
                disabledBorder:
                    OutlineInputBorder(borderRadius: inputBorderRadius),
                enabledBorder: OutlineInputBorder(
                    borderRadius: inputBorderRadius,
                    borderSide:
                        BorderSide(color: config.primaryLightColor.toColor())),
                focusedBorder: OutlineInputBorder(
                    borderRadius: inputBorderRadius,
                    borderSide:
                        BorderSide(color: config.primaryLightColor.toColor())),
                focusedErrorBorder:
                    OutlineInputBorder(borderRadius: inputBorderRadius)),
            textButtonTheme: TextButtonThemeData(style: ButtonStyle()),
            textTheme: TextTheme(
              displayMedium: TextStyle(
                  color: config.primaryLightColor.toColor(),
                  fontSize: 46 * getFontSize()),
              displaySmall: TextStyle(
                  color: config.primaryLightColor.toColor(),
                  fontSize: 36 * getFontSize()),
              headlineMedium: TextStyle(
                  color: config.primaryLightColor.toColor(),
                  fontSize: 32 * getFontSize()),
              headlineSmall: TextStyle(
                  color: config.primaryLightColor.toColor(),
                  fontSize: 28 * getFontSize()),
              titleLarge: TextStyle(
                  color: config.primaryLightColor.toColor(),
                  fontSize: 24 * getFontSize()),
              bodySmall: TextStyle(),
              titleSmall: TextStyle(
                  color: config.primaryLightColor.toColor(),
                  fontSize: 18 * getFontSize()),
              titleMedium: TextStyle(fontSize: 24 * getFontSize()),
              bodyMedium: TextStyle(
                  color: config.primaryLightColor.toColor(),
                  fontSize: 20 * getFontSize()),
            ),
            dialogTheme: DialogTheme(
                titleTextStyle: TextStyle(
                    color: config.primaryLightColor.toColor(),
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.w)),
                contentTextStyle: TextStyle(
                    color: config.primaryLightColor.toColor(),
                    fontSize: 24 * getFontSize()),
                backgroundColor: config.primaryColor.toColor()),
            sliderTheme: SliderThemeData(
              thumbColor: Colors.red,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.grey,
            ),
            cardTheme: CardTheme(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(config.rounderBorderRadiusBottomLeft),
              bottomRight:
                  Radius.circular(config.rounderBorderRadiusBottomRight),
              topRight: Radius.circular(config.rounderBorderRadiusTopRight),
              topLeft: Radius.circular(config.rounderBorderRadiusTopLeft),
            ))),
            primaryColorDark: config.primaryDarkColor.toColor(),
            primaryColorLight: config.primaryLightColor.toColor(),
          ),
          home: Root(),
        );
      },
      designSize: Size(1366, 768),
    );
  }

  //for now set the config manually
  void setConfig() {
    // Wakelock.enable();
    // final config = POSConfig();
    //
    // config.demoPOS = true;
    // config.rounderBorderRadiusTopRight = 14;
    // config.primaryLightColor = "#fafafa".toColor();
  }
}

/// This is the root widget of the application. Here you can show login screen
/// or display another screen based on the login state

class Root extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    posConnectivity.context = context;
    CurrentTheme().init(context);
    KeyBoardController().init(context);
    return LoginView();
  }
}

class RestartWidget extends StatefulWidget {
  RestartWidget({required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()!.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}

// making all the listview builders scrollable for windows touch screens
// without this class - we have needed to use scrollbars
class ScrollBehaviour extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus
      };
}
