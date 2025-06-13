import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playtech_transmitter_app/odometer/custom_odometer/odometer_child_fix_2496x624.dart';
import 'package:playtech_transmitter_app/odometer/custom_odometer/odometer_child_fix_hd.dart';
import 'package:playtech_transmitter_app/odometer/odometer_child.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc_jp_price/jackpot_price_bloc.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc_jp_price/jackpot_state_state.dart';


class JackpotOdometer extends StatelessWidget {
  final String nameJP;
  final String valueKey;
  final double hiveValue;
  final bool isSmall;

  const JackpotOdometer({
    super.key,
    required this.nameJP,
    required this.valueKey,
    required this.hiveValue,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<JackpotPriceBloc, JackpotPriceState, ({double startValue, double endValue})>(
      selector: (state) {
        final blocStartValue = state.previousJackpotValues[valueKey] ?? 0.0;
        final endValue = state.jackpotValues[valueKey] ?? 0.0;
        return (startValue: blocStartValue, endValue: endValue);
      },
      builder: (context, values) {
        return GameOdometerChildStyleFixed2496x624(
          startValue: values.startValue,
          endValue: values.endValue,
          nameJP: nameJP,
          hiveValue: hiveValue,
          isSmall:isSmall

        );
      },
    );
  }
}







