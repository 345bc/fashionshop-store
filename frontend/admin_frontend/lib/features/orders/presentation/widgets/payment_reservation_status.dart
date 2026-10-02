import 'dart:async';

import 'package:flutter/material.dart';

class PaymentReservationStatus extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback onExpired;
  const PaymentReservationStatus({
    super.key,
    required this.expiresAt,
    required this.onExpired,
  });
  @override
  State<PaymentReservationStatus> createState() =>
      _PaymentReservationStatusState();
}

class _PaymentReservationStatusState extends State<PaymentReservationStatus> {
  late final Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {});
      if (!widget.expiresAt.isAfter(DateTime.now()) && timer.tick % 5 == 0) {
        widget.onExpired();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final milliseconds = widget.expiresAt
        .difference(DateTime.now())
        .inMilliseconds;
    final seconds = milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
    final remaining =
        '${(seconds ~/ 60).toString().padLeft(2, "0")}:${(seconds % 60).toString().padLeft(2, "0")}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        seconds == 0
            ? 'Đã hết hạn thanh toán. Đang cập nhật trạng thái hủy...'
            : 'Chờ thanh toán online • Giữ hàng còn $remaining • Quá hạn sẽ tự hủy',
        style: TextStyle(
          color: seconds == 0 ? Colors.red : Colors.orange.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
