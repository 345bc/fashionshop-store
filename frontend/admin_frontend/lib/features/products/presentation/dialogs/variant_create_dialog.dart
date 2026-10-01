import 'package:flutter/material.dart';

import 'variant_form_dialog.dart';

class VariantCreateDialog extends StatelessWidget {
  final int productId;
  const VariantCreateDialog({super.key, required this.productId});

  @override
  Widget build(BuildContext context) => VariantFormDialog(productId: productId);
}
