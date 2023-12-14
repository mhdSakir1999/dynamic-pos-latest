class PromotionGroupBundleResult {
  List<String>? groupBundles;
  bool? success;

  PromotionGroupBundleResult({this.groupBundles, this.success});

  PromotionGroupBundleResult.fromJson(Map<String, dynamic> json) {
    groupBundles = json['group_bundles'].cast<String>();
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['group_bundles'] = this.groupBundles;
    data['success'] = this.success;
    return data;
  }
}
