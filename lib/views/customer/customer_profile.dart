/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Chathura Priyashad
 * Created At: 4/27/21, 5:31 PM
 */

/*
 * Copyright © 2021 myPOS Software Solutions.  All rights reserved.
 * Editor: TM.sakir
 * Editted At: 9/13/23, 12.25 PM
 * 
 * changes: 1. Added controller(line:84) to Datepicker field in order to show correct dob (previously it only shows the current date) & assigned value to doBEditingController(line:169)
 *          2. change the package for area dropdown field & related changes(line:173,509,1462) & added a textElement when editable = false (line: 564)
 */

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/bloc/area_bloc.dart';
import 'package:checkout/bloc/customer_group_bloc.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/components/ext_loyalty/ext_module_customer.dart';
import 'package:checkout/components/ext_loyalty/ext_module_helper.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/controllers/customer_controller.dart';
import 'package:checkout/controllers/keyboard_controller.dart';
import 'package:checkout/controllers/pos_alerts/pos_alerts.dart';
import 'package:checkout/controllers/sms_controller.dart';
import 'package:checkout/controllers/otp_controller.dart';
import 'package:checkout/controllers/special_permission_handler.dart';
import 'package:checkout/extension/extensions.dart';
import 'package:checkout/models/loyalty/area_result.dart';
import 'package:checkout/models/loyalty/customer_group_result.dart';
import 'package:checkout/models/loyalty/customer_list_result.dart';
import 'package:checkout/models/loyalty/customer_loyalty_group_result.dart';
import 'package:checkout/models/loyalty/loyalty_summary.dart';
import 'package:checkout/models/loyalty/title_result.dart';
import 'package:checkout/models/pos/permission_code.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supercharged/supercharged.dart';
import 'package:easy_localization/easy_localization.dart';
import 'customer_helper.dart';

class CustomerProfile extends StatefulWidget {
  static const routeName = "customer_profile";
  final CustomerResult? customer;
  final LoyaltySummary? loyaltySummary;

  const CustomerProfile(this.customer, {this.loyaltySummary});

