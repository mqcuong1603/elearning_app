// import 'package:flutter/foundation.dart';
// import '../services/offline_sync_service.dart';
// import 'dart:async';

// /// Connectivity Provider
// /// Manages offline/online state for the entire application
// class ConnectivityProvider with ChangeNotifier {
//   final OfflineSyncService _offlineSyncService;
//   StreamSubscription<bool>? _connectivitySubscription;
//   bool _isOnline = true;

//   ConnectivityProvider({
//     required OfflineSyncService offlineSyncService,
//   }) : _offlineSyncService = offlineSyncService {
//     _initialize();
//   }

//   /// Get current online status
//   bool get isOnline => _isOnline;

//   /// Get offline mode status
//   bool get isOffline => !_isOnline;

//   /// Get offline sync service
//   OfflineSyncService get offlineSyncService => _offlineSyncService;

//   /// Initialize connectivity monitoring
//   void _initialize() {
//     // Get initial status
//     _isOnline = _offlineSyncService.isOnline;

//     // Listen to connectivity changes
//     _connectivitySubscription = _offlineSyncService.connectivityStream.listen(
//       (bool online) {
//         if (_isOnline != online) {
//           _isOnline = online;
//           notifyListeners();
//           print('🔔 Connectivity Provider: ${online ? "ONLINE" : "OFFLINE"}');
//         }
//       },
//     );
//   }

//   /// Manually refresh connectivity status
//   Future<void> refreshConnectivity() async {
//     final newStatus = _offlineSyncService.isOnline;
//     if (_isOnline != newStatus) {
//       _isOnline = newStatus;
//       notifyListeners();
//     }
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }
// }
