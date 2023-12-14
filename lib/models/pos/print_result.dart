/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/1/21, 6:31 PM
 */
import 'package:checkout/extension/extensions.dart';

class PrintResult {
  bool? success;
  String? pdf;

  PrintResult({this.success, this.pdf});

  PrintResult.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString().parseBool() ?? false;
    pdf = json['pdf'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['pdf'] = this.pdf;
    return data;
  }
}

class PrintStatus {
  final bool goBack;
  final bool showViewButton;
  final String urlPath;

  PrintStatus(this.goBack, this.showViewButton, this.urlPath);
}
