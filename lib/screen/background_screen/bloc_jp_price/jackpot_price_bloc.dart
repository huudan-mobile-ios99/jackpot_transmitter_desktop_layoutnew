import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc_jp_price/jackpot_hive_service.dart';
import 'package:playtech_transmitter_app/screen/background_screen/bloc_jp_price/jackpot_state_state.dart';
import 'package:playtech_transmitter_app/service/config_custom.dart';
import 'package:playtech_transmitter_app/service/config_custom_duration.dart';
import 'package:playtech_transmitter_app/service/config_custom_jackpot.dart';
import 'package:web_socket_channel/io.dart';
import 'jackpot_price_event.dart';

class JackpotPriceBloc extends Bloc<JackpotPriceEvent, JackpotPriceState> {
  late IOWebSocketChannel channel;
  final int secondToReconnect = ConfigCustomDuration.secondToReConnect;
  final List<String> _unknownLevels = [];
  final Map<String, bool> _isFirstUpdate = {
    for (var name in ConfigCustomJackpot.validJackpotNames) name: true,
  };
  final Map<String, double> _currentBatchValues = {};
  final Map<String, DateTime> _lastUpdateTime = {};
  static final Duration _debounceDuration = Duration(seconds: ConfigCustomDuration.durationGetDataToBloc);
  static final Duration _firstUpdateDelay = Duration(milliseconds: ConfigCustomDuration.durationGetDataToBlocFirstMS);
  final JackpotHiveService hiveService = JackpotHiveService();
  final Logger _logger = Logger();

  JackpotPriceBloc() : super(JackpotPriceState.initial()) {
    on<JackpotPriceResetEvent>(_onReset);
    on<JackpotPriceConnectionEvent>(_onConnection);
    // _logger.d('JackpotPriceBloc: Initializing WebSocket connection to ${ConfigCustom.endpointWebSocket}');
    _initializeHiveAndConnect();
  }

  Future<void> _initializeHiveAndConnect() async {
    try {
      await hiveService.initHive();
      _connectToWebSocket();
    } catch (e) {
      // _logger.e('JackpotPriceBloc: Failed to initialize Hive: $e');
    }
  }

