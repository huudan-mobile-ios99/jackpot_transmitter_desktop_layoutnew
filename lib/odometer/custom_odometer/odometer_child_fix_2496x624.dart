import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:playtech_transmitter_app/odometer/odometer_number.dart';
import 'package:playtech_transmitter_app/odometer/slide_odometer.dart';
import 'package:playtech_transmitter_app/service/config_custom.dart';
import 'package:playtech_transmitter_app/service/config_custom_duration.dart';
import 'package:playtech_transmitter_app/service/config_custom_text.dart';
import 'dart:async';
import 'package:playtech_transmitter_app/service/widget/text_style.dart';



class GameOdometerChildStyleFixed2496x624 extends StatefulWidget {
  final double startValue;
  final double endValue;
  final double hiveValue; // New field for Hive initial value
  final String nameJP;
  final bool isSmall;

   const GameOdometerChildStyleFixed2496x624({
    super.key,
    required this.startValue,
    required this.endValue,
    required this.hiveValue,
    required this.nameJP,
    required this.isSmall,
  });

  @override
  _GameOdometerChildStyleFixed2496x624State createState() => _GameOdometerChildStyleFixed2496x624State();
}

class _GameOdometerChildStyleFixed2496x624State extends State<GameOdometerChildStyleFixed2496x624> with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<OdometerNumber> odometerAnimation;
  late ValueNotifier<double> currentValueNotifier;
  late int durationPerStep;
  late int durationPerStepHive;
  Timer? _animationTimer;
  final String fontFamily = 'sf-pro-display';
  bool _isFirstRun = true; // Flag to use hiveValue on first run
  static const Duration _debounceDuration = Duration(seconds: 0);
  DateTime? _lastUpdateTime;
  final bool _isDisposing = false;
  final int totalDuration = ConfigCustomDuration.durationFinishCircleSpinNumber; //total duration to finish a spin


  @override
  void initState() {
    super.initState();
    final initialValue = widget.startValue == 0.0 ? widget.hiveValue : widget.startValue;
    currentValueNotifier = ValueNotifier<double>(initialValue);
    durationPerStep = calculationDurationPerStep(
      totalDuration: totalDuration,
      startValue: initialValue,
      endValue: widget.endValue,
    );

    _initializeAnimationController();
    _updateAnimation(currentValueNotifier.value, currentValueNotifier.value);
    // _isFirstRun? debugPrint('#FirstRun') : debugPrint('#NextRun');
  }







  @override
  void didUpdateWidget(covariant GameOdometerChildStyleFixed2496x624 oldWidget) {
    super.didUpdateWidget(oldWidget);
    final now = DateTime.now();
    if (_lastUpdateTime != null && now.difference(_lastUpdateTime!) < _debounceDuration) {
      // _logger.d('Odometer: ${widget.nameJP}, Skipping update due to debounce, lastUpdate: $_lastUpdateTime');
      return;
    }
    if (widget.startValue != oldWidget.startValue || widget.endValue != oldWidget.endValue) {
      _animationTimer?.cancel();
      currentValueNotifier.value = widget.startValue == 0.0 ? widget.endValue : widget.startValue;
      durationPerStep = calculationDurationPerStep(
        totalDuration: totalDuration,
        startValue:_isFirstRun==true ? widget.hiveValue :  widget.startValue,
        endValue: widget.endValue,
      );

      animationController
        ..stop()
        ..duration = Duration(milliseconds: durationPerStep);
       _updateAnimation(currentValueNotifier.value, currentValueNotifier.value);

      if (_isFirstRun == true && widget.hiveValue > 0 && widget.hiveValue < widget.endValue) {
        _startAutoAnimation(widget.hiveValue);
      }
      if (widget.startValue != 0.0  || widget.startValue !=0 && !_isDisposing) {
        _startAutoAnimation(widget.startValue);
      }


      _isFirstRun = false; // Disable hiveValue after first run
      _lastUpdateTime = now;
    }
  }




  void _startAutoAnimation(double startValue) {
    const increment = 0.01;
    final interval = Duration(milliseconds:  durationPerStep.clamp(20, 5000));
    _animationTimer?.cancel();
    currentValueNotifier.value = startValue;
    _updateAnimation(startValue, startValue);
    _animationTimer = Timer.periodic(interval, (timer) {
      if (!mounted || _isDisposing || currentValueNotifier.value >= widget.endValue) {
        timer.cancel();
        // _logger.d('Odometer: ${widget.nameJP}, Animation completed or unmounted, currentValue: ${currentValueNotifier.value}');
        return;
      }
      if (currentValueNotifier.value >= widget.endValue || !mounted) {
        timer.cancel();
        return;
      }
      final nextValue = (currentValueNotifier.value + increment).clamp(currentValueNotifier.value, widget.endValue);
      _updateAnimation(currentValueNotifier.value, nextValue);
      currentValueNotifier.value = nextValue;
      animationController.forward(from: 0.0);

    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    animationController.dispose();
    currentValueNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return ClipRect(
      child: RepaintBoundary(
        child: Container(
          // color:Colors.white10,
          alignment: Alignment.center,
          width: ConfigCustom.fixWidth / 2,
          height:widget.isSmall==true? ConfigCustomText.odo_height_2496x6244_small :  ConfigCustomText.odo_height_2496x6244,
          child: Stack(
            children: [
              Positioned(
                top:widget.isSmall==true? -ConfigCustomText.odo_position_top_2496x6244_small :  -ConfigCustomText.odo_position_top_2496x624,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<double>(
                  valueListenable: currentValueNotifier,
                  builder: (context, value, child) {
                    return RepaintBoundary(
                      child: SlideOdometerTransition(
                        verticalOffset:widget.isSmall==true?ConfigCustomText.text_odo_letter_vertical_offset_2496x6244_small :  ConfigCustomText.text_odo_letter_vertical_offset_2496x624,
                        groupSeparator: Text(',', style: widget.isSmall==true?textStyleOdo2496x624Small : textStyleOdo2496x624,),
                        decimalSeparator: Text('.', style: widget.isSmall==true?textStyleOdo2496x624Small : textStyleOdo2496x624,),
                        letterWidth:widget.isSmall==true?ConfigCustomText.text_odo_letter_width_2496x6244_small : ConfigCustomText.text_odo_letter_width_2496x624,
                        odometerAnimation: odometerAnimation,
                        numberTextStyle:widget.isSmall==true?textStyleOdo2496x624Small : textStyleOdo2496x624,
                        decimalPlaces: 2,
                        integerDigits: 0,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _initializeAnimationController() {
    animationController = AnimationController(
      duration: Duration(milliseconds: durationPerStep),
      vsync: this,
    );
  }

  void _updateAnimation(double start, double end) {
    odometerAnimation = OdometerTween(
      begin: OdometerNumber((start * 100).round()),
      end: OdometerNumber((end * 100).round()),
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.linear,
      ),
    );
  }
}


int calculationDurationPerStep({
  required int totalDuration,
  required double startValue,
  required double endValue,
}) {
  final logger = Logger();
  if (endValue <= startValue) {
    // debugPrint('Odometer: Calculation - endValue <= startValue, returning 1000ms');
    return 1000;
  }
  final totalSteps = ((endValue - startValue) / 0.01).ceil();
  final durationMs = (totalDuration * 1000) / totalSteps;
  final result = durationMs.round().clamp(20, 10000);
  final estimatedTotal = totalSteps * result / 1000;
  // debugPrint('Odometer: Calculation - startValue: $startValue, endValue: $endValue, totalSteps: $totalSteps, durationMs: $durationMs, rounded: $result, estimatedTotal: ${estimatedTotal}s');
  return result;
}
