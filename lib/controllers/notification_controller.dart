import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  int _itemsPerPage = 10;
  String _filterDate = 'all'; // 'all', 'today', 'week'
  String _filterAge = 'all'; // 'all', '1', '2', etc.
  bool _isInitialized = false;

  List<NotificationModel> get notifications => _notifications;
  int get itemsPerPage => _itemsPerPage;
  String get filterDate => _filterDate;
  String get filterAge => _filterAge;
  int get totalPages => (_notifications.length / _itemsPerPage).ceil();
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationController() {
    _initializeController();
  }

  Future<void> _initializeController() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔄 Initializing notification controller...');
      
      // Initialize notification service (this will load Firebase data)
      await _notificationService.initialize();
      
      // Listen to notification changes
      _notificationService.addListener(_onNotificationsChanged);
      
      // Wait a bit for initial Firebase data to load
      await Future.delayed(const Duration(seconds: 2));
      
      // Get initial notifications from service
      _notifications = _notificationService.notifications;
      
      debugPrint('🔔 Loaded ${_notifications.length} notifications from service');
      
      // Only add dummy data if absolutely no notifications exist
      if (_notifications.isEmpty) {
        debugPrint('📝 No notifications from Firebase - showing empty state');
        // Keep empty instead of adding dummy data
        _notifications = [];
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing notification controller: $e');
      // Show empty state if Firebase fails
      _notifications = [];
    }
  }

  void _onNotificationsChanged(List<NotificationModel> notifications) {
    _notifications = notifications;
    debugPrint('🔔 Notifications updated: ${notifications.length} total');
    notifyListeners();
  }

  // Get notifications for specific page
  List<NotificationModel> getNotificationsForPage(int page) {
    final startIndex = (page - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _notifications.length) {
      return [];
    }

    return _notifications.sublist(
      startIndex,
      endIndex > _notifications.length ? _notifications.length : endIndex,
    );
  }

  // Set items per page
  void setItemsPerPage(int count) {
    _itemsPerPage = count;
    notifyListeners();
  }

  // Mark notification as read
  void markAsRead(String id) {
    _notificationService.markAsRead(id);
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notificationService.clearAll();
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    try {
      debugPrint('🔄 Refreshing notifications from controller...');
      
      if (!_isInitialized) {
        await _initializeController();
      } else {
        // Force refresh from Firebase to get latest data
        await _notificationService.forceRefreshFromFirebase();
        _notifications = _notificationService.notifications;
        debugPrint('✅ Refreshed ${_notifications.length} notifications');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing notifications: $e');
    }
  }

  // Filter notifications by date
  void setDateFilter(String filter) {
    _filterDate = filter;
    notifyListeners();
  }

  // Filter notifications by age
  void setAgeFilter(String filter) {
    _filterAge = filter;
    notifyListeners();
  }

  // Get filtered notifications
  List<NotificationModel> getFilteredNotifications({
    DateTimeRange? dateRange,
    int? selectedAge,
  }) {
    var filtered = List<NotificationModel>.from(_notifications);

    // Filter by date range
    if (dateRange != null) {
      filtered = filtered.where((notification) {
        final notificationDate = DateTime(
          notification.dateTime.year,
          notification.dateTime.month,
          notification.dateTime.day,
        );
        final startDate = DateTime(
          dateRange.start.year,
          dateRange.start.month,
          dateRange.start.day,
        );
        final endDate = DateTime(
          dateRange.end.year,
          dateRange.end.month,
          dateRange.end.day,
        );

        return (notificationDate.isAfter(
              startDate.subtract(const Duration(days: 1)),
            ) &&
            notificationDate.isBefore(endDate.add(const Duration(days: 1))));
      }).toList();
    }

    // Filter by age
    if (selectedAge != null) {
      filtered = filtered.where((notification) {
        return notification.chickenAge == selectedAge;
      }).toList();
    }

    return filtered;
  }

  // Mark all notifications as read
  void markAllAsRead() {
    final updatedNotifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _notifications = updatedNotifications;
    notifyListeners();
  }

  // Delete specific notification
  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // Export notifications (placeholder for future implementation)
  void exportNotifications() {
    // TODO: Implement export to CSV or PDF
    debugPrint('Export notifications feature - to be implemented');
  }

  // Add demo notifications for testing
  void addDemoNotifications() {
    final demoNotifications = [
      NotificationModel(
        id: 'demo_1_${DateTime.now().millisecondsSinceEpoch}',
        type: 'temperature',
        title: 'Suhu tinggi : 38.5°C',
        description: 'Suhu melebihi batas normal, sistem kipas diaktifkan otomatis',
        dateTime: DateTime.now().subtract(const Duration(minutes: 30)),
        chickenAge: 1,
        severity: 'medium',
      ),
      NotificationModel(
        id: 'demo_2_${DateTime.now().millisecondsSinceEpoch}',
        type: 'fuzzy',
        title: 'Fuzzy: Kelembapan sangat tinggi (0.89)',
        description: 'Sistem fuzzy logic mendeteksi kelembapan sangat tinggi dengan confidence 0.89',
        dateTime: DateTime.now().subtract(const Duration(hours: 1)),
        chickenAge: 1,
        severity: 'high',
      ),
      NotificationModel(
        id: 'demo_3_${DateTime.now().millisecondsSinceEpoch}',
        type: 'alert',
        title: 'Kondisi Darurat: Suhu Ekstrem!',
        description: 'Suhu mencapai 42°C! Sistem pendingin darurat diaktifkan',
        dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        chickenAge: 1,
        severity: 'high',
      ),
      NotificationModel(
        id: 'demo_4_${DateTime.now().millisecondsSinceEpoch}',
        type: 'humidity',
        title: 'Kelembapan normal : 65.2%',
        description: 'Kelembapan kembali dalam rentang normal setelah penyesuaian',
        dateTime: DateTime.now().subtract(const Duration(hours: 3)),
        chickenAge: 1,
        severity: 'low',
      ),
    ];

    // Add demo notifications to the beginning of the list
    for (final notification in demoNotifications.reversed) {
      _notifications.insert(0, notification);
    }
    
    debugPrint('✨ Added ${demoNotifications.length} demo notifications');
    notifyListeners();
  }

  // Clear all notifications and reload
  void clearAndReload() {
    _notifications.clear();
    debugPrint('🗑️ Cleared all notifications');
    notifyListeners();
    
    // Reinitialize to get fresh data
    _isInitialized = false;
    _initializeController();
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationsChanged);
    super.dispose();
  }
}
