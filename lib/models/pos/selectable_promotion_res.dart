/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 10/11/22, 4:53 PM
 */

import 'specific_paymodes.dart';

class SelectablePaymentModeWisePromotions {
  final String code;
  final String desc;
  final double amount;
  final String phCode;
  final String pdCode;
  final List<PromoCardBin>? cardBin;

  SelectablePaymentModeWisePromotions(
      {required this.code,required  this.desc,required  this.amount,required  this.phCode,required  this.pdCode,required this.cardBin,required this.discPre});

  final double  discPre;
}
