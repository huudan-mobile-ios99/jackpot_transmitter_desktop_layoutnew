import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:playtech_transmitter_app/service/config_custom.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

part 'video_event.dart';
part 'video_state.dart';

final _logger = Logger();

class VideoBloc extends Bloc<VideoEvent, ViddeoState> {
  final String videoBg; // Single video
  final BuildContext context; // For Phoenix.rebirth
  Timer? _timer;
  final int totalCountToRestart = ConfigCustom.totalCountToRestart;

  VideoBloc({
    required this.videoBg,
    required this.context,
  }) : super(ViddeoState(
    id:1,
          currentVideo: videoBg,
          lastSwitchTime: DateTime.now(),
          count: 0,
          isRestart: false,
        )) {
    on<IncrementCount>(_onIncrementCount);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel(); // Prevent multiple timers
    _timer = Timer.periodic(Duration(seconds: ConfigCustom.durationSwitchVideoSecond), (_) {
      add(IncrementCount());
    });
  }

  Future<void> _onIncrementCount(IncrementCount event, Emitter<ViddeoState> emit) async {
    final now = DateTime.now();
    int newCount = state.count + 1;
    bool newIsRestart = false;

    if (newCount >= totalCountToRestart) {
      newCount = 0;
      newIsRestart = true;
      _logger.i('Triggering app restart after $totalCountToRestart counts');
      try {
        Phoenix.rebirth(context);
      } catch (e) {
        _logger.e('Restart failed: $e');
      }
    }

    emit(ViddeoState(
      currentVideo: videoBg,
      lastSwitchTime: now,
      count: newCount,
      isRestart: newIsRestart, id: 1,
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _logger.i('VideoBloc closed, timer cancelled');
    return super.close();
  }
}
