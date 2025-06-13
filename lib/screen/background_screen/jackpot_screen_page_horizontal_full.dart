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

class JackpotDisplayScreenHorizontalFull extends StatefulWidget {
  const JackpotDisplayScreenHorizontalFull({super.key});

  @override
  State<JackpotDisplayScreenHorizontalFull> createState() => _JackpotDisplayScreenHorizontalFullState();
}

class _JackpotDisplayScreenHorizontalFullState extends State<JackpotDisplayScreenHorizontalFull> {
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
                          child: screenHorizontal(context, hiveValues),
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
  Widget screenHorizontal(BuildContext context, Map<String, double> hiveValues) {
    return Stack(
      children: [
         Positioned(
          top: ConfigCustomSizePosition.jp_vegas_screen2_dY,
          left: ConfigCustomSizePosition.jp_vegas_screen1_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagVegas,
            valueKey: ConfigCustomJackpot.tagVegas,
            hiveValue: hiveValues[ConfigCustomJackpot.tagVegas] ?? 0.0,
            isSmall: false,
          ),
        ),
        Positioned(
          top: ConfigCustomSizePosition.jp_monthly_screen2_dY,
          right: ConfigCustomSizePosition.jp_monthly_screen2_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagMonthly,
            valueKey: ConfigCustomJackpot.tagMonthly,
            hiveValue: hiveValues[ConfigCustomJackpot.tagMonthly] ?? 0.0,
            isSmall: false,
          ),
        ),
         Positioned(
          top: ConfigCustomSizePosition.jp_weekly_screen1_dY,
          right: ConfigCustomSizePosition.jp_weekly_screen1_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagWeekly,
            valueKey: ConfigCustomJackpot.tagWeekly,
            hiveValue: hiveValues[ConfigCustomJackpot.tagWeekly] ?? 0.0,
            isSmall: false,
          ),
        ),

//2
        Positioned(
          top: ConfigCustomSizePosition.jp_tripple_screen2_dY,
          left: ConfigCustomSizePosition.jp_tripple_screen2_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagTriple,
            valueKey: ConfigCustomJackpot.tagTriple,
            hiveValue: hiveValues[ConfigCustomJackpot.tagTriple] ?? 0.0,
            isSmall: false,
          ),
        ),
        Positioned(
          top: ConfigCustomSizePosition.jp_dozen_screen1_dY,
          right: ConfigCustomSizePosition.jp_dozen_screen1_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagDozen,
            valueKey: ConfigCustomJackpot.tagDozen,
            hiveValue: hiveValues[ConfigCustomJackpot.tagDozen] ?? 0.0,
            isSmall: false,
          ),
        ),
        Positioned(
          top: ConfigCustomSizePosition.jp_highlimit_screen2_dY,
          right: ConfigCustomSizePosition.jp_highlimit_screen2_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagHighLimit,
            valueKey: ConfigCustomJackpot.tagHighLimit,
            hiveValue: hiveValues[ConfigCustomJackpot.tagHighLimit] ?? 0.0,
            isSmall: false,
          ),
        ),


//1
        Positioned(
          top: ConfigCustomSizePosition.jp_dailygolden_screen1_dY,
          left: ConfigCustomSizePosition.jp_dailygolden_screen1_dX,
          child: JackpotOdometer(
            nameJP: ConfigCustomJackpot.tagDailyGolden,
            valueKey: ConfigCustomJackpot.tagDailyGolden,
            hiveValue: hiveValues[ConfigCustomJackpot.tagDailyGolden] ?? 0.0,
            isSmall: false,
          ),
        ),
        Positioned(
          top: ConfigCustomSizePosition.jp_daily_screen1_dY,
          right: ConfigCustomSizePosition.jp_daily_screen1_dX,
          child: JackpotOdometer(
            nameJP:ConfigCustomJackpot.tagDaily ,
            valueKey: ConfigCustomJackpot.tagDaily,
            hiveValue: hiveValues[ConfigCustomJackpot.tagDaily] ?? 0.0,
            isSmall: true,
          ),
        ),
        Positioned(
          top: ConfigCustomSizePosition.jp_frequent_screen1_dY,
          right: ConfigCustomSizePosition.jp_frequent_screen1_dX,
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
