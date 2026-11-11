import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../inventory/data/models/inventory_response_model.dart';
import '../../data/models/order_response_model.dart';
import '../providers/orders_provider.dart';

class VnPayRefundDialog extends StatefulWidget {
  const VnPayRefundDialog({
    super.key,
    required this.orderId,
    required this.amount,
    this.returnId,
  });

  final int orderId;
  final int? returnId;
  final num amount;

  @override
  State<VnPayRefundDialog> createState() => _VnPayRefundDialogState();
}

class _VnPayRefundDialogState extends State<VnPayRefundDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  late Future<({VnPayRefund? refund, Object? error})> _refund;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refund = _run(_load);
  }

  Future<VnPayRefund?> _load() async {
    final refunds = await context.read<OrdersProvider>().vnpayRefunds(
      widget.orderId,
    );
    return refunds
        .where((refund) => refund.returnId == widget.returnId)
        .firstOrNull;
  }

  Future<({VnPayRefund? refund, Object? error})> _run(
    Future<VnPayRefund?> Function() request,
  ) async {
    try {
      return (refund: await request(), error: null);
    } catch (error) {
      return (refund: null, error: error);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  void _start(Future<VnPayRefund> Function() request) {
    if (_busy) return;
    setState(() {
      _busy = true;
      _refund = _run(request);
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: FutureBuilder(
      future: _refund,
      builder: (context, snapshot) {
        final refund = snapshot.data?.refund;
        final error = snapshot.data?.error;
        final waiting = snapshot.connectionState != ConnectionState.done;
        final ready = !waiting && error == null;
        final canSubmit =
            ready && (refund == null || refund.state == 'REJECTED');
        final canReconcile =
            ready &&
            refund != null &&
            refund.state != 'SUCCEEDED' &&
            refund.state != 'REJECTED';
        final status = switch (refund?.state) {
          'SUCCEEDED' => 'VNPay đã xác nhận hoàn tiền.',
          'REJECTED' => 'VNPay đã từ chối yêu cầu hoàn tiền.',
          'PENDING' || 'PROCESSING' => 'Yêu cầu đang chờ VNPay xử lý.',
          'UNKNOWN' => 'Chưa rõ kết quả. Hãy đối soát với VNPay.',
          null => 'Chưa có yêu cầu hoàn tiền.',
          _ => 'Cần đối soát với VNPay.',
        };

        return AlertDialog(
          scrollable: true,
          title: const Text('Hoàn tiền VNPay'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Số tiền hoàn: ${money(widget.amount)}'),
                const SizedBox(height: 12),
                if (waiting)
                  const LinearProgressIndicator()
                else if (error != null)
                  Text(error.toString())
                else
                  Text(status),
                if (canSubmit) ...[
                  const SizedBox(height: 16),
                  Form(
                    key: _form,
                    child: TextFormField(
                      controller: _note,
                      maxLength: 400,
                      decoration: const InputDecoration(
                        labelText: 'Lý do hoàn tiền *',
                      ),
                      validator: (value) => value?.trim().isNotEmpty == true
                          ? null
                          : 'Vui lòng nhập lý do',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            if (error != null && !waiting)
              OutlinedButton(
                onPressed: () {
                  final reload = _run(_load);
                  setState(() {
                    _refund = reload;
                  });
                },
                child: const Text('Tải lại trạng thái'),
              ),
            if (canSubmit)
              FilledButton(
                onPressed: () {
                  if (_form.currentState?.validate() != true) return;
                  final provider = context.read<OrdersProvider>();
                  _start(
                    () => provider.submitVnpayRefund(
                      widget.orderId,
                      widget.returnId,
                      _note.text.trim(),
                    ),
                  );
                },
                child: const Text('Gửi yêu cầu hoàn tiền'),
              ),
            if (canReconcile)
              FilledButton(
                onPressed: () {
                  final provider = context.read<OrdersProvider>();
                  _start(() => provider.reconcileVnpayRefund(refund.id));
                },
                child: const Text('Đối soát VNPay'),
              ),
          ],
        );
      },
    ),
  );
}
