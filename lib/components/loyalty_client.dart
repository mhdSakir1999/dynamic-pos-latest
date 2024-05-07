/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/30/21, 12:54 PM
 */
import 'dart:convert';
//import 'dart:html';
import 'dart:io';

import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'api_client.dart';

class LoyaltyApiClient {
  static String bearerToken = "";
  static Future<Response<dynamic>?> call(String endpoint, ApiMethod method,
      {FormData? formData,
      Map<String, dynamic>? data,
      bool errorToast = true,
      bool successToast = false,
      bool localCall = false,
      bool authorize = true,
      bool recallOutlet = false,
      int successCode = 200}) async {
    POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.apiInfo,
        "-------------------Loyalty API Call Started------------------------------"));
    //String url = 'http://localhost:20954/api/';
    String url = POSConfig().loyaltyServerCentral;
    String localUrl = POSConfig().loyaltyServerOutlet;
    //if (!kReleaseMode) url = localUrl;
    localCall = false;
    print(url);
    print(localUrl);
    try {
      Dio dio = Dio();

      // var bytes = utf8
      //     .encode("6f4a3385-1550-4418-ae66-2434da862cde"); // data being hashed
      // var digest = sha1.convert(bytes);
      //debugPrint(digest.toString());
      Map<String, dynamic> headers = {
        // "x-api-key": digest
      };
      if (authorize && (!POSConfig().hasCentralLoyaltyServer && !localCall)) {
        headers = {
          HttpHeaders.contentTypeHeader: "application/json",
          HttpHeaders.authorizationHeader: "Bearer " + ApiClient.bearerToken
        };
      } else {
        headers = {
          HttpHeaders.contentTypeHeader: "application/json",
        };
      }

      final options = Options(
        followRedirects: false,
        headers: headers,
        validateStatus: (status) {
          return true;
        },
        // headers: headers,
      );
      String uri = "$url$endpoint";
      final localUri = "$localUrl$endpoint";
      if (localCall || url.isEmpty) {
        uri = localUri;
      }
      print("URL: $uri");
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.apiInfo, "URL: $uri"));
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.apiInfo, "Method: ${method.toString()}"));

      Map<String, dynamic> temp = {};
      formData?.fields.forEach((e) {
        temp[e.key] = e.value;
      });
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.apiInfo, "FormData: $temp"));

      Response response;
      dynamic tempFormData = data;
      if (formData != null) tempFormData = formData;
      if (data != null) tempFormData = jsonEncode(data);

      //debugPrint(uri);
      switch (method) {
        case ApiMethod.GET:
          //EasyLoading.showError('START API CALL ',
          //    duration: Duration(seconds: 10));
          response = await dio.get(uri, options: options);
          //EasyLoading.showError('END API CALL ' + uri,
          //    duration: Duration(seconds: 10));
          if (localCall && localUrl != url)
            await dio.get(localUri, options: options);

          break;
        case ApiMethod.POST:
          // FormData temp = formData??FormData.fromMap(data);
          response = await dio.post(uri, data: tempFormData, options: options);
          if (localCall && localUrl != url)
            await dio.post(localUrl, data: tempFormData, options: options);
          break;
        case ApiMethod.PUT:
          // FormData temp = formData??FormData.fromMap(data);
          response = await dio.put(uri, data: tempFormData, options: options);
          if (localCall && localUrl != url)
            await dio.put(localUrl, data: tempFormData, options: options);
          break;
        case ApiMethod.DELETE:
          response =
              await dio.delete(uri, data: tempFormData, options: options);
          break;
      }
      final result = response.data;

      var logger = LogWriter.logger;
      try {
        logger.d('API Call: ${method.toString()} \nURL: $uri');
        logger.d('Status Code: ${response.statusCode}');
        logger.d('Response Body: ${response.data.toString()}');
        await LogWriter().saveLogsToFile('API_Log_', [
          'API Call: ${method.toString()} \nURL: $uri',
          'Status Code: ${response.statusCode}',
          'Response Body: ${response.data.toString()}',
        ]);
      } catch (e) {
        logger.d('API Call: ${method.toString()} \nURL: $uri');
        logger.d('Status Code: ${response.statusCode}');
        logger.d('Response Body: ${response.data.toString()}');
        logger.d('API Call Error: ${e.toString()}');
        await LogWriter().saveLogsToFile('API_Log_', [
          'API Call: ${method.toString()} \nURL: $uri',
          'Status Code: ${response.statusCode}',
          'Response Body: ${response.data.toString()}',
          'API Call Error: ${e.toString()}'
        ]);
      }

      POSLoggerController.addNewLog(POSLogger(
          POSLoggerLevel.apiInfo, "Status Code: ${response.statusCode}"));

      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.apiInfo, "Response: ${response.data}"));
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.apiInfo,
          "-------------------Loyalty API Call End------------------------------"));
      if (response.statusCode == 401) {
        POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.apiError,
            "-------------------Loyalty API Regenerating the token------------------------------"));
        await ApiClient.regenerateToken();
        return await call(endpoint, method,
            formData: formData,
            data: data,
            successCode: successCode,
            successToast: successToast,
            errorToast: errorToast,
            localCall: localCall);
      }

      if (response.statusCode != successCode) {
        //debugPrint(result);
        // if (errorToast) {
        //   EasyLoading.showToast(result["message"]);
        // }
      } else {
        if (successToast) {
          EasyLoading.showToast(result["message"],
              toastPosition: EasyLoadingToastPosition.bottom);
        }
      }
      return response;
    } on DioException catch (e) {
      recallOutlet = false;
      if (recallOutlet) {
        print("dwad");
        EasyLoading.showError(
            'Cannot connect to the loyalty server. Fetching customer records from Outlet server.');

        return await call(endpoint, method,
            formData: formData,
            data: data,
            successCode: successCode,
            successToast: successToast,
            errorToast: errorToast,
            localCall: true);
      } else {
        EasyLoading.showError('ERROR 2 - ' + e.toString(),
            duration: Duration(seconds: 10),dismissOnTap: true);
        //EasyLoading.showError('Cannot connect to the loyalty server');
      }
    } on Exception catch (e) {
      EasyLoading.showError('ERROR 2 - ' + e.toString(),
          duration: Duration(seconds: 10),dismissOnTap: true);
      POSLoggerController.addNewLog(
          POSLogger(POSLoggerLevel.apiError, e.toString()));
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.apiInfo,
          "-------------------Loyalty API Call End with Exception------------------------------"));

      return null;
    }
  }
}