  @override
  _CustomerProfileState createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {
  bool activeAccount = true;
  bool loyaltyActive = true;
  bool phoneNumberVerified = false;
  bool? male;
  TextEditingController customerCodeEditingController = TextEditingController();
  TextEditingController firstNameEditingController = TextEditingController();
  TextEditingController lastNameEditingController = TextEditingController();
  TextEditingController address1EditingController = TextEditingController();
  TextEditingController address2EditingController = TextEditingController();
  TextEditingController areaEditingController = TextEditingController();
  TextEditingController customerGroupEditingController =
      TextEditingController();
  TextEditingController customerLoyaltyGroupEditingController =
      TextEditingController();
  TextEditingController mobileEditingController = TextEditingController();
  TextEditingController nicEditingController = TextEditingController();
  TextEditingController doBEditingController = TextEditingController();
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController _titleEditingController = TextEditingController();
  Area? selectedArea;
  CustomerGroupsList? _selectedGroup;
  CustomerLoyaltyGroupsList? _selectedLoyaltyGroup;
  Titles? _selectedTitles;
  final formKey = GlobalKey<FormState>();
  OTPController otpController = OTPController();
  String countryCode = '+94';
  File? pickedImage;
  Uint8List? pickedImageBytes;
  String? imagePath;
  bool editable = true;
  bool _ebill = false;
  bool _editableCustomerCode = false;
  String? _enteredOtp;
  String? _referenceNumber;
  String? phoneNoRegex;
  String? nicRegex;
  late ExtLoyaltyModuleHelper _loyaltyHelper;
  final ScrollController _scrollController = ScrollController();
  double _points = 0;

  @override
  void initState() {
    super.initState();
    _loyaltyHelper = ExtLoyaltyModuleHelper();
    _points = 0;
    _loadingAll();
    _loadLoyaltyPointsFromExtModule();
  }

  Future<void> _loadLoyaltyPointsFromExtModule() async {
    if (_loyaltyHelper.extLoyaltyModuleActive && widget.customer != null) {
      await _loyaltyHelper.pointBalance(widget.customer?.cMCODE ?? '');
    } else {
      _points = widget.loyaltySummary?.pOINTSUMMARY ?? 0;
    }
  }

  Future<void> _loadingAll() async {
    EasyLoading.show(status: 'please_wait'.tr());

    await areaBloc.getAreaList();
    final String? _autoCode = await CustomerController().generateCustomerCode();
    if (_autoCode != null && _autoCode.isNotEmpty) {
      _editableCustomerCode = false;
      customerCodeEditingController.text = _autoCode;
    } else {
      // _editableCustomerCode = true;
      _editableCustomerCode =
          false; //to permanantly disable customer code edition...also i remove validation
    }
    await customerGroupBloc.fetchAll();
    if (widget.customer != null) assignValues(widget.customer!);

    final validationRes = await CustomerController().getValidationResult();
    validationRes?.validation?.forEach((element) {
      String? regex = element.fVREGEX?.trim();
      switch (element.fVFIELDNAME?.toLowerCase()) {
        case "nic":
          nicRegex = regex;
          break;
        case "mobile":
          phoneNoRegex = regex;
          break;
      }
    });

    EasyLoading.dismiss();
    if (mounted) {
      setState(() {});
    }
  }

  void assignValues(CustomerResult customer) {
    _editableCustomerCode = false;
    customerCodeEditingController.text = customer.cMCODE ?? "";
    String name = customer.cMNAME ?? "";
    String firstName = name.split(" ").first;
    firstNameEditingController.text = firstName;
    lastNameEditingController.text = name.replaceFirst(firstName, "").trim();
    activeAccount = customer.cMACTIVE ?? false;
    loyaltyActive = customer.cMLOYALTY ?? false;
    address1EditingController.text = customer.cMADD1 ?? "";
    address2EditingController.text = customer.cMADD2 ?? "";
    mobileEditingController.text =
        customer.cMMOBILE?.replaceAll("+94", "") ?? "";
    nicEditingController.text = customer.cMNIC ?? "";
    emailEditingController.text = customer.cMEMAIL ?? "";
    phoneNumberVerified = true;
    doBEditingController.text =
        DateFormat("yyyy-MM-dd").format(DateTime.parse(customer.cMDOB ?? ''));
    _ebill = customer.cMEBILL ?? false;
    areaEditingController.text = customer.aREADESC ?? "";
    editable = false;
    selectedArea = Area(
      aRCODE: customer.cMAREA,
      aRDESC: customer.aREADESC,
    );

    // going through all area codes all
    final loyaltyIndex = customerGroupBloc.loyaltyGroupList.indexWhere(
        (element) =>
            element.cLCODE == customer.loyaltyGroup &&
            customer.loyaltyGroup != null);
    final groupIndex = customerGroupBloc.customerGroupList.indexWhere(
        (element) =>
            element.cGCODE == customer.cusGroup && customer.cusGroup != null);
    final titleIndex = customerGroupBloc.customerTitleList.indexWhere(
        (element) =>
            element.tTCODE == customer.title && customer.title != null);

    if (groupIndex != -1) {
      _selectedGroup = customerGroupBloc.customerGroupList[groupIndex];
    }
    if (loyaltyIndex != -1) {
      _selectedLoyaltyGroup = customerGroupBloc.loyaltyGroupList[loyaltyIndex];
    }
    if (titleIndex != -1) {
      _selectedTitles = customerGroupBloc.customerTitleList[titleIndex];
    }

    if (customer.cMPICTURE != null) {
      String imageUrl = POSConfig().loyaltyServerImage + customer.cMPICTURE!;
      imagePath = imageUrl;
    }

    String gender = customer.gender ?? "";
    switch (gender.toLowerCase()) {
      case "m":
        male = true;
        break;
      case "f":
        male = false;
        break;
      default:
        male = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final containerWidth = POSConfig().containerSize.w;
    return POSBackground(
        child: Scaffold(
      body: Form(
        key: formKey,
        child: Column(
          children: [
            Center(
              child: Container(
                width: containerWidth,
                child: Column(
                  children: [
                    SizedBox(
                      height: POSConfig().topMargin.h,
                    ),
                    POSAppBar(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, top: 8.0, right: 15.0),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: containerWidth,
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: elementTitle((widget.customer == null
                                          ? "customer_profile.customer_registration"
                                          : "customer_profile.customer_profile")
                                      .tr())),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement('customer_profile.code'.tr()),
                                  textElement(
                                    '',
                                    4,
                                    customerCodeEditingController,
                                    disabled: !_editableCustomerCode,
                                    validator: (String? text) {
                                      return null;
                                    
                                      // return validateEmpty(
                                      //   text,
                                      //   "customer_code_error",
                                      //   !_editableCustomerCode,
                                      // );
                                    },
                                    onTap: _editableCustomerCode
                                        ? () {
                                            KeyBoardController().dismiss();
                                            KeyBoardController().init(context);
                                            KeyBoardController()
                                                .showBottomDPKeyBoard(
                                                    customerCodeEditingController,
                                                    onEnter: () {
                                              KeyBoardController().dismiss();
                                            });
                                          }
                                        : null,
                                  ),
                                  activeButtonElement(
                                      'customer_profile.active'.tr(),
                                      activeAccount, () {
                                    if (mounted && editable)
                                      setState(() {
                                        activeAccount = true;
                                      });
                                  }),
                                  inactiveButtonElement(
                                      'customer_profile.inactive'.tr(),
                                      !activeAccount, () {
                                    if (mounted && editable)
                                      setState(() {
                                        activeAccount = false;
                                      });
                                  }),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement(
                                      'customer_profile.loyalty_status'.tr()),
                                  SizedBox(
                                    width: 8.w,
                                  ),
                                  activeButtonElement(
                                      'customer_profile.active'.tr(),
                                      loyaltyActive, () {
                                    if (mounted && editable)
                                      setState(() {
                                        loyaltyActive = true;
                                      });
                                  }),
                                  inactiveButtonElement(
                                      'customer_profile.inactive'.tr(),
                                      !loyaltyActive, () {
                                    if (mounted && editable)
                                      setState(() {
                                        loyaltyActive = false;
                                      });
                                  }),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement('customer_profile.title'.tr()),
                                  StreamBuilder(
                                    stream:
                                        customerGroupBloc.customerTitleSnapshot,
                                    builder: (BuildContext context,
                                        AsyncSnapshot<List<Titles>> snapshot) {
                                      if (!snapshot.hasData)
                                        return textElement(
                                            '', 14, _titleEditingController);

                                      final data = snapshot.data;
                                      // // Initialize _selectedTitles with the initial selected value
                                      // if (_selectedTitles == null &&
                                      //     data!.isNotEmpty) {
                                      //   _selectedTitles = data[
                                      //       0]; // Set the first item as the initial selected value
                                      // }
                                      print(data.toString());
                                      return wrapper(
                                        width: 14 * 0.75,
                                        child: Theme(
                                          data: CurrentTheme.themeData!
                                              .copyWith(
                                                  primaryColor:
                                                      CurrentTheme.primaryColor,
                                                  textTheme: TextTheme(
                                                    titleMedium: CurrentTheme
                                                        .bodyText2!
                                                        .copyWith(
                                                            color: CurrentTheme
                                                                .primaryColor,
                                                            fontSize: 15.sp),
                                                  )),
                                          child: DropdownSearch<Titles>(
                                            popupProps: PopupProps.menu(),
                                            selectedItem: _selectedTitles,
                                            enabled: editable,
                                            dropdownDecoratorProps:
                                                DropDownDecoratorProps(
                                              baseStyle: TextStyle(
                                                  color:
                                                      CurrentTheme.primaryColor,
                                                  fontSize: 14.sp),
                                              dropdownSearchDecoration:
                                                  InputDecoration(
                                                filled: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 15),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              _titleEditingController.text =
                                                  value?.tTCODE ?? "";
                                              _selectedTitles = value;
                                              setState(() {});
                                            },
                                            compareFn: (item, selectedItem) =>
                                                item.tTCODE ==
                                                selectedItem.tTCODE,
                                            items: data ?? [],
                                            itemAsString: (item) =>
                                                item.tTDESC ?? "",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement(
                                      'customer_profile.first_name'.tr()),
                                  textElement(
                                    '',
                                    14,
                                    firstNameEditingController,
                                    validator: (String? text) {
                                      return validateEmpty(
                                          text, "first_name_error", true);
                                    },
                                    onTap: () {
                                      KeyBoardController().dismiss();
                                      KeyBoardController().init(context);
                                      KeyBoardController().showBottomDPKeyBoard(
                                          firstNameEditingController,
                                          onEnter: () {
                                        KeyBoardController().dismiss();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement(
                                      'customer_profile.last_name'.tr()),
                                  textElement(
                                    '',
                                    14,
                                    lastNameEditingController,
                                    // validator: (String? text) {
                                    //   return validateEmpty(
                                    //       text, "last_name_error", true);
                                    // },
                                    onTap: () {
                                      KeyBoardController().dismiss();
                                      KeyBoardController().init(context);
                                      KeyBoardController().showBottomDPKeyBoard(
                                          lastNameEditingController,
                                          onEnter: () {
                                        KeyBoardController().dismiss();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement('customer_profile.address'.tr()),
                                  textElement(
                                    '',
                                    14,
                                    address1EditingController,
                                    // validator: (String? text) {
                                    //   return validateEmpty(
                                    //       text,
                                    //       "address1_error",
                                    //       POSConfig().requiredAddress);
                                    // },
                                    onTap: () {
                                      KeyBoardController().dismiss();
                                      KeyBoardController().init(context);
                                      KeyBoardController().showBottomDPKeyBoard(
                                          address1EditingController,
                                          onEnter: () {
                                        KeyBoardController().dismiss();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  nullLabelElement(''),
                                  textElement(
                                    '',
                                    14,
                                    address2EditingController,
                                    onTap: () {
                                      KeyBoardController().dismiss();
                                      KeyBoardController().init(context);
                                      KeyBoardController().showBottomDPKeyBoard(
                                          address2EditingController,
                                          onEnter: () {
                                        KeyBoardController().dismiss();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement('customer_profile.area'.tr()),
                                  editable
                                      ? StreamBuilder(
                                          stream: areaBloc.areaListSnapshot,
                                          builder: (BuildContext context,
                                              AsyncSnapshot<List<Area>>
                                                  snapshot) {
                                            if (!snapshot.hasData)
                                              return textElement('', 14,
                                                  areaEditingController);

                                            final data = snapshot.data;

                                            return wrapper(
                                              width: 14 * 0.75,
                                              child: Theme(
                                                  data: CurrentTheme.themeData!
                                                      .copyWith(
                                                          primaryColor:
                                                              CurrentTheme
                                                                  .primaryColor,
                                                          textTheme: TextTheme(
                                                            titleMedium: CurrentTheme
                                                                .bodyText2!
                                                                .copyWith(
                                                                    color: CurrentTheme
                                                                        .primaryColor,
                                                                    fontSize:
                                                                        15.sp),
                                                          )),

                                                  /*
                                                  editor: TM.Sakir
                                                  reason for the change: archieving searchable dropdown menu
                                                   */
                                                  child: cityDropdown(
                                                      data) //new change

                                                  // DropdownSearch<Area>(
                                                  //   selectedItem: selectedArea,
                                                  //   enabled: editable,
                                                  //   dropdownDecoratorProps:
                                                  //       DropDownDecoratorProps(
                                                  //     baseStyle: TextStyle(
                                                  //         color:
                                                  //             CurrentTheme.primaryColor,
                                                  //         fontSize: 14.sp),
                                                  //     dropdownSearchDecoration:
                                                  //         InputDecoration(
                                                  //       filled: true,
                                                  //       contentPadding:
                                                  //           EdgeInsets.symmetric(
                                                  //               horizontal: 15),
                                                  //     ),
                                                  //   ),
                                                  //   onChanged: (value) {
                                                  //     areaEditingController.text =
                                                  //         value?.aRDESC ?? "";
                                                  //     selectedArea = value;
                                                  //     setState(() {});
                                                  //   },
                                                  //   compareFn: (item, selectedItem) =>
                                                  //       item.aRCODE ==
                                                  //       selectedItem.aRCODE,
                                                  //   items: data ?? [],
                                                  //   itemAsString: (item) =>
                                                  //       item.aRDESC ?? "",
                                                  // ),
                                                  ),
                                            );
                                          },
                                        )
                                      : textElement(
                                          '',
                                          14,
                                          areaEditingController,
                                          // validator: (String? text) {
                                          //   return validateEmpty(
                                          //       text,
                                          //       "address1_error",
                                          //       POSConfig().requiredAddress);
                                          // },
                                        ),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement(
                                      'customer_profile.customer_group'.tr()),
                                  StreamBuilder(
                                    stream:
                                        customerGroupBloc.customerGroupSnapshot,
                                    builder: (BuildContext context,
                                        AsyncSnapshot<List<CustomerGroupsList>>
                                            snapshot) {
                                      if (!snapshot.hasData)
                                        return textElement('', 14,
                                            customerGroupEditingController);

                                      final data = snapshot.data;
                                      return wrapper(
                                        width: 14 * 0.75,
                                        child: Theme(
                                          data: CurrentTheme.themeData!
                                              .copyWith(
                                                  primaryColor:
                                                      CurrentTheme.primaryColor,
                                                  textTheme: TextTheme(
                                                    titleMedium: CurrentTheme
                                                        .bodyText2!
                                                        .copyWith(
                                                            color: CurrentTheme
                                                                .primaryColor,
                                                            fontSize: 15.sp),
                                                  )),
                                          child: DropdownSearch<
                                              CustomerGroupsList>(
                                            selectedItem: _selectedGroup,
                                            enabled: editable,
                                            dropdownDecoratorProps:
                                                DropDownDecoratorProps(
                                              baseStyle: TextStyle(
                                                  color:
                                                      CurrentTheme.primaryColor,
                                                  fontSize: 14.sp),
                                              dropdownSearchDecoration:
                                                  InputDecoration(
                                                filled: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 15),
                                              ),
                                            ),
                                            onChanged: (value) async {
                                              if (value != null &&
                                                  (value.cGPERMISSIONREQUIRED ??
                                                      false) &&
                                                  (value.cG_MENUTAG ?? '')
                                                      .isNotEmpty) {
                                                final res =
                                                    await SpecialPermissionHandler(
                                                            context: context)
                                                        .askForPermission(
                                                            permissionCode:
                                                                value
                                                                    .cG_MENUTAG,
                                                            accessType: 'A',
                                                            refCode: DateTime
                                                                    .now()
                                                                .toIso8601String());
                                                if (res.success != true) {
                                                  _selectedGroup =
                                                      _selectedGroup;
                                                  customerGroupEditingController
                                                          .text =
                                                      _selectedGroup?.cGDESC ??
                                                          "";
                                                } else {
                                                  customerGroupEditingController
                                                          .text =
                                                      value.cGDESC ?? "";
                                                  _selectedGroup = value;
                                                }
                                                ;
                                              } else {
                                                customerGroupEditingController
                                                    .text = value?.cGDESC ?? "";
                                                _selectedGroup = value;
                                              }

                                              setState(() {});
                                            },
                                            compareFn: (item, selectedItem) =>
                                                item.cGCODE ==
                                                selectedItem.cGCODE,
                                            items: data ?? [],
                                            itemAsString: (item) =>
                                                item.cGDESC ?? "",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement(
                                      'customer_profile.loyalty_group'.tr()),
                                  StreamBuilder(
                                    stream:
                                        customerGroupBloc.loyaltyGroupSnapshot,
                                    builder: (BuildContext context,
                                        AsyncSnapshot<
                                                List<CustomerLoyaltyGroupsList>>
                                            snapshot) {
                                      if (!snapshot.hasData)
                                        return textElement('', 14,
                                            customerLoyaltyGroupEditingController);

                                      final data = snapshot.data;
                                      return wrapper(
                                        width: 14 * 0.75,
                                        child: Theme(
                                          data: CurrentTheme.themeData!
                                              .copyWith(
                                                  primaryColor:
                                                      CurrentTheme.primaryColor,
                                                  textTheme: TextTheme(
                                                    titleMedium: CurrentTheme
                                                        .bodyText2!
                                                        .copyWith(
                                                            color: CurrentTheme
                                                                .primaryColor,
                                                            fontSize: 15.sp),
                                                  )),
                                          child: DropdownSearch<
                                              CustomerLoyaltyGroupsList>(
                                            selectedItem: _selectedLoyaltyGroup,
                                            enabled: editable,
                                            dropdownDecoratorProps:
                                                DropDownDecoratorProps(
                                              baseStyle: TextStyle(
                                                  color:
                                                      CurrentTheme.primaryColor,
                                                  fontSize: 14.sp),
                                              dropdownSearchDecoration:
                                                  InputDecoration(
                                                filled: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 15),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              customerLoyaltyGroupEditingController
                                                  .text = value?.cLDESC ?? "";
                                              _selectedLoyaltyGroup = value;
                                              setState(() {});
                                            },
                                            compareFn: (item, selectedItem) =>
                                                item.cLCODE ==
                                                selectedItem.cLCODE,
                                            items: data ?? [],
                                            itemAsString: (item) =>
                                                item.cLDESC ?? "",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement('customer_profile.mobile'.tr()),
                                  CountryCodePicker(
                                    backgroundColor: CurrentTheme.primaryColor,
                                    boxDecoration: BoxDecoration(
                                        color: CurrentTheme.primaryColor),
                                    textStyle: TextStyle(
                                        color: CurrentTheme.primaryLightColor),

                                    onChanged: (value) {
                                      setState(() {
                                        countryCode = value.dialCode ?? '+94';
                                      });
                                    },
                                    initialSelection: countryCode,
                                    favorite: [
                                      '+94',
                                      '+960',
                                      '+86',
                                      '+880',
                                      '+975',
                                      '+91',
                                      '+975',
                                      '+92'
                                    ],
                                    // optional. Shows only country name and flag
                                    showCountryOnly: false,
                                  ),
                                  textElement(
                                    '',
                                    8.5,
                                    mobileEditingController,
                                    inputFormatter: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    validator: (String? text) {
                                      String? res = validateEmpty(
                                          text, "mobile_error", true);
                                      if (res == null) {
                                        // if (!phoneNumberVerified &&
                                        //     POSConfig().otpEnabled)
                                        //   return "customer_profile.number_not_verify"
                                        //       .tr();
                                        return null;
                                      }
                                      return res;
                                    },
                                    onTap: () {
                                      KeyBoardController().dismiss();
                                      KeyBoardController().init(context);
                                      KeyBoardController().showBottomDPKeyBoard(
                                          mobileEditingController, onEnter: () {
                                        KeyBoardController().dismiss();
                                      });
                                    },
                                  ),
                                  (phoneNumberVerified)
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(right: 15),
                                          child: Icon(Icons.verified_outlined),
                                        )
                                      : SizedBox.shrink(),
                                  !POSConfig().otpEnabled
                                      ? SizedBox.shrink()
                                      : activeButtonElement(
                                          'customer_profile.verify'.tr(), true,
                                          () async {
                                          if (phoneNoRegex != null) {
                                            if (!RegExp(phoneNoRegex!).hasMatch(
                                                mobileEditingController.text)) {
                                              EasyLoading.showError(
                                                  'Invalid Phone number');
                                              return;
                                            }
                                          }

                                          //check external modules available or not
                                          if (!_loyaltyHelper
                                              .extLoyaltyModuleActive) {
                                            final otp =
                                                otpController.generateOTP();
                                            await SMSController().sendOTP(
                                                mobileEditingController.text,
                                                otp);
                                            await otpController.verifyOTP(
                                                context,
                                                cusCode:
                                                    customerCodeEditingController
                                                        .text,
                                                mobile: mobileEditingController
                                                    .text);
                                            setState(() {
                                              phoneNumberVerified =
                                                  otpController.validOtp;
                                            });
                                          } else {
                                            String? referenceNumber =
                                                await _loyaltyHelper
                                                    .registrationRequest(
                                                        _toExtModuleCustomer());
                                            if ((referenceNumber ?? '')
                                                .isNotEmpty) {
                                              _referenceNumber =
                                                  referenceNumber;
                                              _enteredOtp = await otpController
                                                  .enter3rdPartyOTP(context);
                                              phoneNumberVerified = true;
                                              setState(() {});
                                            }
                                          }
                                        }),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement('customer_profile.nic'.tr()),
                                  textElement(
                                    '',
                                    14,
                                    nicEditingController,
                                    validator: (String? text) {
                                      if (nicRegex != null) {
                                        if (RegExp(nicRegex!)
                                            .hasMatch(text ?? '')) {
                                          return null;
                                        } else {
                                          return 'customer_profile.nic_error'
                                              .tr();
                                        }
                                      }
                                      return null;
                                    },
                                    onTap: () {
                                      KeyBoardController().dismiss();
                                      KeyBoardController().init(context);
                                      KeyBoardController().showBottomDPKeyBoard(
                                          nicEditingController, onEnter: () {
                                        KeyBoardController().dismiss();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement('customer_profile.dob'.tr()),
                                  wrapper(
                                    width: 5.5,
                                    child: Theme(
                                      data: CurrentTheme.themeData!.copyWith(
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: CurrentTheme
                                                .primaryLightColor, // button text color
                                          ),
                                        ),
                                      ),
                                      child: DateTimeField(
                                        controller: doBEditingController,
                                        enabled: editable,
                                        format: DateFormat("yyyy-MM-dd"),
                                        initialValue: doBEditingController
                                                .text.isEmpty
                                            ? DateTime.now()
                                            : DateFormat("yyyy-MM-dd").parse(
                                                doBEditingController.text),
                                        style: TextStyle(
                                            color: CurrentTheme.primaryColor,
                                            fontSize: 14.sp),
                                        decoration: InputDecoration(
                                          filled: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 15),
                                        ),
                                        onShowPicker:
                                            (context, currentValue) async {
                                          final date = await showDatePicker(
                                              context: context,
                                              firstDate: DateTime(1900),
                                              initialDate: currentValue ??
                                                  DateTime.now(),
                                              locale:
                                                  EasyLocalization.of(context)!
                                                      .locale,
                                              lastDate: DateTime.now());
                                          if (date != null)
                                            doBEditingController.text =
                                                DateFormat("yyyy-MM-dd")
                                                    .format(date);
                                          setState(() {});
                                          return date;
                                        },
                                      ),
                                    ),
                                  ),
                                  labelElement('customer_profile.gender'.tr()),
                                  wrapper(
                                    width: 5.5,
                                    child: Row(
                                      children: [
                                        Radio(
                                            value: true,
                                            groupValue: male,
                                            onChanged: (bool? val) {
                                              setState(() {
                                                male = val;
                                              });
                                            }),
                                        Text(
                                          "customer_profile.male".tr(),
                                          style: TextStyle(fontSize: 14.sp),
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Radio(
                                            value: false,
                                            groupValue: male,
                                            onChanged: (bool? val) {
                                              setState(() {
                                                male = val;
                                              });
                                            }),
                                        Text("customer_profile.female".tr(),
                                            style: TextStyle(fontSize: 14.sp)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Container(
                              width: containerWidth * 1.5,
                              child: Row(
                                children: [
                                  labelElement('customer_profile.email'.tr()),
                                  textElement(
                                    '',
                                    8,
                                    emailEditingController,
                                    // validator: (String? text) {
                                    //   String? res = validateEmpty(
                                    //       text,
                                    //       "email_error",
                                    //       POSConfig().requiredEmail);
                                    //   if (res == null &&
                                    //       POSConfig().requiredEmail) {
                                    //     final regExp = RegExp(
                                    //         r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
                                    //     if (regExp.hasMatch(text!)) {
                                    //       return null;
                                    //     } else {
                                    //       return "customer_profile.email_error"
                                    //           .tr();
                                    //     }
                                    //   } else
                                    //     return res;
                                    // },
                                    onTap: () {
                                      KeyBoardController().dismiss();
                                      KeyBoardController().init(context);
                                      KeyBoardController().showBottomDPKeyBoard(
                                          emailEditingController, onEnter: () {
                                        KeyBoardController().dismiss();
                                      });
                                    },
                                  ),
                                  if (emailEditingController.text.isNotEmpty)
                                    Row(
                                      children: [
                                        labelElement(
                                            'customer_profile.ebill'.tr()),
                                        activeButtonElement(
                                            'customer_profile.yes'.tr(), _ebill,
                                            () {
                                          if (mounted && editable)
                                            setState(() {
                                              _ebill = true;
                                            });
                                        }),
                                        inactiveButtonElement(
                                            'customer_profile.no'.tr(), !_ebill,
                                            () {
                                          if (mounted && editable)
                                            setState(() {
                                              _ebill = false;
                                            });
                                        }),
                                      ],
                                    )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 25.h,
                            ),
                            Container(
                              width: containerWidth * 1.4,
                              child: Row(
                                children: [
                                  Expanded(
                                      child: appButton(() {
                                    if (mounted)
                                      setState(() {
                                        editable = true;
                                      });
                                  }, 'customer_profile.edit'.tr())),
                                  SizedBox(
                                    width: 15.w,
                                  ),
                                  Expanded(
                                      child: appButton(
                                          updateOrCreate,
                                          widget.customer == null
                                              ? 'customer_profile.create'.tr()
                                              : 'customer_profile.update'
                                                  .tr())),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 50.h,
                            ),
                          ],
                        ),
                        Positioned(
                          top: 150.h,
                          right: 0,
                          child: Column(
                            children: [
                              Container(
                                width: 120.w,
                                child: Center(
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Card(
                                        shape: CircleBorder(),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              ScreenUtil().screenWidth * 500),
                                          child: Image(
                                            image: customerImage(),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                          bottom: 20,
                                          child:
                                              imagePickerSupportedPlatform() &&
                                                      editable
                                                  ? TextButton(
                                                      onPressed: pickImage,
                                                      child: Text(
                                                          "Change Picture"))
                                                  : SizedBox.shrink()),
                                    ],
                                  ),
                                ),
                              ),
                              if (widget.customer == null)
                                SizedBox.shrink()
                              else
                                notificationElement(
                                    "${_points.toStringAsFixed(2)}",
                                    DateFormat("dd-MM-yyyy").format(now),
                                    DateFormat("hh:mm aa").format(now),
                                    '${widget.loyaltySummary?.lASTVISIT ?? "N/A"}',
                                    '${widget.loyaltySummary?.aVGBILL?.toStringAsFixed(2) ?? 0}',
                                    '${widget.loyaltySummary?.tOTALBILL?.toStringAsFixed(2) ?? 0}')
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    ));
  }

  ImageProvider customerImage() {
    if (pickedImageBytes != null) return MemoryImage(pickedImageBytes!);
    if (imagePath != null) //EasyLoading.showError(imagePath.toString());
      return CachedNetworkImageProvider(imagePath!,
          headers: {'Access-Control-Allow-Origin': '*'});
    return AssetImage("assets/images/default_male.png");
  }

  bool imagePickerSupportedPlatform() {
    if (kIsWeb) return true;
    if (Platform.isAndroid) return true;
    if (Platform.isIOS)
      return true;
    else
      return false;
  }

  Future pickImage() async {
    final _picker = ImagePicker();
    // PickedFile? pickedFile =
    //     await _picker.getImage(source: ImageSource.gallery);
    var pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      pickedImageBytes = await pickedFile.readAsBytes();
      setState(() {
        pickedImage = File(pickedFile.path);
      });
      return;
    }
  }

  String? validateEmpty(String? text, String key, bool required) {
    if (required && (text ?? "").isEmpty)
      return "customer_profile.$key".tr();
    else
      return null;
  }

  Future updateOrCreate() async {
    bool permission = false;
    final helper = CustomerHelper(context);
    if (widget.customer == null) {
      //  check for create permission
      permission = await helper.hasCustomerMasterPermission("C");
    } else {
      permission = await helper.hasCustomerMasterPermission("M");
    }
    bool otpValidationRes = phoneNumberVerified;
    if (!phoneNumberVerified) {
      otpValidationRes = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('customer_profile.skip_otp'.tr()),
          actions: [
            AlertDialogButton(
                onPressed: () => Navigator.pop(context, false),
                text: 'cancel'.tr()),
            AlertDialogButton(
                onPressed: () async {
                  EasyLoading.show(status: 'please_wait'.tr());
                  SpecialPermissionHandler handler =
                      SpecialPermissionHandler(context: context);
                  bool permissionStatus = handler.hasPermission(
                      permissionCode: PermissionCode.skipOtpForRegistration,
                      accessType: 'A',
                      refCode:
                          '${customerCodeEditingController.text}@${mobileEditingController.text}');
                  if (!permissionStatus) {
                    final permission = await handler.askForPermission(
                        permissionCode: PermissionCode.skipOtpForRegistration,
                        accessType: "A",
                        refCode:
                            '${customerCodeEditingController.text}@${mobileEditingController.text}');
                    if (permission.success) {
                      Navigator.pop(context, true);
                    } else {
                      EasyLoading.showError('Action revoked');
                      Navigator.pop(context, false);
                    }
                  } else {
                    Navigator.pop(context, true);
                  }
                  EasyLoading.dismiss();
                },
                text: 'skip&continue'.tr()),
          ],
        ),
      );
    }
    //true if the data is valid
    if (permission &&
        editable &&
        formKey.currentState!.validate() &&
        otpValidationRes) {
      // get customer code again
      if (!_editableCustomerCode && widget.customer == null) {
        final String currentCode = customerCodeEditingController.text;
        final String? newCode =
            await CustomerController().generateCustomerCode();
        if (currentCode != newCode) {
          customerCodeEditingController.text = newCode ?? '';
          bool? alertRes = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('customer_profile.code_used'.tr(namedArgs: {
                'code': newCode ?? '',
              })),
              actions: [
                AlertDialogButton(
                    onPressed: () => Navigator.pop(context, false),
                    text: 'customer_profile.no'.tr()),
                AlertDialogButton(
                    onPressed: () => Navigator.pop(context, true),
                    text: 'customer_profile.yes'.tr()),
              ],
            ),
          );
          alertRes ??= false;
          if (!alertRes) {
            return;
          }
        }
      }

      final Map<String, dynamic> data = _toExtModuleCustomer().toJson();
      EasyLoading.show(status: 'please_wait'.tr());

      var res = await CustomerController()
          .createOrUpdateCustomer(data, widget.customer != null);

      if (widget.customer == null && _loyaltyHelper.extLoyaltyModuleActive) {
        try {
          await _loyaltyHelper.registerCustomer(_toExtModuleCustomer());
        } on Exception catch (e) {
          EasyLoading.dismiss();
          EasyLoading.showError(e.toString());
        }
      }
      EasyLoading.dismiss();

      if (res != null) {
        if (pickedImageBytes != null)
          await CustomerController()
              .updateCustomerImage(res, pickedImageBytes!);
        customerCodeEditingController.clear();
        firstNameEditingController.clear();
        lastNameEditingController.clear();
        address1EditingController.clear();
        address2EditingController.clear();
        selectedArea = null;
        nicEditingController.clear();
        mobileEditingController.clear();
        emailEditingController.clear();
        male = false;
        Navigator.pop(context);
      }
    }
  }

  Widget elementTitle(text) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        child: Row(
          children: [
            SizedBox(
              width: 15.r,
            ),
            GoBackIconButton(),
            Spacer(),
            Text(
              text,
              style: CurrentTheme.subtitle1!
                  .copyWith(color: CurrentTheme.primaryColor),
              textAlign: TextAlign.center,
            ),
            Spacer()
          ],
        ),
      ),
    );
  }

  ExtModuleCustomer _toExtModuleCustomer() {
    final Map<String, dynamic> data = {
      'mobile': countryCode + mobileEditingController.text.trim(),
      'mobile_entered': mobileEditingController.text.trim(),
      'code': customerCodeEditingController.text.trim(),
      'firstName': firstNameEditingController.text.trim(),
      'lastName': lastNameEditingController.text.trim(),
      'nic': nicEditingController.text.trim(),
      'address1': address1EditingController.text.trim(),
      'address2': address2EditingController.text.trim(),
      'email': emailEditingController.text.trim(),
      'dob': doBEditingController.text.trim(),
      'gender': male == null
          ? null
          : male!
              ? 'M'
              : 'F',
      'areaCode': selectedArea?.aRCODE,
      // 'autoIncrementCode': _editableCustomerCode ? 0 : 1,
      //'autoIncrementCode': _editableCustomerCode ? 1 : 0,
      'autoIncrementCode': customerCodeEditingController.text == "" ? 1 : 0,
      'user': userBloc.currentUser?.uSERHEDUSERCODE,
      'active': activeAccount ? 1 : 0,
      "loyalty": loyaltyActive ? 1 : 0,
      'ebill': _ebill ? 1 : 0,
      'loyaltyGroup': _selectedLoyaltyGroup?.cLCODE ?? '',
      'group': _selectedGroup?.cGCODE ?? '',
      'location': POSConfig().setupLocation,
      'title': _selectedTitles?.tTCODE ?? '',
      'referenceNumber': _referenceNumber,
      'enteredOtp': _enteredOtp
    };

    return ExtModuleCustomer.fromJson(data);
  }

  Container notificationElement(point, date, time, lastDate, avg, total) {
    final containerWidth = 250.w;
    final textWidth = 200.w;
    return Container(
      width: containerWidth,
      height: 380.h,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 5.r),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(
            children: [
              Spacer(),
              SizedBox(
                width: textWidth,
                child: Text(
                  'Point as at',
                  style: CurrentTheme.subtitle2!
                      .copyWith(color: CurrentTheme.primaryLightColor),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: textWidth,
                child: Text(
                  date,
                  style: CurrentTheme.subtitle2!
                      .copyWith(color: CurrentTheme.primaryLightColor),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: textWidth,
                child: Text(
                  time,
                  style: CurrentTheme.subtitle2!
                      .copyWith(color: CurrentTheme.primaryLightColor),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: textWidth,
                child: Text(
                  point.toString().parseDouble().toStringAsFixed(2),
                  style: CurrentTheme.headline2!.copyWith(
                      color: Colors.green, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: textWidth,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    'Last Visit on: ' +
                        lastDate.toString().replaceAll('T', ' '),
                    style: CurrentTheme.subtitle2!
                        .copyWith(color: CurrentTheme.primaryLightColor),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              SizedBox(
                width: textWidth,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    'Average Bill Value : ' + avg,
                    style: CurrentTheme.subtitle2!
                        .copyWith(color: CurrentTheme.primaryLightColor),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              SizedBox(
                width: textWidth,
                child: Text(
                  'Total Purchases : ' + total,
                  style: CurrentTheme.subtitle2!
                      .copyWith(color: CurrentTheme.primaryLightColor),
                  textAlign: TextAlign.right,
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Container labelElement(text) {
    final containerWidth = POSConfig().containerSize.w;
    return Container(
      width: (containerWidth) * 3.5 / 12,
      child: Card(
        color: CurrentTheme.primaryColor,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 20.w),
          child: Text(
            text,
            style: CurrentTheme.bodyText2!.copyWith(
                color: CurrentTheme.primaryLightColor, fontSize: 16.sp),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }

  Container nullLabelElement(text) {
    final containerWidth = POSConfig().containerSize.w;
    return Container(
      width: (containerWidth) * 3.5 / 12,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 20.w),
        child: Text(
          text,
          style: CurrentTheme.bodyText2!
              .copyWith(color: CurrentTheme.primaryLightColor),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget wrapper({required Widget child, required double width}) {
    final containerWidth = POSConfig().containerSize.w;
    return Container(
      width: containerWidth * width / 14,
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
      child: child,
    );
  }

  Widget textElement(
      String text, double width, TextEditingController controller,
      {bool disabled = false,
      StringToFunc? validator,
      VoidCallback? onTap,
      List<TextInputFormatter>? inputFormatter}) {
    return wrapper(
      width: width * 0.75,
      child: TextFormField(
        onTap: onTap,
        validator: validator,
        readOnly: disabled,
        textAlign: TextAlign.left,
        inputFormatters: inputFormatter,
        enabled: editable,
        style: CurrentTheme.bodyText2!
            .copyWith(color: CurrentTheme.primaryColor, fontSize: 14.sp),
        controller: controller,
        textInputAction: TextInputAction.next,
        onChanged: (String value) {
          if (mounted) setState(() {});
        },
        decoration: InputDecoration(
          filled: true,
          hintText: text,
          alignLabelWithHint: true,
          isDense: true,
          contentPadding: EdgeInsets.all(10),
        ),
      ),
    );
  }

  Container activeButtonElement(text, bool status, VoidCallback onPress) {
    // final containerWidth = POSConfig().containerSize .w;
    return Container(
      //width: containerWidth/12,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: ElevatedButton(
          onPressed: onPress,
          child: Text(text),
          style: ElevatedButton.styleFrom(
              backgroundColor: status ? Colors.green : Colors.white70,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              textStyle: TextStyle(
                  //fontSize: 30,
                  //fontWeight: FontWeight.bold
                  )),
        ),
      ),
    );
  }

  Container inactiveButtonElement(text, bool status, VoidCallback onPressed) {
    // final containerWidth = POSConfig().containerSize .w;
    return Container(
      //width: containerWidth/12,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 5.w),
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(text),
          style: ElevatedButton.styleFrom(
              backgroundColor: status ? Colors.red : Colors.white70,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              textStyle: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }

  Widget appButton(VoidCallback? onPressed, String? text) {
    if (onPressed != null && text != null)
      return Container(
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(
            text,
            textAlign: TextAlign.center,
          ),
          style: ElevatedButton.styleFrom(
              backgroundColor: POSConfig().primaryDarkGrayColor.toColor()),
        ),
      );
    else {
      return SizedBox.shrink();
    }
  }

  /*
  Author: TM.Sakir
  reason for the change: archieving searchable dropdown menu
  */
  DropdownButtonHideUnderline cityDropdown(List<Area>? area) {
    final config = POSConfig();
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        dropdownSearchData: DropdownSearchData(
          searchController: areaEditingController,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Container(
            height: 50,
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 4,
              right: 8,
              left: 8,
            ),
            child: TextFormField(
              expands: true,
              maxLines: null,
              controller: areaEditingController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                ),
                hintText: 'Search the city...',
                hintStyle: TextStyle(fontSize: 12.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value.toString().contains(searchValue
                .toUpperCase()); //item.toString().contains(searchValue);
          },
        ),
        //This to clear the search value when you close the menu
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            areaEditingController.clear();
          }
        },
        // hint: const Row(
        //   children: [
        //     Icon(
        //       Icons.list,
        //       size: 16,
        //       color: Colors.yellow,
        //     ),
        //     SizedBox(
        //       width: 4,
        //     ),
        //     Expanded(
        //       child: Text(
        //         '',
        //         style: TextStyle(
        //           fontSize: 14,
        //           fontWeight: FontWeight.bold,
        //           color: Colors.black,
        //         ),
        //         overflow: TextOverflow.ellipsis,
        //       ),
        //     ),
        //   ],
        // ),
        items: area!
            .map((e) => e.aRDESC)
            .toList()
            .map((String? item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item ?? '',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.normal,
                      color: CurrentTheme.primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        value: selectedArea?.aRDESC,
        onChanged: (value) {
          // areaEditingController.text = value?.aRDESC ?? "";
          // selectedArea = value;
          // setState(() {});
          setState(() {
            selectedArea =
                area.where((element) => element.aRDESC == value).first;
          });
        },
        buttonStyleData: ButtonStyleData(
          // height: MediaQuery.of(context).size.height * 0.06,
          width: MediaQuery.of(context).size.width * 0.25,
          padding: const EdgeInsets.only(left: 14, right: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(config.rounderBorderRadiusBottomLeft),
              bottomRight:
                  Radius.circular(config.rounderBorderRadiusBottomRight),
              topRight: Radius.circular(config.rounderBorderRadiusTopRight),
              topLeft: Radius.circular(config.rounderBorderRadiusTopLeft),
            ),
            color: Colors.white,
          ),
          // elevation: 2,
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          iconSize: 24,
          iconEnabledColor: Colors.grey,
          iconDisabledColor: Colors.grey,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: MediaQuery.of(context).size.height * 0.3,
          width: MediaQuery.of(context).size.width * 0.29,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
          ),
          // offset: const Offset(-20, 0),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: WidgetStateProperty.all<double>(6),
            thumbVisibility: WidgetStateProperty.all<bool>(true),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
          padding: EdgeInsets.only(left: 14, right: 14),
        ),
      ),
    );
  }
}
