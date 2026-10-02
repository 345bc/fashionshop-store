const receiptStatuses = {
  'DRAFT': 'Nháp',
  'POSTED': 'Đã nhập kho',
  'CANCELLED': 'Đã hủy',
};
const paymentStatuses = {
  'UNPAID': 'Chưa trả',
  'PARTIAL': 'Trả một phần',
  'PAID': 'Đã trả đủ',
};

class GoodsReceiptResponseModel {
  final int id, supplierId;
  final String code, supplierName, status, paymentStatus;
  final num totalAmount, paidAmount, remainingAmount;
  final num returnedAmount, supplierRefundedAmount, supplierRefundDue;
  final String? note, createdBy, postedBy;
  final DateTime createdAt;
  final List<Map<String, dynamic>> items, payments;
  final List<Map<String, dynamic>> returns, refunds;
  GoodsReceiptResponseModel(Map<String, dynamic> j)
    : id = j['id'] as int,
      supplierId = j['supplierId'] as int,
      code = j['code'] as String,
      supplierName = j['supplierName'] as String,
      status = j['status'] as String,
      paymentStatus = j['paymentStatus'] as String,
      totalAmount = j['totalAmount'] as num,
      paidAmount = j['paidAmount'] as num,
      remainingAmount = j['remainingAmount'] as num,
      returnedAmount = j['returnedAmount'] as num? ?? 0,
      supplierRefundedAmount = j['supplierRefundedAmount'] as num? ?? 0,
      supplierRefundDue = j['supplierRefundDue'] as num? ?? 0,
      returns = (j['returns'] as List? ?? []).cast<Map<String, dynamic>>(),
      refunds = (j['refunds'] as List? ?? []).cast<Map<String, dynamic>>(),
      note = j['note'] as String?,
      createdBy = j['createdBy'] as String?,
      postedBy = j['postedBy'] as String?,
      createdAt = DateTime.parse(j['createdAt'] as String).toLocal(),
      items = (j['items'] as List).cast<Map<String, dynamic>>(),
      payments = (j['payments'] as List).cast<Map<String, dynamic>>();
}
