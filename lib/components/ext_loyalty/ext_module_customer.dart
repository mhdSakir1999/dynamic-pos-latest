/*
 * Copyright © 2022 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 3/22/22, 6:06 PM
 */

class ExtModuleCustomer {
  String? mobile;
  String? mobileEntered;
  String? code;
  String? firstName;
  String? lastName;
  String? nic;
  String? address1;
  String? address2;
  String? email;
  String? dob;
  String? gender;
  String? areaCode;
  int? autoIncrementCode;
  String? user;
  int? active;
  int? loyalty;
  int? ebill;
  String? loyaltyGroup;
  String? group;
  String? location;
  String? title;
  int? enteredOtp;
  int? referenceNumber;

  ExtModuleCustomer(
      {this.mobile,
        this.code,
        this.firstName,
        this.lastName,
        this.nic,
        this.address1,
        this.address2,
        this.email,
        this.dob,
        this.gender,
        this.areaCode,
        this.autoIncrementCode,
        this.user,
        this.active,
        this.loyalty,
        this.ebill,
        this.loyaltyGroup,
        this.group,
        this.location,
        this.title,this.enteredOtp,this.referenceNumber});

  ExtModuleCustomer.fromJson(Map<String, dynamic> json) {
    mobile = json['mobile'];
    mobileEntered = json['mobile_entered'];
    code = json['code'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    nic = json['nic'];
    address1 = json['address1'];
    address2 = json['address2'];
    email = json['email'];
    dob = json['dob'];
    gender = json['gender'];
    areaCode = json['areaCode'];
    autoIncrementCode = json['autoIncrementCode'];
    user = json['user'];
    active = json['active'];
    loyalty = json['loyalty'];
    ebill = json['ebill'];
    loyaltyGroup = json['loyaltyGroup'];
    group = json['group'];
    location = json['location'];
    title = json['title'];
    enteredOtp = int.tryParse(json['customerPin']?.toString()??'');
    referenceNumber =int.tryParse(json['referenceNumber']?.toString()??'');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mobile'] = this.mobile;
    data['code'] = this.code;
    data['firstName'] = this.firstName;
    data['lastName'] = this.lastName;
    data['nic'] = this.nic;
    data['address1'] = this.address1;
    data['address2'] = this.address2;
    data['email'] = this.email;
    data['dob'] = this.dob;
    data['gender'] = this.gender;
    data['areaCode'] = this.areaCode;
    data['autoIncrementCode'] = this.autoIncrementCode;
    data['user'] = this.user;
    data['active'] = this.active;
    data['loyalty'] = this.loyalty;
    data['ebill'] = this.ebill;
    data['loyaltyGroup'] = this.loyaltyGroup;
    data['group'] = this.group;
    data['location'] = this.location;
    data['title'] = this.title;
    data['referenceNumber'] = this.referenceNumber;
    data['customerPin'] = this.enteredOtp;
    return data;
  }
}
