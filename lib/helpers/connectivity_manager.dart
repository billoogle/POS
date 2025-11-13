// lib/helpers/connectivity_manager.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityManager {
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  factory ConnectivityManager() => _instance;
  ConnectivityManager._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  // ValueNotifier for reactive UI updates
  static final ValueNotifier<bool> isOnline = ValueNotifier(true);
  static final ValueNotifier<bool> isSyncing = ValueNotifier(false);

  // Initialize connectivity listener
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    isOnline.value = _isConnected(result);
    
    print('📡 Initial connectivity: ${isOnline.value ? "ONLINE" : "OFFLINE"}');

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = isOnline.value;
      isOnline.value = _isConnected(results);
      
      print('📡 Connectivity changed: ${isOnline.value ? "ONLINE" : "OFFLINE"}');
      
      // If came online from offline, trigger sync
      if (!wasOnline && isOnline.value) {
        print('🔄 Internet restored! Triggering auto-sync...');
        // Auto-sync will be handled by SyncService
      }
    });
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  void dispose() {
    _subscription?.cancel();
  }

  // Static helper methods
  static bool get currentStatus => isOnline.value;
  
  static void showOfflineSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Offline Mode: Data will sync when internet is available',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static void showOnlineSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Back Online! Syncing data...'),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static void showSyncCompleteSnackbar(BuildContext context, int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('✅ Synced $count items successfully'),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}