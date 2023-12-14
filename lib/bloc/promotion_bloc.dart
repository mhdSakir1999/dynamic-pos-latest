import 'package:rxdart/rxdart.dart';

import '../models/promotion_model.dart';

class PromotionBloc{
  final _promoList = BehaviorSubject<List<Promotion>>();
  List<Promotion> get promotionList => _promoList.valueOrNull??[];


  void addPromotions(List<Promotion> promotion){
    _promoList.add(promotion);
  }
  void dispose(){
    _promoList.close();
  }
}
final PromotionBloc promotionBloc = PromotionBloc();