import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc_jp_price/jackpot_hive_service.dart';
import 'package:playtech_transmitter_app/screen/background_screen/jackpot_screen_odometer.dart';
import 'package:playtech_transmitter_app/service/config_custom.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc/video_bloc.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc_jp_price/jackpot_price_bloc.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc_jp_price/jackpot_state_state.dart';
import 'package:logger/logger.dart';
import 'package:playtech_transmitter_app/service/config_custom_jackpot.dart';
import 'package:playtech_transmitter_app/service/config_custom_size_position.dart';
import 'package:playtech_transmitter_app/service/widget/circlar_progress.dart';

class JackpotDisplayScreen2496x624 extends StatefulWidget {
  const JackpotDisplayScreen2496x624({super.key});

  @override
  State<JackpotDisplayScreen2496x624> createState() => _JackpotDisplayScreen2496x624State();
}

class _JackpotDisplayScreen2496x624State extends State<JackpotDisplayScreen2496x624> {
  final Logger _logger = Logger();
  late Future<Map<String, double>> _hiveValuesFuture;

  @override
  void initState() {
    super.initState();
    // Fetch Hive data once on initialization
    _hiveValuesFuture = JackpotHiveService().getJackpotHistory().then((state) => state.first);
  }



  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: _hiveValuesFuture,
      builder: (context, snapshot) {
        Map<String, double> hiveValues = {};
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          hiveValues = snapshot.data!;
        } else if (snapshot.hasError) {
          _logger.e('Error loading Hive data: ${snapshot.error}');
        }

        return BlocBuilder<VideoBloc, ViddeoState>(
          buildWhen: (previous, current) => previous.id != current.id,
          builder: (context, state) {
            return BlocBuilder<JackpotPriceBloc, JackpotPriceState>(
              buildWhen: (previous, current) =>
                  previous.isConnected != current.isConnected ||
                  previous.error != current.error ||
                  previous.jackpotValues != current.jackpotValues ||
                  previous.previousJackpotValues != current.previousJackpotValues,
              builder: (context, priceState) {
                // _logger.i('Building JackpotDisplayScreen: ${priceState.jackpotValues}');
                return Center(
                  child: priceState.isConnected
                      ?
                      SizedBox(
                          width: ConfigCustom.fixWidth,
                          height: ConfigCustom.fixHeight,
                          child: screenHorizontal2496x624(context, hiveValues),
                        )
                      :
                      priceState.error != null ? Container() : circularProgessCustom()
                );
              },
            );
          },
        );
      },
    );
  }
  Widget screenHorizontal2496x624(BuildContext context, Map<String, double> hiveValues) {
    return Stack(
      children: [
        //ROW ABOVE
         Positioned(
          top: ConfigCustomSizePosition.jp_vegas_2496x624_dY,
          left: ConfigCustomSizePosition.jp_vegas_2496x624_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagVegas,
            valueKey: ConfigCustomJackpot.tagVegas,
            hiveValue: hiveValues[ConfigCustomJackpot.tagVegas] ?? 0.0,
            isSmall: false,
          ),
        ),
        Positioned(
          top: ConfigCustomSizePosition.jp_monthly_2496x624_dY,
          left: ConfigCustomSizePosition.jp_monthly_2496x624_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagMonthly,
            valueKey: ConfigCustomJackpot.tagMonthly,
            hiveValue: hiveValues[ConfigCustomJackpot.tagMonthly] ?? 0.0,
            isSmall: false,
          ),
        ),
         Positioned(
          top: ConfigCustomSizePosition.jp_weekly_2496x624_dY,
          left: ConfigCustomSizePosition.jp_weekly_2496x624dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagWeekly,
            valueKey: ConfigCustomJackpot.tagWeekly,
            hiveValue: hiveValues[ConfigCustomJackpot.tagWeekly] ?? 0.0,
            isSmall: false,
          ),
        ),
        Positioned(
          top: ConfigCustomSizePosition.jp_tripple_2496x624_dY,
          left: ConfigCustomSizePosition.jp_tripple_2496x624_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagTriple,
            valueKey: ConfigCustomJackpot.tagTriple,
            hiveValue: hiveValues[ConfigCustomJackpot.tagTriple] ?? 0.0,
            isSmall: false,
          ),
        ),
        Positioned(
          top: ConfigCustomSizePosition.jp_dozen_2496x624_dY,
          left: ConfigCustomSizePosition.jp_dozen_2496x624_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagDozen,
            valueKey: ConfigCustomJackpot.tagDozen,
            hiveValue: hiveValues[ConfigCustomJackpot.tagDozen] ?? 0.0,
            isSmall: false,
          ),
        ),



        //ROW BELOW
        Positioned(
          top: ConfigCustomSizePosition.jp_dailygolden_2496x624_dY,
          left: ConfigCustomSizePosition.jp_dailygolden_2496x624_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagDailyGolden,
            valueKey: ConfigCustomJackpot.tagDailyGolden,
            hiveValue: hiveValues[ConfigCustomJackpot.tagDailyGolden] ?? 0.0,
            isSmall: true,
          ),
        ),
        Positioned(
          top: ConfigCustomSizePosition.jp_daily_2496x624_dY,
          left: ConfigCustomSizePosition.jp_daily_2496x624_dX,
          child: JackpotOdometer(
            nameJP:ConfigCustomJackpot.tagDaily ,
            valueKey: ConfigCustomJackpot.tagDaily,
            hiveValue: hiveValues[ConfigCustomJackpot.tagDaily] ?? 0.0,
            isSmall: true,
          ),
        ),
        Positioned(
          top: ConfigCustomSizePosition.jp_frequent_2496x624_dY,
          left: ConfigCustomSizePosition.jp_frequent_2496x624_dX,
          child:
           JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagFrequent,
            valueKey: ConfigCustomJackpot.tagFrequent,
            hiveValue: hiveValues[ConfigCustomJackpot.tagFrequent] ?? 0.0,
            isSmall: true,
          ),
        ),

      ],
    );
  }

}
