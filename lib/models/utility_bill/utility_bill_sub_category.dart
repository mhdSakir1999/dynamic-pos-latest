class UtilityBillSubcategoryResult {
  UtilityBillSubcategoryResult({
    this.utilityBillSubcategory,
    this.message,
  });

  List<UtilityBillSubcategory>? utilityBillSubcategory;
  String? message;

  factory UtilityBillSubcategoryResult.fromJson(Map<String, dynamic> json) =>
      UtilityBillSubcategoryResult(
        utilityBillSubcategory: List<UtilityBillSubcategory>.from(
            json["utility_bill_subcategory"]
                .map((x) => UtilityBillSubcategory.fromJson(x))),
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "utility_bill_category":
            List<dynamic>.from(utilityBillSubcategory!.map((x) => x.toJson())),
        "message": message,
      };
}

class UtilityBillSubcategory {
  UtilityBillSubcategory({
    this.ubSCode,
    this.ubCCode,
    this.ubSCName,
  });

  String? ubSCode;
  String? ubCCode;
  String? ubSCName;

  factory UtilityBillSubcategory.fromJson(Map<String, dynamic> json) =>
      UtilityBillSubcategory(
        ubSCode: json["ubsC_CODE"],
        ubCCode: json["ubC_CODE"],
        ubSCName: json["ubsC_NAME"],
      );

  Map<String, dynamic> toJson() => {
        "ubsC_CODE": ubSCode,
        "ubC_CODE": ubCCode,
        "ubsC_NAME": ubSCName,
      };
}
