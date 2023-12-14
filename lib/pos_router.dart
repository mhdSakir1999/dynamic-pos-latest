/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/21/21, 10:55 AM
 */

import 'package:checkout/components/components.dart';
import 'package:checkout/views/authentication/exit_screen.dart';
import 'package:checkout/views/invoice/cart.dart';
import 'package:checkout/views/customer/customer_search_view.dart';
import 'package:checkout/views/invoice/payment_view.dart';
import 'package:checkout/views/invoice/product_search_view.dart';
import 'package:checkout/views/invoice/recall_backend_invoice_view.dart';
import 'package:checkout/views/landing/landing.dart';
import 'package:checkout/views/landing/open_float_view.dart';
import 'package:checkout/views/pos_functions/special_functions.dart';
import 'package:checkout/views/pos_functions/utility_bill/utility_bill_home.dart';
import 'package:checkout/views/shift_reconciliation/shift_reconciliation_view.dart';
import 'package:flutter/material.dart';

import 'views/authentication/login_view.dart';

class POSRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case LoginView.routeName:
        return MaterialPageRoute(builder: (_) => LoginView());
      case LandingView.routeName:
        return MaterialPageRoute(builder: (_) => LandingView());
      case OpenFloatScreen.routeName:
        return MaterialPageRoute(builder: (_) => OpenFloatScreen());
      case Cart.routeName:
        return MaterialPageRoute(builder: (_) => Cart());
      case SpecialFunctions.routeName:
        return MaterialPageRoute(builder: (_) => SpecialFunctions());
      case PaymentView.routeName:
        return MaterialPageRoute(builder: (_) => PaymentView());
      case ProductSearchView.routeName:
        return MaterialPageRoute(builder: (_) => ProductSearchView());
      case CustomerSearchView.routeName:
        return MaterialPageRoute(builder: (_) => CustomerSearchView());
      case ShiftReconciliationView.routeName:
        return MaterialPageRoute(builder: (_) => ShiftReconciliationView());
      case ExitScreen.routeName:
        return MaterialPageRoute(builder: (_) => ExitScreen());
      case UtilityBillHome.routeName:
        return MaterialPageRoute(builder: (_) => UtilityBillHome());
      case RecallBackendInvoice.routeName:
        return MaterialPageRoute(builder: (_) => RecallBackendInvoice());
      default:
        return MaterialPageRoute(
            builder: (context) => POSBackground(
                  child: Scaffold(
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No route defined for ${settings.name}',
                          style: CurrentTheme.headline6,
                          textAlign: TextAlign.center,
                        ),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Go Back'))
                      ],
                    ),
                  ),
                ));
    }
  }
}
