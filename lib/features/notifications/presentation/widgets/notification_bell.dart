import 'dart:async';

import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';
import '../pages/notification_inbox_page.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, required this.result});

  final LoginResult result;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with WidgetsBindingObserver {
  int _unreadCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCount();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadCount(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCount() async {
    final token = widget.result.token;
    if (token == null || token.isEmpty) return;
    try {
      final data = await AuthApi.getNotifications(token);
      if (mounted) setState(() => _unreadCount = data.unreadCount);
    } on AuthApiException {
      // The bell remains usable while notifications are temporarily unavailable.
    }
  }

  Future<void> _openInbox() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationInboxPage(result: widget.result),
      ),
    );
    if (mounted) _loadCount();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Notifications',
    onPressed: _openInbox,
    icon: SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: Icon(Icons.notifications_none_rounded)),
          if (_unreadCount > 0)
            Positioned(
              right: -6,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFDF625F),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
