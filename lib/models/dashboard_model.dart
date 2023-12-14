class Dashboard {
  Dashboard({
    this.noOfLoyaltyRegistrations,
    this.noOfEbillRegistrations,
    this.valueOfLoyaltyTransactions,
    this.cashierMonthlySales,
  });

  int? noOfLoyaltyRegistrations;
  int? noOfEbillRegistrations;
  double? valueOfLoyaltyTransactions;
  List<CashierMonthlySale>? cashierMonthlySales;

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
        noOfLoyaltyRegistrations: json["noOfLoyaltyRegistrations"] != null
            ? int.tryParse(json["noOfLoyaltyRegistrations"])
            : null,
        noOfEbillRegistrations: json["noOfEbillRegistrations"] != null
            ? int.tryParse(json["noOfEbillRegistrations"])
            : null,
        valueOfLoyaltyTransactions: json["valueOfLoyaltyTransactions"],
        cashierMonthlySales: List<CashierMonthlySale>.from(
            json["cashierMonthlySales"]
                .map((x) => CashierMonthlySale.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "noOfLoyaltyRegistrations": noOfLoyaltyRegistrations,
        "noOfEbillRegistrations": noOfEbillRegistrations,
        "valueOfLoyaltyTransactions": valueOfLoyaltyTransactions,
        "cashierMonthlySales":
            List<dynamic>.from(cashierMonthlySales!.map((x) => x.toJson())),
      };
}

class CashierMonthlySale {
  CashierMonthlySale({
    this.cashier,
    this.transactionDate,
    this.sales,
  });

  String? cashier;
  DateTime? transactionDate;
  double? sales;

  factory CashierMonthlySale.fromJson(Map<String, dynamic> json) =>
      CashierMonthlySale(
        cashier: json["cashier"],
        transactionDate: DateTime.tryParse(json["transactionDate"]),
        sales: json["sales"],
      );

  Map<String, dynamic> toJson() => {
        "cashier": cashier,
        "transactionDate": transactionDate?.toIso8601String(),
        "sales": sales,
      };
}
