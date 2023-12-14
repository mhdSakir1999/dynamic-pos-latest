class CustomerBundleResult {
  bool? success;
  List<CustomerBundles>? bundles;

  CustomerBundleResult({this.success, this.bundles});

  CustomerBundleResult.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['bundles'] != null) {
      bundles = <CustomerBundles>[];
      json['bundles'].forEach((v) {
        bundles!.add(new CustomerBundles.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.bundles != null) {
      data['bundles'] = this.bundles!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CustomerBundles {
  String? bunDCODE;

  CustomerBundles({this.bunDCODE});

  CustomerBundles.fromJson(Map<String, dynamic> json) {
    bunDCODE = json['bunD_CODE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['bunD_CODE'] = this.bunDCODE;
    return data;
  }
}
