
/// This data transfer object used to send and retried promotions for specific items
class PromoCartItemDto {
  ///not used in response
  double _qty = 0;
  final String productCode;

  PromoCartItemDto({required this.productCode});

  double get qty => _qty;

  set qty(double value) {
    _qty += value;
  }

  Map<String, dynamic> toMap() {
    return {
      'qty': this._qty,
      'productCode': this.productCode,
    };
  }
}
