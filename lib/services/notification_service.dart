import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'db_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<NotificationModel> _notifications = [];
  final List<Function(List<NotificationModel>)> _listeners = [];
  final List<StreamSubscription> _subscriptions = [];
  final Map<String, DateTime> _lastNotificationTimes = {};
  bool _isInitialized = false;
  int _currentChickenAge = 1;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    debugPrint('🚀 Menginisialisasi NotificationService...');

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Izin notifikasi diizinkan');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    await _loadNotificationsFromDb();
    _fetchAgeFromFirebase();
    _startMonitoring();

    await forceRefreshFromFirebase();
    _isInitialized = true;
    debugPrint('✅ NotificationService berhasil diinisialisasi');
  }

  Future<void> _loadNotificationsFromDb() async {
    try {
      _notifications = await _dbHelper.getNotifications();
      _notifyListeners();
    } catch (e) {
      debugPrint('❌ Gagal memuat notifikasi lokal: $e');
    }
  }

  void _fetchAgeFromFirebase() {
    debugPrint('🐔 Memuat umur ayam dari Firebase...');
    final subscription = _database.child('chicken_age').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        _currentChickenAge = int.tryParse(data.toString()) ?? 1;
        debugPrint('🐔 Umur ayam diperbarui: $_currentChickenAge minggu');
      }
    });
    _subscriptions.add(subscription);
  }

  void _startMonitoring() {
    debugPrint('👀 Mulai memantau data dari Firebase...');
    _loadEmergencyData();
    _loadFuzzyData();
    _loadStatusData();
    _loadSensorData();
    _loadWifiLogData();
  }

  void _loadWifiLogData() {
    try {
      final subscription = _database.child('logs/wifi').onValue.listen((event) {
        final wifiLog = event.snapshot.value?.toString();
        if (wifiLog == null || wifiLog.trim().isEmpty) {
          return;
        }

        final lowerLog = wifiLog.toLowerCase();
        final isDisconnected =
            lowerLog.contains('disconnected') ||
            lowerLog.contains('connection failed') ||
            lowerLog.contains('terputus');
        final isReconnected =
            lowerLog.contains('connected') ||
            lowerLog.contains('reconnect') ||
            lowerLog.contains('tersambung kembali');

        if (isDisconnected) {
          _addNotificationFromEvent(
            'wifi terputus silahkan cek dikandang anda',
            type: 'alert',
            severity: 'high',
          );
          return;
        }

        if (!isReconnected) {
          return;
        }

        _addNotificationFromEvent(
          'wifi tersambung kembali',
          type: 'system',
          severity: 'low',
        );
      });
      _subscriptions.add(subscription);
    } catch (e) {
      debugPrint('❌ Error saat setup listener wifi log: $e');
    }
  }

  void _loadEmergencyData() {
    try {
      final subscription = _database.child('emergency').onValue.listen((event) {
        final raw = event.snapshot.value;
        if (raw is! Map) {
          return;
        }

        final emergencyData = Map<String, dynamic>.from(raw);
        if (emergencyData['low_temperature'] == true) {
          _addNotificationFromEvent(
            'Suhu sangat rendah! Kondisi darurat terdeteksi.',
            type: 'alert',
            severity: 'high',
          );
        }
        if (emergencyData['high_temperature'] == true) {
          _addNotificationFromEvent(
            'Suhu sangat tinggi! Kondisi darurat terdeteksi.',
            type: 'alert',
            severity: 'high',
          );
        }
        if (emergencyData['low_humidity'] == true) {
          _addNotificationFromEvent(
            'Kelembapan sangat rendah! Kondisi darurat terdeteksi.',
            type: 'alert',
            severity: 'high',
          );
        }
        if (emergencyData['high_humidity'] == true) {
          _addNotificationFromEvent(
            'Kelembapan sangat tinggi! Kondisi darurat terdeteksi.',
            type: 'alert',
            severity: 'high',
          );
        }
      });
      _subscriptions.add(subscription);

      final changeSubscription = _database
          .child('emergency')
          .onChildChanged
          .listen((event) {
            if (event.snapshot.value != true) {
              return;
            }

            final type = event.snapshot.key ?? 'unknown';
            String message = '';
            if (type == 'low_temperature') {
              message = 'Suhu sangat rendah! Kondisi darurat terdeteksi.';
            } else if (type == 'high_temperature') {
              message = 'Suhu sangat tinggi! Kondisi darurat terdeteksi.';
            } else if (type == 'low_humidity') {
              message = 'Kelembapan sangat rendah! Kondisi darurat terdeteksi.';
            } else if (type == 'high_humidity') {
              message = 'Kelembapan sangat tinggi! Kondisi darurat terdeteksi.';
            }

            if (message.isNotEmpty) {
              _addNotificationFromEvent(
                message,
                type: 'alert',
                severity: 'high',
              );
            }
          });
      _subscriptions.add(changeSubscription);
    } catch (e) {
      debugPrint('❌ Error saat setup listener emergency: $e');
    }
  }

  void _loadFuzzyData() {
    try {
      final tempSubscription = _database
          .child('fuzzy/temperature')
          .onValue
          .listen((event) {
            final raw = event.snapshot.value;
            if (raw is! Map) {
              return;
            }

            final fuzzyTemp = Map<String, dynamic>.from(raw);
            final veryHigh = (fuzzyTemp['veryHigh'] as num?)?.toDouble() ?? 0.0;
            final veryLow = (fuzzyTemp['veryLow'] as num?)?.toDouble() ?? 0.0;

            if (veryHigh > 0.7) {
              _addNotificationFromEvent(
                'Fuzzy: Suhu sangat tinggi (${veryHigh.toStringAsFixed(2)})',
                type: 'fuzzy',
                severity: 'high',
              );
            }
            if (veryLow > 0.7) {
              _addNotificationFromEvent(
                'Fuzzy: Suhu sangat rendah (${veryLow.toStringAsFixed(2)})',
                type: 'fuzzy',
                severity: 'high',
              );
            }
          });
      _subscriptions.add(tempSubscription);

      final humSubscription = _database.child('fuzzy/humidity').onValue.listen((
        event,
      ) {
        final raw = event.snapshot.value;
        if (raw is! Map) {
          return;
        }

        final fuzzyHum = Map<String, dynamic>.from(raw);
        final veryHigh = (fuzzyHum['veryHigh'] as num?)?.toDouble() ?? 0.0;
        final veryLow = (fuzzyHum['veryLow'] as num?)?.toDouble() ?? 0.0;

        if (veryHigh > 0.7) {
          _addNotificationFromEvent(
            'Fuzzy: Kelembapan sangat tinggi (${veryHigh.toStringAsFixed(2)})',
            type: 'fuzzy',
            severity: 'high',
          );
        }
        if (veryLow > 0.7) {
          _addNotificationFromEvent(
            'Fuzzy: Kelembapan sangat rendah (${veryLow.toStringAsFixed(2)})',
            type: 'fuzzy',
            severity: 'high',
          );
        }
      });
      _subscriptions.add(humSubscription);
    } catch (e) {
      debugPrint('❌ Error saat setup listener fuzzy: $e');
    }
  }

  void _loadStatusData() {
    try {
      final tempSubscription = _database
          .child('status/temperature')
          .onValue
          .listen((event) {
            final tempStatus = event.snapshot.value?.toString();
            if (tempStatus == null) {
              return;
            }

            if (tempStatus.contains('Sangat Tinggi') ||
                tempStatus.contains('Sangat Rendah')) {
              _addNotificationFromEvent(
                'Status: $tempStatus',
                type: 'alert',
                severity: 'high',
              );
            }
          });
      _subscriptions.add(tempSubscription);

      final humSubscription = _database.child('status/humidity').onValue.listen(
        (event) {
          final humStatus = event.snapshot.value?.toString();
          if (humStatus == null) {
            return;
          }

          if (humStatus.contains('Sangat Tinggi') ||
              humStatus.contains('Sangat Rendah')) {
            _addNotificationFromEvent(
              'Status: $humStatus',
              type: 'alert',
              severity: 'high',
            );
          }
        },
      );
      _subscriptions.add(humSubscription);

      final statusSubscription = _database
          .child('status')
          .onChildChanged
          .listen((event) {
            final status = event.snapshot.value?.toString() ?? '';
            final type = event.snapshot.key ?? 'unknown';
            if (status.contains('Sangat Tinggi') ||
                status.contains('Sangat Rendah')) {
              _addNotificationFromEvent(
                'Status $type: $status',
                type: 'alert',
                severity: 'high',
              );
            }
          });
      _subscriptions.add(statusSubscription);
    } catch (e) {
      debugPrint('❌ Error saat setup listener status: $e');
    }
  }

  void _loadSensorData() {
    final subscription = _database.child('sensor').onValue.listen((event) {
      final raw = event.snapshot.value;
      if (raw is! Map) {
        return;
      }

      try {
        final sensorData = Map<String, dynamic>.from(raw);
        final temperature = _readDouble(sensorData, ['temperature']);
        final humidity = _readDouble(sensorData, ['Humidity', 'humidity']);

        if (temperature == null || humidity == null) {
          return;
        }

        final ranges = _getRangeByAge(_currentChickenAge);
        final tempMin = ranges['tempMin']!;
        final tempMax = ranges['tempMax']!;
        final humMin = ranges['humMin']!;
        final humMax = ranges['humMax']!;

        if (temperature < tempMin - 2) {
          _addNotificationFromEvent(
            'Suhu sangat rendah: ${temperature.toStringAsFixed(1)}°C (Kritis)',
            type: 'temperature',
            severity: 'high',
          );
        } else if (temperature < tempMin) {
          _addNotificationFromEvent(
            'Suhu rendah: ${temperature.toStringAsFixed(1)}°C',
            type: 'temperature',
            severity: 'medium',
          );
        } else if (temperature > tempMax + 2) {
          _addNotificationFromEvent(
            'Suhu sangat tinggi: ${temperature.toStringAsFixed(1)}°C (Kritis)',
            type: 'temperature',
            severity: 'high',
          );
        } else if (temperature > tempMax) {
          _addNotificationFromEvent(
            'Suhu tinggi: ${temperature.toStringAsFixed(1)}°C',
            type: 'temperature',
            severity: 'medium',
          );
        } else {
          _addNotificationFromEvent(
            'Suhu normal: ${temperature.toStringAsFixed(1)}°C (Optimal)',
            type: 'temperature',
            severity: 'low',
          );
        }

        if (humidity < humMin - 5) {
          _addNotificationFromEvent(
            'Kelembapan sangat rendah: ${humidity.toStringAsFixed(1)}% (Kritis)',
            type: 'humidity',
            severity: 'high',
          );
        } else if (humidity < humMin) {
          _addNotificationFromEvent(
            'Kelembapan rendah: ${humidity.toStringAsFixed(1)}%',
            type: 'humidity',
            severity: 'medium',
          );
        } else if (humidity > humMax + 5) {
          _addNotificationFromEvent(
            'Kelembapan sangat tinggi: ${humidity.toStringAsFixed(1)}% (Kritis)',
            type: 'humidity',
            severity: 'high',
          );
        } else if (humidity > humMax) {
          _addNotificationFromEvent(
            'Kelembapan tinggi: ${humidity.toStringAsFixed(1)}%',
            type: 'humidity',
            severity: 'medium',
          );
        } else {
          _addNotificationFromEvent(
            'Kelembapan normal: ${humidity.toStringAsFixed(1)}% (Optimal)',
            type: 'humidity',
            severity: 'low',
          );
        }
      } catch (e) {
        debugPrint('❌ Error saat memproses data sensor: $e');
      }
    });
    _subscriptions.add(subscription);
  }

  Future<void> _addNotificationFromEvent(
    String event, {
    required String type,
    required String severity,
  }) async {
    final lastTime = _lastNotificationTimes[event];
    if (lastTime != null) {
      final difference = DateTime.now().difference(lastTime);
      if (difference.inMinutes < 5) {
        return;
      }
    }

    _lastNotificationTimes[event] = DateTime.now();

    final notification = NotificationModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_$type',
      type: type,
      title: event,
      description: '$event [Umur: $_currentChickenAge minggu]',
      dateTime: DateTime.now(),
      chickenAge: _currentChickenAge,
      severity: severity,
    );

    _notifications.insert(0, notification);
    _notifyListeners();

    await _dbHelper.insertNotification(notification);

    await _showHighPriorityLocalNotification(notification);
  }

  Map<String, double> _getRangeByAge(int ageInWeeks) {
    switch (ageInWeeks) {
      case 1:
        return {
          'tempMin': 33.0,
          'tempMax': 35.0,
          'humMin': 60.0,
          'humMax': 70.0,
        };
      case 2:
        return {
          'tempMin': 30.0,
          'tempMax': 33.0,
          'humMin': 60.0,
          'humMax': 65.0,
        };
      case 3:
        return {
          'tempMin': 28.0,
          'tempMax': 30.0,
          'humMin': 60.0,
          'humMax': 65.0,
        };
      case 4:
        return {
          'tempMin': 25.0,
          'tempMax': 28.0,
          'humMin': 55.0,
          'humMax': 60.0,
        };
      default:
        return {
          'tempMin': 25.0,
          'tempMax': 28.0,
          'humMin': 55.0,
          'humMax': 60.0,
        };
    }
  }

  double? _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  void disposeService() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _isInitialized = false;
    debugPrint('🛑 NotificationService dihentikan');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Notifikasi Baru',
      message.notification?.body ?? 'Anda memiliki notifikasi baru',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  Future<void> _showHighPriorityLocalNotification(
    NotificationModel notification,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.description,
      platformChannelSpecifics,
      payload: notification.id,
    );
  }

  void addListener(Function(List<NotificationModel>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(List<NotificationModel>) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_notifications);
    }
  }

  // Mark notification as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notifyListeners();
      _dbHelper.markAsRead(id);
    }
  }

  // Get unread count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Clear all notifications
  void clearAll() {
    _notifications.clear();
    _notifyListeners();
    _dbHelper.clearAll();
  }

  // Force refresh from Firebase
  Future<void> forceRefreshFromFirebase() async {
    try {
      final sensorSnapshot = await _database.child('sensor').get();
      if (sensorSnapshot.value is Map) {
        final sensorData = Map<String, dynamic>.from(
          sensorSnapshot.value as Map,
        );
        final temperature = _readDouble(sensorData, ['temperature']);
        final humidity = _readDouble(sensorData, ['Humidity', 'humidity']);
        if (temperature != null || humidity != null) {
          if (temperature != null) {
            _addNotificationFromEvent(
              'Suhu saat ini: ${temperature.toStringAsFixed(1)}°C',
              type: 'temperature',
              severity: 'low',
            );
          }
          if (humidity != null) {
            _addNotificationFromEvent(
              'Kelembapan saat ini: ${humidity.toStringAsFixed(1)}%',
              type: 'humidity',
              severity: 'low',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Gagal force refresh: $e');
    }

    _notifyListeners();
  }
}

// Handle background message
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📱 Menerima pesan di background: ${message.notification?.title}');
  await NotificationService().initialize();
}
