class ReturnOrderSummary {
  final int orderId, totalRequests, pendingRequests;
  final String orderCode, recipientName, recipientPhone;
  final num totalAmount;
  final DateTime latestRequestAt;
  final List<String> statuses;

  ReturnOrderSummary(Map<String, dynamic> json)
    : orderId = (json['orderId'] as num).toInt(),
      orderCode = json['orderCode'] as String,
      recipientName = json['recipientName'] as String,
      recipientPhone = json['recipientPhone'] as String,
      totalAmount = json['totalAmount'] as num,
      latestRequestAt = DateTime.parse(json['latestRequestAt'] as String)
          .toLocal(),
      totalRequests = (json['totalRequests'] as num).toInt(),
      pendingRequests = (json['pendingRequests'] as num).toInt(),
      statuses = (json['statuses'] as List).cast<String>();
}
