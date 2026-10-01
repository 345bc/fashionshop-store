import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/customer_response_model.dart';
import '../providers/customers_provider.dart';

class CustomerDetailDialog extends StatefulWidget {
  final int customerId;
  const CustomerDetailDialog({super.key, required this.customerId});
  @override
  State<CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<CustomerDetailDialog> {
  late final Future<CustomerResponseModel> _future;
  @override
  void initState() {
    super.initState();
    _future = context.read<CustomersProvider>().loadDetail(widget.customerId);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ZellaDialog(
      width: (size.width * 2 / 3).clamp(480.0, 1100.0),
      height: size.height * 2 / 3,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi tiết khách hàng',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<CustomerResponseModel>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Không tải được khách hàng: ${snapshot.error}'),
                  );
                }
                final c = snapshot.data!;
                return ListView(
                  children: [
                    _row('Họ và tên', c.fullName),
                    _row('Tên đăng nhập', c.username),
                    _row('Email', c.email),
                    _row('Số điện thoại', c.phone),
                    _row('Địa chỉ', c.address),
                    _row('Hạng thành viên', c.membershipTier),
                    _row('Điểm thưởng', '${c.rewardPoints}'),
                    _row('Tổng chi tiêu', '${c.totalSpending} đ'),
                    _row('Tài khoản', c.isActive ? 'Hoạt động' : 'Đã khóa'),
                    _row('Ngày tạo', c.createdAt?.toLocal().toString()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        SizedBox(
          width: 180,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Text(value == null || value.isEmpty ? '—' : value)),
      ],
    ),
  );
}
