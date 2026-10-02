const orderStatuses = {
  'PENDING': 'Chờ thanh toán',
  'CONFIRMED': 'Đã xác nhận',
  'SHIPPED': 'Đã xuất kho',
  'DELIVERED': 'Đã giao',
  'CANCELLED': 'Đã hủy',
  'RETURNED': 'Đã nhận lại kiện hàng',
};
const orderPaymentStatuses = {
  'PENDING': 'Chờ thanh toán online',
  'EXPIRED': 'Hết hạn thanh toán',
  'PAID': 'Đã thu tiền',
  'REFUND_PENDING': 'Chờ hoàn tiền',
  'REFUNDED': 'Đã hoàn tiền',
};
const returnStatuses = {
  'PENDING': 'Chờ duyệt',
  'APPROVED': 'Đã duyệt',
  'REJECTED': 'Từ chối',
  'RECEIVED': 'Đã nhận hàng',
  'COMPLETED': 'Hoàn tất',
  'CANCELLED': 'Đã hủy',
};

class OrderResponseModel {
  final int id;
  final int? customerUserId;
  final String code,
      customerName,
      recipientName,
      recipientPhone,
      address,
      status,
      paymentStatus,
      paymentMethod;
  final String? note;
  final bool inventoryManaged;
  final num subtotal, shippingFee, totalAmount;
  final DateTime createdAt;
  final DateTime? paymentExpiresAt;
  final List<Map<String, dynamic>> items, histories;
  OrderResponseModel(Map<String, dynamic> j)
    : id = j['id'] as int,
      customerUserId = j['customerUserId'] as int?,
      code = j['code'] as String,
      customerName = j['customerName'] as String,
      recipientName = j['recipientName'] as String,
      recipientPhone = j['recipientPhone'] as String,
      address = j['address'] as String,
      status = j['status'] as String,
      paymentStatus = j['paymentStatus'] as String,
      paymentMethod = j['paymentMethod'] as String,
      note = j['note'] as String?,
      inventoryManaged = j['inventoryManaged'] as bool,
      subtotal = j['subtotal'] as num,
      shippingFee = j['shippingFee'] as num,
      totalAmount = j['totalAmount'] as num,
      createdAt = DateTime.parse(j['createdAt'] as String).toLocal(),
      paymentExpiresAt = j['paymentExpiresAt'] == null
          ? null
          : DateTime.parse(j['paymentExpiresAt'] as String).toLocal(),
      items = (j['items'] as List).cast<Map<String, dynamic>>(),
      histories = (j['histories'] as List).cast<Map<String, dynamic>>();
}

class ReturnResponseModel {
  final int id, orderId;
  final String code, orderCode, status, reason;
  final String? adminNote, refundMethod;
  final num refundAmount;
  final List<Map<String, dynamic>> items, histories;
  ReturnResponseModel(Map<String, dynamic> j)
    : id = j['id'] as int,
      orderId = j['orderId'] as int,
      code = j['code'] as String,
      orderCode = j['orderCode'] as String,
      status = j['status'] as String,
      reason = j['reason'] as String,
      adminNote = j['adminNote'] as String?,
      refundMethod = j['refundMethod'] as String?,
      refundAmount = j['refundAmount'] as num,
      items = (j['items'] as List).cast<Map<String, dynamic>>(),
      histories = (j['histories'] as List).cast<Map<String, dynamic>>();
}
