import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';

enum AttributeKind {
  color('Màu sắc', 'Màu', '/color', Symbols.palette),
  size('Size', 'Size', '/size', Symbols.straighten),
  sizeGuide('Size Guide', 'Size Guide', '/sizeguide', Symbols.menu_book);

  const AttributeKind(this.title, this.singular, this.path, this.icon);
  final String title;
  final String singular;
  final String path;
  final IconData icon;
}
