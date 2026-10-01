import 'package:flutter/material.dart';

import 'variant_form_dialog.dart';

class VariantEditDialog extends StatelessWidget {
  final int productId;
  final Map<String, dynamic> variant;
  const VariantEditDialog({
    super.key,
    required this.productId,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) =>
      VariantFormDialog(productId: productId, variant: variant);
}
