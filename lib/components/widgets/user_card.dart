/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan
 * Created At: 4/22/21, 2:45 PM
 */
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// This widget return the logged user's card

class UserCard extends StatelessWidget {
  final String text;
  final bool welcome;
  final bool shift;

  const UserCard(
      {Key? key, required this.text, this.welcome = true, this.shift = false})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final user = userBloc.currentUser;
    final userDetails = userBloc.userDetails;
    final userTitle = user?.uSERHEDTITLE ?? "";
    final format = DateFormat("yyyy-MM-dd HH:mm:ss");
    String loggedDate = DateFormat.yMMMMEEEEd().format(
        format.parse(user?.uSERHEDSIGNONDATE ?? DateTime.now().toString()));
    return ListTile(
      leading: UserImage(),
      title: Text(
        welcome ? "welcome".tr() + " $userTitle" : "$userTitle",
        style: CurrentTheme.subtitle1!
            .copyWith(color: CurrentTheme.bodyText2!.color),
      ),
      subtitle: Text(
        shift
            ? "Login @ $loggedDate Shift # ${userDetails?.shiftNo ?? ""}"
            : text,
        style: CurrentTheme.bodyText2,
      ),
    );
  }
}
