import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playtech_transmitter_app/screen/background_screen/jackpot_screen_page.dart';
import 'package:playtech_transmitter_app/service/config_custom.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc/video_bloc.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc_jp_price/jackpot_price_bloc.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc_jp_price/jackpot_state_state.dart';
import 'package:logger/logger.dart';
import 'package:playtech_transmitter_app/service/widget/circlar_progress.dart';

class JackpotDisplayScreenHorizontal extends StatefulWidget {
  const JackpotDisplayScreenHorizontal({super.key});

  @override
  State<JackpotDisplayScreenHorizontal> createState() => _JackpotDisplayScreenHorizontalState();
}

class _JackpotDisplayScreenHorizontalState extends State<JackpotDisplayScreenHorizontal> {
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return  BlocBuilder<VideoBloc, ViddeoState>(
          buildWhen: (previous, current) => previous.id != current.id,
          builder: (context, state) {
            return BlocBuilder<JackpotPriceBloc, JackpotPriceState>(
              buildWhen: (previous, current) =>
                  previous.isConnected != current.isConnected ||
                  previous.error != current.error ||
                  previous.jackpotValues != current.jackpotValues ||
                  previous.previousJackpotValues != current.previousJackpotValues,
              builder: (context, priceState) {
                return Center(


                );
              },
            );
          },
        );
  }

}
