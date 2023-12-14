class CustomerGroupResult {
  List<CustomerGroupsList> customerGroups  =<CustomerGroupsList>[];

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
    data['customer_groups'] = this.customerGroups.map((i) => i.toJson()).toList();
    return data;
  }

}

class CustomerGroupsList {
  String? cGCODE;
  String? cGDESC;

  CustomerGroupsList({this.cGCODE, this.cGDESC});

  CustomerGroupsList.fromJson(Map<String, dynamic> json) {
    this.cGCODE = json['cG_CODE'];
    this.cGDESC = json['cG_DESC'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cG_CODE'] = this.cGCODE;
    data['cG_DESC'] = this.cGDESC;
    return data;
  }
}
