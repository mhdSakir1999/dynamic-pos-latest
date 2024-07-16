/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/30/21, 12:54 PM
 */
import 'dart:convert';
import 'dart:io';

import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/controllers/logWriter.dart';
import 'package:checkout/controllers/pos_logger_controller.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:checkout/models/pos_logger.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ApiClient {
  // static String url = "http://192.168.8.100:1998/";
  static String url = "";
  static String bearerToken = "";
  static String bearerTokenBackend = "";

  static Future<Response<dynamic>?> call(String endpoint, ApiMethod method,
      {FormData? formData,
      Map<String, dynamic>? data,
      bool errorToast = true,
      bool successToast = false,
      int successCode = 200,
      String? overrideUrl,
      bool local = false,
      bool authorize = true,
      bool writeLog = true,
      bool backendToken = false,
      bool restrictLocalCall = false}) async {
    if (writeLog)
      POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.apiInfo,
          "-------------------API Call Started------------------------------"));
    try {
      Dio dio = Dio();

      // var bytes = utf8
      //     .encode("6f4a3385-1550-4418-ae66-2434da862cde"); // data being hashed
      // var digest = sha1.convert(bytes);
      //debugPrint(digest.toString());
      Map<String, dynamic>? headers;
      if (authorize && bearerToken.isNotEmpty) {
        headers = {HttpHeaders.authorizationHeader: "Bearer " + bearerToken};
      }
      if (backendToken) {
        String token = await generateBackendToken(overrideUrl!);
        headers = {HttpHeaders.authorizationHeader: "Bearer " + token};
      }
      var options = Options(
        followRedirects: false,
        headers: headers,
        validateStatus: (status) {
          return true;
        },
        // headers: headers,
      );
      if (local) {
        overrideUrl = POSConfig().local;
      }
      final uri = "${overrideUrl ?? url}$endpoint";
      if (writeLog) {
        POSLoggerController.addNewLog(
            POSLogger(POSLoggerLevel.apiInfo, "URL: $uri"));
        POSLoggerController.addNewLog(
            POSLogger(POSLoggerLevel.apiInfo, "Method: ${method.toString()}"));
      }
      dynamic tempFormData = data;
      if (formData != null) {
        tempFormData = formData;
        Map<String, dynamic> temp = {};
        formData.fields.forEach((e) {
          temp[e.key] = e.value;
        });
        if (writeLog)
          POSLoggerController.addNewLog(
              POSLogger(POSLoggerLevel.apiInfo, "FormData: $temp"));
      }
      print(bearerToken);
      if (data != null) {
        tempFormData = jsonEncode(data);
        if (writeLog)
          POSLoggerController.addNewLog(
              POSLogger(POSLoggerLevel.apiInfo, "Raw Data: $data"));
        options.headers?.putIfAbsent(
            HttpHeaders.contentTypeHeader, () => "application/json");

        await LogWriter().saveLogsToFile('API_Log_', [
          '================== API REQUEST DATA FOR {$uri}======================',
          tempFormData,
          '===================================================================='
        ]);
      }

      if (restrictLocalCall && POSConfig().localMode) {
        EasyLoading.showError('This operation is restricted in local mode');
        return null;
      }

      Response response;

      debugPrint(uri);
      switch (method) {
        case ApiMethod.GET:
          response = await dio.get(uri, options: options, data: tempFormData);
          break;
        case ApiMethod.POST:
          // FormData temp = formData??FormData.fromMap(data);
          response = await dio.post(uri, data: tempFormData, options: options);
          break;
        case ApiMethod.PUT:
          // FormData temp = formData??FormData.fromMap(data);
          response = await dio.put(uri, data: tempFormData, options: options);
          break;
        case ApiMethod.DELETE:
          response =
              await dio.delete(uri, data: tempFormData, options: options);
          break;
      }

      //author: TM.Sakir on 9/25/2023 2:06 PM
      //new change -- try to get all api responses in a log file
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

      final result = response.data;
      if (writeLog) {
        POSLoggerController.addNewLog(POSLogger(
            POSLoggerLevel.apiInfo, "Status Code: ${response.statusCode}"));

        POSLoggerController.addNewLog(
            POSLogger(POSLoggerLevel.apiInfo, "Response: ${response.data}"));
        POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.apiInfo,
            "-------------------API Call End------------------------------"));
      }

      if (response.statusCode == 401) {
        if (writeLog)
          POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.apiError,
              "-------------------POS API Regenerating the token------------------------------"));
        await regenerateToken();
        return await call(endpoint, method,
            formData: formData,
            data: data,
            successCode: successCode,
            successToast: successToast,
            errorToast: errorToast);
      }

      if (response.statusCode != successCode) {
        //debugPrint(result);
        if (errorToast && !local) {
          if (result == null || result.toString().isEmpty) {
            EasyLoading.showToast(
                duration: Duration(milliseconds: 1100),
                "easy_loading.invalid".tr()); //Invalid api response
          } else {
            final message = result?["message"] ?? "";
            if (message.toString().isNotEmpty && !local) {
              EasyLoading.showToast(
                  duration: Duration(milliseconds: 1100), message);
            }
          }
        }
      } else {
        if (successToast) {
          EasyLoading.showToast(result["message"],
              duration: Duration(milliseconds: 1100),
              toastPosition: EasyLoadingToastPosition.bottom);
        }
      }
      return response;
    } on DioException catch (ex) {
      EasyLoading.dismiss();
      if (ex.type == DioExceptionType.connectionTimeout) {
        throw Exception("Connection  Timeout Exception");
      }
      EasyLoading.showError('Cannot connect to the Server. Url: $overrideUrl');

      throw Exception(ex.message);
    } on Exception catch (e) {
      if (writeLog) {
        POSLoggerController.addNewLog(
            POSLogger(POSLoggerLevel.apiError, e.toString()));
        POSLoggerController.addNewLog(POSLogger(POSLoggerLevel.apiInfo,
            "-------------------API Call End with Exception------------------------------"));
      }
      return null;
    }
  }

  static Future regenerateToken() async {
    final Response<dynamic>? res = await call(
        'users/regenerate_token', ApiMethod.POST,
        formData: FormData.fromMap(<String, dynamic>{'old_token': bearerToken}),
        authorize: false);
    bearerToken = res?.data != '' ? res?.data['token'] ?? '' : '';
  }

  static Future<String> generateBackendToken(String url) async {
    final Response<dynamic>? res = await call(
        'Login/${userBloc.currentUser?.uSERHEDUSERCODE}', ApiMethod.GET,
        authorize: false, overrideUrl: url, errorToast: false);
    return res?.data != '' ? res?.data['token'] ?? '' : '';
  }
}

enum ApiMethod { GET, POST, PUT, DELETE }
