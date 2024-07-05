class CustomerGroupResult {
  List<CustomerGroupsList> customerGroups = <CustomerGroupsList>[];

  CustomerGroupResult({required this.customerGroups});

  CustomerGroupResult.fromJson(Map<String, dynamic> json) {
    if (json['customer_groups'] != null) {
      customerGroups = <CustomerGroupsList>[];
      json['customer_groups'].forEach((v) {
        customerGroups.add(new CustomerGroupsList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['customer_groups'] =
        this.customerGroups.map((i) => i.toJson()).toList();
    return data;
  }
}

class CustomerGroupsList {
  String? cGCODE;
  String? cGDESC;
  bool? cGOTPREQUIRED;
  bool? cGPERMISSIONREQUIRED;
  String? cG_MENUTAG;

  CustomerGroupsList(
      {this.cGCODE,
      this.cGDESC,
      this.cGOTPREQUIRED,
      this.cGPERMISSIONREQUIRED,
      this.cG_MENUTAG});

  CustomerGroupsList.fromJson(Map<String, dynamic> json) {
    this.cGCODE = json['cG_CODE'];
    this.cGDESC = json['cG_DESC'];
    try {
      this.cGOTPREQUIRED = json['cG_OTP_REQUIRED'] ?? false;
      this.cGPERMISSIONREQUIRED = json['cG_PERMISSION_REQUIRED'] ?? false;
      this.cG_MENUTAG = json['cG_MENUTAG'] ?? '';
    } catch (e) {
      // this is not necessary
      this.cGOTPREQUIRED = false;
      this.cGPERMISSIONREQUIRED = false;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cG_CODE'] = this.cGCODE;
    data['cG_DESC'] = this.cGDESC;
    return data;
  }
}
