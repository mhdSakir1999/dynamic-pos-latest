class CustomerLoyaltyGroupResult {
  List<CustomerLoyaltyGroupsList> customerLoyaltyGroups =
      <CustomerLoyaltyGroupsList>[];

  CustomerLoyaltyGroupResult({required this.customerLoyaltyGroups});

  CustomerLoyaltyGroupResult.fromJson(Map<String, dynamic> json) {
    if (json['customer_loyalty_groups'] != null) {
      customerLoyaltyGroups = <CustomerLoyaltyGroupsList>[];
      json['customer_loyalty_groups'].forEach((v) {
        customerLoyaltyGroups.add(new CustomerLoyaltyGroupsList.fromJson(v));
      });
    }

  }
}

class CustomerLoyaltyGroupsList {
  String? cLCODE;
  String? cLDESC;

  CustomerLoyaltyGroupsList({this.cLCODE, this.cLDESC});

  CustomerLoyaltyGroupsList.fromJson(Map<String, dynamic> json) {
    this.cLCODE = json['cL_CODE'];
    this.cLDESC = json['cL_DESC'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cL_CODE'] = this.cLCODE;
    data['cL_DESC'] = this.cLDESC;
    return data;
  }
}
