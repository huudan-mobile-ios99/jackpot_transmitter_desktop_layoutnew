import 'package:flutter/material.dart';
import 'package:playtech_transmitter_app/service/config_custom.dart';
final textStyleOdo = TextStyle(
    fontSize: ConfigCustom.text_odo_size,
    color: Colors.white,
    fontFamily: 'sf-pro-display',
    fontWeight: FontWeight.w600,
  );
final textStyleOdoSmall = TextStyle(
    fontSize: ConfigCustom.text_odo_size_small,
    color: Colors.white,
    fontFamily: 'sf-pro-display',
    fontWeight: FontWeight.w600,
);


final textStyleJPHit = TextStyle(
      fontSize: ConfigCustom.text_hit_price_size,
      color: Colors.white,
      fontFamily: 'sf-pro-display',
      fontWeight: FontWeight.w600,
      shadows: const [
        Shadow(
          color: Colors.orangeAccent,
          offset: Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
    final textStyleJPHitSmall = TextStyle(
      fontSize: ConfigCustom.text_hit_number_size,
      color: Colors.white,
      fontFamily: 'sf-pro-display',
      fontWeight: FontWeight.w600,
      shadows: const [
        Shadow(
          color: Colors.orangeAccent,
          offset: Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
