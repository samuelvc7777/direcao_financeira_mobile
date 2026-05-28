import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'realtime_client.dart';

abstract class JourneyRealtimeBridge {
  RxBool get isOnline;
  void bind({required VoidCallback onRideChanged});
  void unbind();
}

class DefaultJourneyRealtimeBridge implements JourneyRealtimeBridge {
  DefaultJourneyRealtimeBridge({required this.realtimeClient});

  final RealtimeClient realtimeClient;
  static const _rideRefreshDebounce = Duration(milliseconds: 800);

  static const _rideEvents = <String>[
    'journey.ride.created',
    'journey.ride.updated',
  ];

  VoidCallback? _onRideChanged;
  DateTime? _lastRideRefreshAt;

  @override
  RxBool get isOnline => realtimeClient.isOnline;

  @override
  void bind({required VoidCallback onRideChanged}) {
    _onRideChanged = onRideChanged;
    for (final event in _rideEvents) {
      realtimeClient.on(event, _handleRideEvent);
    }
  }

  @override
  void unbind() {
    _onRideChanged = null;
    _lastRideRefreshAt = null;
    for (final event in _rideEvents) {
      realtimeClient.off(event, _handleRideEvent);
    }
  }

  void _handleRideEvent(dynamic _) => _notifyRideChanged();

  void _notifyRideChanged() {
    final now = DateTime.now();
    final lastRefreshAt = _lastRideRefreshAt;
    if (lastRefreshAt != null &&
        now.difference(lastRefreshAt) < _rideRefreshDebounce) {
      return;
    }

    _lastRideRefreshAt = now;
    _onRideChanged?.call();
  }
}
