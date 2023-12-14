class UtilityBillCategoryResult {
  UtilityBillCategoryResult({
    this.utilityBillCategory,
    this.message,
  });

  List<UtilityBillCategory>? utilityBillCategory;
  String? message;

  factory UtilityBillCategoryResult.fromJson(Map<String, dynamic> json) =>
      UtilityBillCategoryResult(
        utilityBillCategory: List<UtilityBillCategory>.from(
            json["utility_bill_category"]
                .map((x) => UtilityBillCategory.fromJson(x))),
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "utility_bill_category":
            List<dynamic>.from(utilityBillCategory!.map((x) => x.toJson())),
        "message": message,
      };
}

class UtilityBillCategory {
  UtilityBillCategory({
    this.ubCCode,
    this.ubCName,
  });

  String? ubCCode;
  String? ubCName;

  factory UtilityBillCategory.fromJson(Map<String, dynamic> json) =>
      UtilityBillCategory(
        ubCCode: json["ubC_CODE"],
        ubCName: json["ubC_NAME"],
      );

  Map<String, dynamic> toJson() => {
        "ubC_ID": ubCCode,
        "ubC_NAME": ubCName,
      };
}
