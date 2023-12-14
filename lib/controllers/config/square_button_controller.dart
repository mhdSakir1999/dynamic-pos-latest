/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/29/21, 3:18 PM
 */
import 'package:shared_preferences/shared_preferences.dart';

/// This controller class save the square buttons
class SquareButtonController {
  SharedPreferences _preferences;
  String _squareButtonTopLeftRadius = "square_button_top_left_radius";
  String _squareButtonTopRightRadius = "square_button_top_right_radius";
  String _squareButtonBottomLeftRadius = "square_button_bottom_left_radius";
  String _squareButtonBottomRightRadius = "square_button_bottom_right_radius";

  SquareButtonController(this._preferences);

  Future<double?> getSquareButtonTopLeftRadius() async {
    return _preferences.getDouble(_squareButtonTopLeftRadius);
  }

  Future<double?> getSquareButtonTopRightRadius() async {
    return _preferences.getDouble(_squareButtonTopRightRadius);
  }

  Future<double?> getSquareButtonBottomLeftRadius() async {
    return _preferences.getDouble(_squareButtonBottomLeftRadius);
  }

  Future<double?> getSquareButtonBottomRightRadius() async {
    return _preferences.getDouble(_squareButtonBottomRightRadius);
  }

  Future<bool> setSquareButtonTopLeftRadius(double radius) async {
    return await _preferences.setDouble(_squareButtonTopLeftRadius, radius);
  }

  Future<bool?> setSquareButtonTopRightRadius(double radius) async {
    return await _preferences.setDouble(_squareButtonTopRightRadius, radius);
  }

  Future<bool?> setSquareButtonBottomLeftRadius(double radius) async {
    return await _preferences.setDouble(_squareButtonBottomLeftRadius, radius);
  }

  Future<bool?> setSquareButtonBottomRightRadius(double radius) async {
    return await _preferences.setDouble(_squareButtonBottomRightRadius, radius);
  }
}
