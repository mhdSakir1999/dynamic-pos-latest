/*
 * Copyright (c) 2021 myPOS Software Solutions.  All rights reserved.
 * Author: Shalika Ashan & TM.Sakir
 * Created At: 4/22/21, 10:18 AM
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:checkout/bloc/user_bloc.dart';
import 'package:checkout/components/components.dart';
import 'package:checkout/models/pos_config.dart';
import 'package:flutter/material.dart';

/// This widget returns the logged user image
class UserImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String user = userBloc.currentUser?.uSERHEDPICTURE ?? "";
    if (user.isEmpty) {
      user = 'default.png';
    }
    user = '${POSConfig().posImageServer}images/user/$user';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
            elevation: 5,
            shape: CircleBorder(),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: user,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Image.asset(
                  "assets/images/default_male.png",
                  fit: BoxFit.cover,
                ),
              ),
            )
            // CircleAvatar(backgroundImage: CachedNetworkImageProvider(user))

            ),
      ],
    );
    // return Image.asset("assets/images/default_male.png");
  }
}

/// This widget returns the current customer's image
class CustomerImage extends StatelessWidget {
  final String? imagePath;

  const CustomerImage({Key? key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildImageAvatar();
  }

  Widget buildImageAvatar() {
    return CircleAvatar(
      backgroundColor: CurrentTheme.primaryColor,
      backgroundImage: buildUserImage(),
    );
  }

  ImageProvider buildUserImage() {
    print(POSConfig().loyaltyServerImage + (imagePath ?? ''));
    if (imagePath == null || imagePath?.isNotEmpty != true)
      return AssetImage("assets/images/default_male.png");
    else
      return CachedNetworkImageProvider(
          POSConfig().loyaltyServerImage + (imagePath ?? ''),
          //POSConfig().posImageServer + (imagePath ?? ""),
          headers: {'Access-Control-Allow-Origin': '*'});
  }
}
