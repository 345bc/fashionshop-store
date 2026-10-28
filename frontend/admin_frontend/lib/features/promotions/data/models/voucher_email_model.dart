class VoucherEmailRecipientModel {
  final String name, email, tier;
  const VoucherEmailRecipientModel({
    required this.name,
    required this.email,
    required this.tier,
  });

  factory VoucherEmailRecipientModel.fromJson(Map<String, dynamic> json) =>
      VoucherEmailRecipientModel(
        name: json['name'] as String? ?? '',
        email: json['email'] as String,
        tier: json['tier'] as String,
      );
}

class VoucherEmailPreview {
  final int eligible, alreadyQueued, invalidEmails, toQueue;
  final int? remainingUses;
  final String audienceKey, subject, emailBody;
  final List<VoucherEmailRecipientModel> sample;
  const VoucherEmailPreview({
    required this.eligible,
    required this.alreadyQueued,
    required this.invalidEmails,
    required this.toQueue,
    required this.remainingUses,
    required this.audienceKey,
    required this.subject,
    required this.emailBody,
    required this.sample,
  });

  factory VoucherEmailPreview.fromJson(Map<String, dynamic> json) =>
      VoucherEmailPreview(
        eligible: (json['eligible'] as num).toInt(),
        alreadyQueued: (json['alreadyQueued'] as num).toInt(),
        invalidEmails: (json['invalidEmails'] as num).toInt(),
        toQueue: (json['toQueue'] as num).toInt(),
        remainingUses: (json['remainingUses'] as num?)?.toInt(),
        audienceKey: json['audienceKey'] as String,
        subject: json['subject'] as String,
        emailBody: json['emailBody'] as String,
        sample: [
          for (final recipient in json['sample'] as List)
            VoucherEmailRecipientModel.fromJson(
              Map<String, dynamic>.from(recipient),
            ),
        ],
      );
}

class VoucherEmailSendResult {
  final int queued, alreadyQueued;
  const VoucherEmailSendResult(this.queued, this.alreadyQueued);
  factory VoucherEmailSendResult.fromJson(Map<String, dynamic> json) =>
      VoucherEmailSendResult(
        (json['queued'] as num).toInt(),
        (json['alreadyQueued'] as num).toInt(),
      );
}
