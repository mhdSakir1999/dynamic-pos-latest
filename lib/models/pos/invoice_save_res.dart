/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 7/27/22, 5:30 PM
 */
class InvoiceSaveRes {
  final bool success;
  final double earnedPoints;
  String? resReturn;

  InvoiceSaveRes(this.success, this.earnedPoints, this.resReturn);
}
