import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _itemsPerPage = 10;
  String _filterDate = 'all'; // 'all', 'today', 'week'
  String _filterAge = 'all'; // 'all', '1', '2', etc.

  List<NotificationModel> get notifications => _notifications;
  int get itemsPerPage => _itemsPerPage;
  String get filterDate => _filterDate;
  String get filterAge => _filterAge;
  int get totalPages => (_notifications.length / _itemsPerPage).ceil();
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationController() {
    _initializeNotifications();
  }

  void _initializeNotifications() {
    _notifications = [
      NotificationModel(
        id: '1',
        type: 'humidity',
        title: 'Kelembapan rendah : 58.0%',
        description: 'Kelembapan rendah : 58.0%',
        dateTime: DateTime(2025, 6, 26, 21, 38),
        chickenAge: 1,
        severity: 'medium',
      ),
      NotificationModel(
        id: '2',
        type: 'temperature',
        title: 'Suhu rendah : 28°C',
        description: 'Suhu rendah : 28°C',
        dateTime: DateTime(2025, 6, 26, 21, 38),
        chickenAge: 1,
        severity: 'medium',
      ),
      NotificationModel(
        id: '3',
        type: 'fuzzy',
        title: 'Fuzzy: Kelembapan sangat rendah (1.00)',
        description: 'Fuzzy: Kelembapan sangat rendah (1.00)',
        dateTime: DateTime(2025, 6, 27, 1, 21),
        chickenAge: 1,
        severity: 'low',
      ),
      NotificationModel(
        id: '4',
        type: 'fuzzy',
        title: 'Fuzzy: Suhu sangat rendah (1.00)',
        description: 'Fuzzy: Suhu sangat rendah (1.00)',
        dateTime: DateTime(2025, 6, 27, 1, 21),
        chickenAge: 1,
        severity: 'low',
      ),
      NotificationModel(
        id: '5',
        type: 'alert',
        title: 'Kelembapan sangat rendah! Kondisi darurat terdeteksi',
        description: 'Kelembapan sangat rendah! Kondisi darurat terdeteksi',
        dateTime: DateTime(2025, 6, 27, 1, 21),
        chickenAge: 1,
        severity: 'high',
      ),
      NotificationModel(
        id: '6',
        type: 'fuzzy',
        title: 'Fuzzy: Suhu sangat rendah (1.00)',
        description: 'Fuzzy: Suhu sangat rendah (1.00)',
        dateTime: DateTime(2025, 6, 27, 1, 21),
        chickenAge: 1,
        severity: 'low',
      ),
    ];
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

  // Filter by date
  void setDateFilter(String filter) {
    _filterDate = filter;
    notifyListeners();
  }

  // Filter by age
  void setAgeFilter(String age) {
    _filterAge = age;
    notifyListeners();
  }

  // Mark notification as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // Mark all as read
  void markAllAsRead() {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();
  }

  // Add new notification
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Delete specific notification
  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // Export notifications (placeholder)
  void exportNotifications() {
    // Implement export logic here
    notifyListeners();
  }
}
