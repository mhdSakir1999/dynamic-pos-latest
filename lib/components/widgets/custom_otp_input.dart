import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otp_text_field/otp_field.dart';
import 'package:otp_text_field/style.dart';
import 'package:responsive_grid/responsive_grid.dart';

class CustomKeyboard extends StatelessWidget {
  final void Function(String) onKeyPressed;

  CustomKeyboard({required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(9, (index) {
        final digit = (index + 1).toString();
        return TextButton(
          onPressed: () => onKeyPressed(digit),
          child: Text(digit),
        );
      }),
    );
  }
}

class CustomOTPInput extends StatefulWidget {
  @override
  _CustomOTPInputState createState() => _CustomOTPInputState();
}

class _CustomOTPInputState extends State<CustomOTPInput> {
  OtpFieldController otpController = OtpFieldController();
  String otp = '';

  void updateOTP(String digit) {
    if (otp.length <= 5) {
      setState(() {
        otp += digit;
        otpController.setValue(digit, otp.length - 1);
        if (otp.trim().length == 6) {
          POSConfig.validateOTP = otp;
        }
      });
    }
  }

  void deleteDigit() {
    setState(() {
      if (otp.isNotEmpty) {
        otp = otp.substring(0, otp.length - 1);
        print(otp);
        otpController.setValue('', otp.length);
      } else {
        otpController.clear();
      }
    });
  }

  @override
  void dispose() {
    //otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OTPTextField(
          controller: otpController,
          length: 6,
          width: MediaQuery.of(context).size.width,
          fieldWidth: 50,
          style: TextStyle(fontSize: 17),
          textFieldAlignment: MainAxisAlignment.spaceAround,
          fieldStyle: FieldStyle.underline,
          // onChanged: (value) {
          //   setState(() {
          //     otp = value;
          //   });
          // },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // CustomKeyboard(
            //   onKeyPressed: (digit) {
            //     updateOTP(digit);
            //   },
            // ),
            Container(
              width: ScreenUtil().screenWidth / 3.5,
              child: ResponsiveGridList(
                  scroll: false,
                  desiredItemWidth: ScreenUtil().screenWidth / 20,
                  children: List.generate(
                      10,
                      (i) => Padding(
                            padding: const EdgeInsets.all(2.5),
                            child: TextButton(
                              onPressed: () => updateOTP(i.toString()),
                              style: ButtonStyle(
                                padding:
                                    WidgetStateProperty.all<EdgeInsetsGeometry>(
                                  const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10), // Adjust padding as needed
                                ),
                                minimumSize: WidgetStateProperty.all<Size>(
                                  const Size(50, 60), // Set the desired size
                                ),
                                textStyle: WidgetStateProperty.all<TextStyle>(
                                  const TextStyle(
                                      fontSize: 20.0,
                                      color:
                                          Colors.white), // Set the text style
                                ),
                                backgroundColor: WidgetStateProperty.all<Color>(
                                    Colors.greenAccent),
                                shape: WidgetStateProperty.all<OutlinedBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          8.0)), // Set the shape of the button
                                ),
                              ),
                              child: Text(
                                i.toString(),
                                style:const TextStyle(color: Colors.black),
                              ),
                            ),
                          ))),
            ),
            // for (var i = 0; i <= 9; i++)
            //   TextButton(
            //     onPressed: () => updateOTP(i.toString()),
            //     style: ButtonStyle(
            //       padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
            //         EdgeInsets.symmetric(
            //             horizontal: 20,
            //             vertical: 10), // Adjust padding as needed
            //       ),
            //       minimumSize: MaterialStateProperty.all<Size>(
            //         Size(40, 100), // Set the desired size
            //       ),
            //       textStyle: MaterialStateProperty.all<TextStyle>(
            //         TextStyle(
            //             fontSize: 20.0,
            //             color: Colors.white), // Set the text style
            //       ),
            //       backgroundColor:
            //           MaterialStateProperty.all<Color>(Colors.greenAccent),
            //       shape: MaterialStateProperty.all<OutlinedBorder>(
            //         RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(
            //                 8.0)), // Set the shape of the button
            //       ),
            //     ),
            //     child: Text(
            //       i.toString(),
            //       style: TextStyle(color: Colors.black),
            //     ),
            //   )
            TextButton(
              style: ButtonStyle(
                padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                 const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10), // Adjust padding as needed
                ),
                minimumSize: WidgetStateProperty.all<Size>(
                 const Size(40, 100), // Set the desired size
                ),
                backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                shape: WidgetStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          8.0)), // Set the shape of the button
                ),
              ),
              onPressed: deleteDigit,
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ],
    );
  }
}
