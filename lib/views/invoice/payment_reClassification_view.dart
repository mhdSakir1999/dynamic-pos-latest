import 'package:checkout/components/current_theme.dart';
import 'package:checkout/components/widgets/go_back.dart';
import 'package:checkout/components/widgets/pos_background.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supercharged/supercharged.dart';

class PaymentReClassification extends StatefulWidget {
  const PaymentReClassification({super.key});

  @override
  State<PaymentReClassification> createState() =>
      _PaymentReClassificationState();
}

class _PaymentReClassificationState extends State<PaymentReClassification> {
  TextEditingController invController = TextEditingController();
  FocusNode invFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    invFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return POSBackground(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              goBackBar(),
              Row(
                children: [
                  Expanded(child: invoiceSearch()),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text('Re-Classify'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text('Save'),
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Colors.green[800])),
                    ),
                  )
                ],
              ),
              invDetailCard(),
              Expanded(flex: 1, child: paymentsCard('OLD PAYMENTS')),
              Expanded(flex: 1, child: paymentsCard('CLASSIFIED PAYMENTS'))
            ],
          ),
        ),
      ),
    );
  }

  Widget paymentsCard(String paymentLabel) {
    var labelStyle = TextStyle(
        fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black);
    final height = MediaQuery.of(context).size.height;
    return Container(
        width: double.infinity,
        height: height * 0.23,
        child: Card(
          color: CurrentTheme.primaryColor,
          child: Column(
            children: [
              Text(
                paymentLabel,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        flex: 1,
                        child: Text(
                          '#',
                          textAlign: TextAlign.center,
                          style: labelStyle,
                        )),
                    Expanded(
                        flex: 2,
                        child: Text('Payment Code',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 3,
                        child: Text('Payment Description',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 2,
                        child: Text('Detail Code',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 3,
                        child: Text('Detail Description',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 5,
                        child: Text('Card/Cheque Number',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 3,
                        child: Text('Cheque Date',
                            textAlign: TextAlign.center, style: labelStyle)),
                    Expanded(
                        flex: 3,
                        child: Text('Amount',
                            textAlign: TextAlign.center, style: labelStyle)),
                  ],
                ),
              ),
              SizedBox(
                height: height * 0.001,
              ),
              paymentList(),
              SizedBox(
                height: height * 0.001,
              ),
            ],
          ),
        ));
  }

  Widget paymentList() {
    final height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.15,
      child: ListView.builder(
          physics: BouncingScrollPhysics(),
          itemCount: 10,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                    color: CurrentTheme.backgroundColor,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    paymentRowValue(value: '1', flex: 1),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 2, value: '001'),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 3, value: 'Cash Payment'),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 2, value: 'CSH'),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 3, value: 'Cash'),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 5, value: '1111-11**-****-1111'),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 3, value: '05/12/2024'),
                    SizedBox(
                      width: 5,
                    ),
                    paymentRowValue(flex: 3, value: '12,000.00')
                  ],
                ),
              ),
            );
          }),
    );
  }

  Expanded paymentRowValue({int flex = 1, String value = '--'}) {
    var valueStyle = CurrentTheme.bodyText1!.copyWith(
        fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600);
    return Expanded(
        flex: flex,
        child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8))),
            child: Padding(
              padding: const EdgeInsets.only(left: 1.0, right: 1),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: valueStyle,
              ),
            )));
  }

  Widget invDetailCard() {
    return Container(
        width: double.infinity,
        child: Card(
          color: CurrentTheme.primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    invDetailRecords(
                      label: 'Date',
                      value: '12/05/2024',
                    ),
                    invDetailRecords(
                      label: 'Invoice Amount',
                      value: '1500.00',
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    invDetailRecords(
                      label: 'Terminal',
                      value: '003',
                    ),
                    invDetailRecords(
                      label: 'Cashier',
                      value: '4097',
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    invDetailRecords(
                      label: 'Location',
                      value: '00013',
                    ),
                    invDetailRecords(
                      label: 'Customer',
                      value: 'Mohamed Sakir',
                    ),
                  ],
                ),
                Row(
                  children: [
                    invDetailRecords(
                      label: 'Remarks',
                      value: 'abcdefghijklmnopqrstuvwxyz',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget goBackBar() {
    return Container(
      width: double.infinity,
      child: Card(
        child: Row(
          children: [
            SizedBox(
              width: 15.r,
            ),
            GoBackIconButton(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
              child: Center(
                  child: Text(
                'Payment Re-Classification',
                style: CurrentTheme.bodyText2!
                    .copyWith(color: CurrentTheme.primaryColor),
              )),
            ),
            SizedBox(
              width: 15.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget invoiceSearch() {
    final textStyle = CurrentTheme.headline6!.copyWith(
        color: CurrentTheme.primaryLightColor, fontWeight: FontWeight.w600);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final config = POSConfig();
    return Container(
      width: width * 0.5,
      child: Card(
        color: CurrentTheme.primaryColor,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: Row(
                  children: [
                    Text(
                      'Invoice Number',
                      style: textStyle,
                    ),
                    SizedBox(
                      width: width * 0.05,
                    ),
                    Expanded(
                      child: Container(
                        height: height * 0.05,
                        child: TextField(
                          style: textStyle,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            contentPadding:
                                EdgeInsets.only(left: 10, right: 10),
                            border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.black, width: 2)),
                          ),
                          focusNode: invFocus,
                          autofocus: true,
                          controller: invController,
                          onEditingComplete: () {
                            EasyLoading.showInfo('Processing !!!');
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width * 0.02,
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      child: Container(
                        child: IconButton(
                            onPressed: () async {},
                            icon: Icon(
                              Icons.search,
                            )),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class invDetailRecords extends StatelessWidget {
  const invDetailRecords({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textStyle = CurrentTheme.bodyText1!.copyWith(
        color: CurrentTheme.primaryDarkColor, fontWeight: FontWeight.w600);
    return Expanded(
      flex: 1,
      child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 10.r),
          child: Row(
            children: [
              Container(
                  width: width * 0.15,
                  child:
                      Text(label.toUpperCase(), style: CurrentTheme.bodyText2)),
              SizedBox(
                width: width * 0.02,
                child: Text(':'),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    value,
                    style: textStyle,
                  ),
                ),
              )
            ],
          )),
    );
  }
}
