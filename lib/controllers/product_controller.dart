/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 5/14/21, 6:22 PM
 */

import 'package:checkout/bloc/cart_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/models/pos/GroupResults.dart';
import 'package:checkout/models/pos/pro_price.dart';
import 'package:checkout/models/pos/product_result.dart';
import 'package:checkout/models/pos/variant_result.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../models/pos/location_wise_stock_result.dart';

class ProductController {
  //TODO user_bloc => Current user , POSConfig() => terminal+location
  Future<ProductResult?> searchProductByBarcode(String code, double qty) async {
    // I am sending absolute qty because this api cannot return proPrices if it is a minus qty
    final res = await ApiClient.call(
        "products/${POSConfig().locCode}/$code?priceMode=${cartBloc.cartSummary?.priceMode ?? ''}&qty=${qty.abs()}",
        ApiMethod.GET);
    print(res?.data);
    if (res == null || res.data == null || res.data is String) return null;
    return ProductResult.fromJson(res.data);
  }

  Future<List<Product>> searchProductByKeyword(String keyword, int page,
      int filterBy, bool firstLetterSearch, bool combinedSearch) async {
    final res = await ApiClient.call(
        "products/search/${POSConfig().locCode}/$keyword?items=100&page=$page&filteredBy=$filterBy&byfirstletter=${firstLetterSearch ? 1 : 0}&combineSearch=${combinedSearch ? 1 : 0}",
        ApiMethod.GET);
    if (res == null || res.data == null) return [];
    final List<dynamic> products = res.data?["products"] ?? [];
    return products.take(20).map((e) => Product.fromJson(e)).toList();
  }

  Future<ProPriceResults?> getProductsMultiplePrices(
      String code, double qty) async {
    final res = await ApiClient.call(
      'price/multiple_prices?loc=${POSConfig().locCode}&code=$code&qty=$qty&priceMode=${cartBloc.cartSummary?.priceMode ?? ''}',
      ApiMethod.GET,
    );
    if (res == null || res.data == null) return null;
    return ProPriceResults.fromJson(res.data);
  }

  Future addToLostSale(Product? product, String searchText, double qty) async {
    final res = await ApiClient.call("products/add_lost_sale", ApiMethod.POST,
        formData: FormData.fromMap({
          "code": product?.pLUCODE,
          "desc": product?.pLUPOSDESC ?? searchText,
          "qty": product?.sIH?.toDouble() ?? 0,
          "price": product?.sELLINGPRICE?.toDouble() ?? 0,
          'user': userBloc.currentUser?.uSERHEDUSERCODE ?? "Unauthorized",
          'loc': POSConfig().locCode
        }));
    if (res?.statusCode == 200) {
      EasyLoading.showSuccess('product_view.success_lost'.tr());
    }
  }

  Future reorder(Product? product, String searchText, double qty) async {
    final res = await ApiClient.call("products/reorder", ApiMethod.POST,
        formData: FormData.fromMap({
          "code": product?.pLUCODE,
          "desc": product?.pLUPOSDESC ?? searchText,
          "qty": qty,
          "price": product?.sELLINGPRICE?.toDouble() ?? 0,
          'user': userBloc.currentUser?.uSERHEDUSERCODE ?? "Unauthorized",
          'loc': POSConfig().locCode
        }));
    if (res?.statusCode == 200) {
      EasyLoading.showSuccess('product_view.success_reorder'.tr());
    }
  }

  Future<List<Product>> getWeightedProducts(
      String groupNo, String groupCode) async {
    final res = await ApiClient.call(
        "products/weighted?loc=${POSConfig().locCode}&groupCode=$groupCode&groupNo=$groupNo",
        ApiMethod.GET);
    if (res == null || res.data == null) return [];
    final List<dynamic> products = res.data?["products"] ?? [];
    return products.map((e) => Product.fromJson(e)).toList();
  }

  Future<List<LocationStocks>> getLocationWiseStock(String code) async {
    final res = await ApiClient.call("products/stock/$code", ApiMethod.GET,
        overrideUrl: '${POSConfig().setup?.centralPOSServer}/api/');
    if (res == null || res.data == null || res.statusCode != 200) return [];
    return LocationWiseStockResult.fromJson(res.data).stocks ?? [];
  }

  Future<List<ProVariant>> getLocationWiseVariantStock(String code) async {
    final res = await ApiClient.call("products/variant/$code", ApiMethod.GET,
        overrideUrl:
            '${POSConfig().setup?.centralPOSServer?.replaceFirst('/api/', '')}/api/');
    if (res == null || res.data == null || res.statusCode != 200) return [];
    return LocationWiseVariantStockResult.fromJson(res.data).stocks ?? [];
  }

  Future<Map<String, dynamic>?> getWeightedProductByID(String code) async {
    final res = await ApiClient.call(
        "products/weighted/quick_search?loc=${POSConfig().locCode}&code=$code&priceMode=${cartBloc.cartSummary?.priceMode ?? ''}",
        ApiMethod.GET);
    if (res == null || res.data == null) return null;
    final group = res.data["group"];
    final product = res.data["product"];
    if (product == null || group == null)
      return null;
    else {
      return {
        "group": Groups.fromJson(group),
        "product": Product.fromJson(product),
      };
    }
  }

  Future<List> getStockInHandDetails(List<Map<String, dynamic>> proList) async {
    var data = Map<String, dynamic>.from(
        {"location": POSConfig().locCode, "items": proList});
    final res = await ApiClient.call(
        "products/check_stock", data: data, ApiMethod.POST);
    if (res?.statusCode == 200 && res?.data != null) {
      return res?.data['stock_details'] ?? [];
    }
    return [];
  }
}