  void _connectToWebSocket() {
    try {
      // _logger.d('JackpotPriceBloc: Connecting to WebSocket');
      channel = IOWebSocketChannel.connect(ConfigCustom.endpoint_web_socket);
      emit(state.copyWith(isConnected: true, error: null));
      channel.stream.listen(
        (message) async {
          try {
            // debugPrint('JackpotPriceBloc: Received message at ${DateTime.now().toIso8601String()}: $message');
            final data = jsonDecode(message);
            final level = data['Id'].toString();
            final value = double.tryParse(data['Value'].toString()) ?? 0.0;
            final key = ConfigCustomJackpot.getJackpotNameByLevel(level);
            if (key == null) {
              if (!_unknownLevels.contains(level)) {
                _unknownLevels.add(level);
                // _logger.d('JackpotPriceBloc: Unknown level: $level, tracked: $_unknownLevels');
                if (_unknownLevels.length > 5) {
                  // _logger.d('JackpotPriceBloc: Excessive unknown levels: $_unknownLevels');
                }
              }
              return;
            }

            _currentBatchValues[key] = value;
            // _logger.d('JackpotPriceBloc: Added to batch: $key=$value, batch: $_currentBatchValues');

            final isFirst = _isFirstUpdate[key] ?? false;
            final now = DateTime.now();
            final lastUpdate = _lastUpdateTime[key];

            if (!isFirst && lastUpdate != null && now.difference(lastUpdate) < _debounceDuration) {
              // _logger.d('JackpotPriceBloc: Skipping update for $key due to debounce');
              // print('JackpotPriceBloc: Skipping update for $key due to debounce, lastUpdate: $lastUpdate');
              return;
            }
            await Future.delayed(isFirst ? _firstUpdateDelay : _debounceDuration);

            final jackpotValues = Map<String, double>.from(state.jackpotValues);
            final previousJackpotValues = Map<String, double>.from(state.previousJackpotValues);

            if (jackpotValues[key] != value) {
              previousJackpotValues[key] = jackpotValues[key] ?? 0.0;
              jackpotValues[key] = value;
              _lastUpdateTime[key] = now;
              if (isFirst) {
                _isFirstUpdate[key] = false;
              }
              final validKeys = ConfigCustomJackpot.validJackpotNames.toSet();
              jackpotValues.removeWhere((k, v) => !validKeys.contains(k));
              previousJackpotValues.removeWhere((k, v) => !validKeys.contains(k));
              // print('JackpotPriceBloc: Updated $key to $value');
              // ignore: invalid_use_of_visible_for_testing_member
              emit(state.copyWith(
                jackpotValues: jackpotValues,
                previousJackpotValues: previousJackpotValues,
                isConnected: true,
                error: null,
              ));

              if (_currentBatchValues.isNotEmpty) {
                try {
                  await hiveService.appendJackpotHistory(_currentBatchValues);
                  // _logger.d('JackpotPriceBloc: Saved batch to Hive: $_currentBatchValues');
                } catch (e) {
                  // _logger.d('JackpotPriceBloc: Failed to save batch to Hive: $e');
                }
              }
            }
          } catch (e) {
            // _logger.d('JackpotPriceBloc: Error parsing message: $e');
          }
        },
        onError: (error) {
          // _logger.d('JackpotPriceBloc: WebSocket error: $error');
          emit(state.copyWith(isConnected: false, error: error.toString()));
          Future.delayed(Duration(seconds: secondToReconnect), _connectToWebSocket);
        },
        onDone: () {
          // _logger.d('JackpotPriceBloc: WebSocket closed');
          emit(state.copyWith(isConnected: false, error: null));
          Future.delayed(Duration(seconds: secondToReconnect), _connectToWebSocket);
        },
      );
    } catch (e) {
      // _logger.d('JackpotPriceBloc: Failed to connect to WebSocket: $e');
      emit(state.copyWith(isConnected: false, error: e.toString()));
      Future.delayed(Duration(seconds: secondToReconnect), _connectToWebSocket);
    }
  }

  Future<void> _onReset(JackpotPriceResetEvent event, Emitter<JackpotPriceState> emit) async {
    final key = ConfigCustomJackpot.getJackpotNameByLevel(event.level);
    if (key == null) {
      // _logger.d('JackpotPriceBloc: Unknown level for reset: ${event.level}');
      return;
    }

    final resetValue = ConfigCustomJackpot.getResetValueByLevel(event.level);
    if (resetValue == null) {
      // _logger.d('JackpotPriceBloc: No reset value found for $key');
      return;
    }

    final jackpotValues = Map<String, double>.from(state.jackpotValues);
    final previousJackpotValues = Map<String, double>.from(state.previousJackpotValues);

    previousJackpotValues[key] = jackpotValues[key] ?? 0.0;
    jackpotValues[key] = resetValue;
    _lastUpdateTime[key] = DateTime.now();
    _isFirstUpdate[key] = false;
    // _logger.d('JackpotPriceBloc: Reset $key to $resetValue');
    emit(state.copyWith(
      jackpotValues: jackpotValues,
      previousJackpotValues: previousJackpotValues,
      isConnected: true,
      error: null,
    ));

    _currentBatchValues[key] = resetValue;
    try {
      await hiveService.appendJackpotHistory(Map.from(_currentBatchValues));
      // _logger.d('JackpotPriceBloc: Saved reset batch to Hive: $_currentBatchValues');
    } catch (e) {
      // _logger.d('JackpotPriceBloc: Failed to save reset batch to Hive: $e');
    }
  }

  Future<void> _onConnection(JackpotPriceConnectionEvent event, Emitter<JackpotPriceState> emit) async {
    // _logger.d('JackpotPriceBloc: Connection status changed: isConnected=${event.isConnected}, error=${event.error}');
    emit(state.copyWith(
      isConnected: event.isConnected,
      error: event.error,
    ));
  }

  @override
  Future<void> close() {
    // _logger.d('JackpotPriceBloc: Closing WebSocket');
    channel.sink.close(1000, 'Bloc closed');
    return super.close();
  }
}
