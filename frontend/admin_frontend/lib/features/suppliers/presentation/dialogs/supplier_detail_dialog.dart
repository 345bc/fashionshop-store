import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/supplier_response_model.dart';
import '../providers/suppliers_provider.dart';

class SupplierDetailDialog extends StatefulWidget {
  final int supplierId;
  const SupplierDetailDialog({super.key, required this.supplierId});
  @override
  State<SupplierDetailDialog> createState() => _SupplierDetailDialogState();
}

class _SupplierDetailDialogState extends State<SupplierDetailDialog> {
  late final Future<SupplierResponseModel> _future;
  @override
  void initState() {
    super.initState();
    _future = context.read<SuppliersProvider>().loadDetail(widget.supplierId);
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
                  'Chi tiết nhà cung cấp',
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
            child: FutureBuilder<SupplierResponseModel>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Không tải được nhà cung cấp: ${snapshot.error}',
                    ),
                  );
                }
                final s = snapshot.data!;
                return ListView(
                  children: [
                    _row('Tên nhà cung cấp', s.name),
                    _row('Mã', s.code),
                    _row('Người liên hệ', s.contactPerson),
                    _row('Email', s.contactEmail),
                    _row('Số điện thoại', s.phone),
                    _row('Địa chỉ', s.address),
                    _row('Trạng thái', s.isActive ? 'Hoạt động' : 'Đã ẩn'),
                    _row('Ngày tạo', s.createdAt?.toLocal().toString()),
                    _row('Ngày cập nhật', s.updatedAt?.toLocal().toString()),
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
