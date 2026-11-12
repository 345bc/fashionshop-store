import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late Future<Object?> _status;
  List<VnPayRefund> _refunds = [];
  bool _busy = false;
  String? _copiedDetails;

  @override
  void initState() {
    super.initState();
    _status = _run();
  }

  Future<Object?> _run([Future<VnPayRefund> Function()? request]) async {
    final provider = context.read<OrdersProvider>();
    try {
      if (request == null) {
        _refunds = await provider.vnpayRefunds(widget.orderId);
      } else {
        final updated = await request();
        _refunds = [
          updated,
          ..._refunds.where((refund) => refund.id != updated.id),
        ];
      }
      return null;
    } catch (error) {
      if (request != null) {
        try {
          _refunds = await provider.vnpayRefunds(widget.orderId);
        } catch (_) {
          // Keep the known attempts and report the original operation error.
        }
      }
      return error;
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  void _start([Future<VnPayRefund> Function()? request]) {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = _run(request);
    });
  }

  bool _needsReconciliation(VnPayRefund refund) =>
      refund.state != 'SUCCEEDED' && refund.state != 'REJECTED';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: FutureBuilder(
      future: _status,
      builder: (context, snapshot) {
        final refund = _refunds
            .where((item) => item.returnId == widget.returnId)
            .firstOrNull;
        final error = snapshot.data;
        final waiting = snapshot.connectionState != ConnectionState.done;
        final ready = !waiting && error == null;
        final canRequest = refund == null || refund.state == 'REJECTED';
        final blocker = canRequest
            ? _refunds.where(_needsReconciliation).firstOrNull
            : null;
        final toReconcile = refund != null && _needsReconciliation(refund)
            ? refund
            : blocker;
        final attempt = toReconcile ?? refund;
        final details = [
          'Số hóa đơn (vnp_TxnRef): ${widget.orderId}',
          if (attempt != null) 'Lần hoàn #${attempt.id}',
          if (attempt?.requestId case final requestId?
              when requestId.isNotEmpty)
            'Mã yêu cầu hoàn (requestId): $requestId',
        ].join('\n');
        final canSubmit = ready && canRequest && blocker == null;
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
                else ...[
                  if (blocker != null)
                    const Text(
                      'Đơn có khoản hoàn chưa rõ kết quả. Hãy đối soát VNPay trước khi gửi yêu cầu này.',
                    )
                  else if (error == null)
                    Text(status),
                  if (error != null) Text(error.toString()),
                  const SizedBox(height: 12),
                  SelectableText(details),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: details));
                        if (mounted) setState(() => _copiedDetails = details);
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(
                        _copiedDetails == details
                            ? 'Đã sao chép'
                            : 'Sao chép thông tin tra soát',
                      ),
                    ),
                  ),
                ],
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
                onPressed: () => _start(),
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
            if (!waiting && toReconcile != null)
              FilledButton(
                onPressed: () {
                  final provider = context.read<OrdersProvider>();
                  _start(() => provider.reconcileVnpayRefund(toReconcile.id));
                },
                child: const Text('Đối soát VNPay'),
              ),
          ],
        );
      },
    ),
  );
}
