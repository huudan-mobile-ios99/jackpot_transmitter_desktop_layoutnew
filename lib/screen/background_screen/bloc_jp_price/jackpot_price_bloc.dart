import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
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
  final Map<String, double> _lastSavedBatch = {}; // Track last saved batch
  final Map<String, DateTime> _lastUpdateTime = {};
  static final Duration _debounceDuration = Duration(seconds: ConfigCustomDuration.durationGetDataToBloc);
  static final Duration _firstUpdateDelay = Duration(milliseconds: ConfigCustomDuration.durationGetDataToBlocFirstMS);
  final JackpotHiveService hiveService = JackpotHiveService();
  final Logger _logger = Logger();
  Timer? _reconnectTimer;
  Timer? _saveTimer;
  static const double _tolerance = 0.0001; // Tolerance for floating-point comparison
  static const List<String> _requiredKeys = [
    'Frequent',
    'Daily',
    'Dozen',
    'Weekly',
    'Triple',
    'Vegas',
    'Monthly',
    'HighLimit',
    'DailyGolden'
  ]; // All nine required keys

  JackpotPriceBloc() : super(JackpotPriceState.initial()) {
    on<JackpotPriceResetEvent>(_onReset);
    on<JackpotPriceConnectionEvent>(_onConnection);
    _initializeHiveAndConnect();
  }

  Future<void> _initializeHiveAndConnect() async {
    try {
      await hiveService.initHive();
      _connectToWebSocket();
    } catch (e) {
      _logger.e('JackpotPriceBloc: Failed to initialize Hive: $e');
    }
  }

  void _connectToWebSocket() {
    if (isClosed) {
      debugPrint('JackpotPriceBloc: Aborting connection attempt because BLoC is closed');
      return;
    }
    try {
      debugPrint('JackpotPriceBloc: Connecting to WebSocket');
      channel = IOWebSocketChannel.connect(ConfigCustom.endpoint_web_socket);
      if (!isClosed) {
        emit(state.copyWith(isConnected: true, error: null));
      }
      channel.stream.listen(
        (message) async {
          try {
            final data = jsonDecode(message);
            final level = data['Id'].toString();
            final value = double.tryParse(data['Value'].toString()) ?? 0.0;
            final key = ConfigCustomJackpot.getJackpotNameByLevel(level);
            if (key == null) {
              if (!_unknownLevels.contains(level)) {
                _unknownLevels.add(level);
                debugPrint('JackpotPriceBloc: Unknown level: $level, tracked: $_unknownLevels');
                if (_unknownLevels.length > 5) {
                  debugPrint('JackpotPriceBloc: Excessive unknown levels: $_unknownLevels');
                }
              }
              return;
            }

            _currentBatchValues[key] = value;
            // debugPrint('JackpotPriceBloc: Added to batch: $key=$value, batch: $_currentBatchValues');

            final isFirst = _isFirstUpdate[key] ?? false;
            final now = DateTime.now();
            final lastUpdate = _lastUpdateTime[key];

            if (!isFirst && lastUpdate != null && now.difference(lastUpdate) < _debounceDuration) {
              debugPrint('JackpotPriceBloc: Skipping update for $key due to debounce');
              return;
            }

            // Schedule save only if all required keys are present
            if (_currentBatchValues.keys.toSet().containsAll(_requiredKeys)) {
              _scheduleSave(isFirst ? _firstUpdateDelay : _debounceDuration);
            }
          } catch (e) {
            debugPrint('JackpotPriceBloc: Error parsing message: $e');
          }
        },
        onError: (error) {
          debugPrint('JackpotPriceBloc: WebSocket error: $error');
          if (!isClosed) {
            emit(state.copyWith(isConnected: false, error: error.toString()));
            _scheduleReconnect();
          }
        },
        onDone: () {
          debugPrint('JackpotPriceBloc: WebSocket closed');
          if (!isClosed) {
            emit(state.copyWith(isConnected: false, error: null));
            _scheduleReconnect();
          }
        },
      );
    } catch (e) {
      debugPrint('JackpotPriceBloc: Failed to connect to WebSocket: $e');
      if (!isClosed) {
        emit(state.copyWith(isConnected: false, error: e.toString()));
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (!isClosed) {
      _reconnectTimer = Timer(Duration(seconds: secondToReconnect), () {
        if (!isClosed) {
          _connectToWebSocket();
        }
      });
    }
  }

  void _scheduleSave(Duration delay) {
    _saveTimer?.cancel(); // Cancel any existing save timer
    _saveTimer = Timer(delay, () async {
      if (isClosed) {
        debugPrint('JackpotPriceBloc: Aborting save because BLoC is closed');
        return;
      }

      // Ensure all required keys are present
      if (!_currentBatchValues.keys.toSet().containsAll(_requiredKeys)) {
        debugPrint('JackpotPriceBloc: Incomplete batch, skipping save: $_currentBatchValues');
        return;
      }

      // Check if the batch is different from the last saved batch
      if (_isBatchUnchanged()) {
        debugPrint('JackpotPriceBloc: Skipping save due to unchanged batch');
        return;
      }

      final jackpotValues = Map<String, double>.from(state.jackpotValues);
      final previousJackpotValues = Map<String, double>.from(state.previousJackpotValues);
      final validKeys = ConfigCustomJackpot.validJackpotNames.toSet();

      // Update state with new values
      _currentBatchValues.forEach((key, value) {
        if (jackpotValues[key] != value) {
          previousJackpotValues[key] = jackpotValues[key] ?? 0.0;
          jackpotValues[key] = value;
          _lastUpdateTime[key] = DateTime.now();
          if (_isFirstUpdate[key] ?? false) {
            _isFirstUpdate[key] = false;
          }
        }
      });

      jackpotValues.removeWhere((k, v) => !validKeys.contains(k));
      previousJackpotValues.removeWhere((k, v) => !validKeys.contains(k));

      if (!isClosed) {
        emit(state.copyWith(
          jackpotValues: jackpotValues,
          previousJackpotValues: previousJackpotValues,
          isConnected: true,
          error: null,
        ));
      }

      // Save to Hive and update last saved batch
      try {
        await hiveService.appendJackpotHistory(Map.from(_currentBatchValues));
        debugPrint('JackpotPriceBloc: Saved batch to Hive: $_currentBatchValues');
        _lastSavedBatch.clear();
        _lastSavedBatch.addAll(_currentBatchValues); // Update last saved batch
        _currentBatchValues.clear(); // Clear batch after saving
      } catch (e) {
        debugPrint('JackpotPriceBloc: Failed to save batch to Hive: $e');
      }
    });
  }

  bool _isBatchUnchanged() {
    // If no last saved batch or current batch is incomplete, allow saving
    if (_lastSavedBatch.isEmpty || !_currentBatchValues.keys.toSet().containsAll(_requiredKeys)) {
      return false;
    }

    // Check if all nine prices differ from the last saved batch
    for (var key in _requiredKeys) {
      if (!_currentBatchValues.containsKey(key) || !_lastSavedBatch.containsKey(key)) {
        return false; // Missing keys mean the batch is different
      }
      if ((_currentBatchValues[key]! - _lastSavedBatch[key]!).abs() < _tolerance) {
        return true; // If any price is the same (within tolerance), consider batch unchanged
      }
    }
    return false; // All prices differ, batch is unique
  }

  Future<void> _onReset(JackpotPriceResetEvent event, Emitter<JackpotPriceState> emit) async {
    final key = ConfigCustomJackpot.getJackpotNameByLevel(event.level);
    if (key == null) {
      debugPrint('JackpotPriceBloc: Unknown level for reset: ${event.level}');
      return;
    }

    final resetValue = ConfigCustomJackpot.getResetValueByLevel(event.level);
    if (resetValue == null) {
      debugPrint('JackpotPriceBloc: No reset value found for $key');
      return;
    }

    final jackpotValues = Map<String, double>.from(state.jackpotValues);
    final previousJackpotValues = Map<String, double>.from(state.previousJackpotValues);

    previousJackpotValues[key] = jackpotValues[key] ?? 0.0;
    jackpotValues[key] = resetValue;
    _lastUpdateTime[key] = DateTime.now();
    _isFirstUpdate[key] = false;
    debugPrint('JackpotPriceBloc: Reset $key to $resetValue');
    if (!isClosed) {
      emit(state.copyWith(
        jackpotValues: jackpotValues,
        previousJackpotValues: previousJackpotValues,
        isConnected: true,
        error: null,
      ));
    }

    _currentBatchValues[key] = resetValue;
    if (_currentBatchValues.keys.toSet().containsAll(_requiredKeys)) {
      _scheduleSave(Duration.zero); // Save immediately for reset if batch is complete
    }
  }

  Future<void> _onConnection(JackpotPriceConnectionEvent event, Emitter<JackpotPriceState> emit) async {
    debugPrint('JackpotPriceBloc: Connection status changed: isConnected=${event.isConnected}, error=${event.error}');
    if (!isClosed) {
      emit(state.copyWith(
        isConnected: event.isConnected,
        error: event.error,
      ));
    }
  }

  @override
  Future<void> close() {
    debugPrint('JackpotPriceBloc: Closing WebSocket and cancelling timers');
    _reconnectTimer?.cancel();
    _saveTimer?.cancel();
    channel.sink.close(1000, 'Bloc closed');
    return super.close();
  }
}
