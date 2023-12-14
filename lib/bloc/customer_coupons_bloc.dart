import 'package:checkout/bloc/customer_bloc.dart';
import 'package:checkout/models/loyalty/customer_coupons_result.dart';
import 'package:rxdart/rxdart.dart';

import '../controllers/customer_controller.dart';

class CustomerCouponBloc {
  final _customerCoupons = BehaviorSubject<CustomerCouponsResult?>();

  Stream<CustomerCouponsResult?> get allCouponsList => _customerCoupons.stream;

  CustomerCouponsResult? get availableCoupons => _customerCoupons.valueOrNull;

  List<Coupons> removedCouponsList = [];

  Future<void> getAvailableCoupons() async {
    final code = customerBloc.currentCustomer?.cMCODE ?? '0';
    // EasyLoading.show(status: 'please_wait'.tr(), dismissOnTap: true);
    final res = await CustomerController().getAvailableCoupons(code);
    _customerCoupons.sink.add(res);
    // EasyLoading.dismiss();
  }

  void removeCoupon(Coupons? coupon) {
    removedCouponsList.add(coupon!);
    print(removedCouponsList);
    final list = availableCoupons?.couponsList ?? [];
    if (list.isNotEmpty) {
      list.remove(coupon);
      _customerCoupons.sink
          .add(CustomerCouponsResult(success: true, couponsList: list));
    }
  }

  void undoRemovedCoupons() {
    // _customerCoupons.sink.add(_couponsResult);
  }

  void clearCoupons() {
    _customerCoupons.sink.add(null);
  }

  void dispose() {
    _customerCoupons.close();
  }
}

final customerCouponBloc = CustomerCouponBloc();
