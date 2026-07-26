import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frontened/core/api.dart';

class SocketService {
  static IO.Socket? _socket;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 🔥 INITIALIZE CORE REAL-TIME SOCKET ECOSYSTEM
  static void initialize(BuildContext context, List<String> enrolledCourseIds) {
    if (_socket != null && _socket!.connected) return;

    // Connect securely to the root url for socket connection
    String socketUrl = Api.baseUrl.replaceAll('/api', '');
    
    _socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setReconnectionAttempts(5) // Will auto-retry if backend is sleeping
        .build());

    _socket!.onConnect((_) {
      debugPrint("🔌 Real-time Notification Tunnel established successfully!");

      for (String courseId in enrolledCourseIds) {
        _socket!.emit("join_course_room", courseId);
      }
    });

    _socket!.onConnectError((error) {
      debugPrint("⚠️ Socket Connection Error: $error");
    });

    // 🔥 GLOBAL EVENT LISTENER
    _socket!.on("new_notification", (data) {
      if (data != null) {
        String title = data['title'] ?? "Academic Update";
        String message = data['message'] ?? "New content published.";

        _showNativeTopBannerNotification(title, message);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint("❌ Notification Tunnel disconnected safely.");
    });
  }

  // 🔥 NATIVE HEADS-UP POPUP DISPLAY ENGINE
  static Future<void> _showNativeTopBannerNotification(String title, String message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'smart_teacher_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for academic alerts.',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('smart_sound'),
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      int safeNotificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // 🔥 FIX: Wapas Named Arguments lagaye gaye hain (id:, title:, body:)
      await _localNotifications.show(
        id: safeNotificationId, 
        title: title,
        body: message,
        notificationDetails: platformDetails,
      );
    } catch (e) {
      debugPrint("Native Top Banner Audio Exception: $e");
    }
  }

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}