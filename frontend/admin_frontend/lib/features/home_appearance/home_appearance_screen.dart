import 'package:flutter/material.dart';

import 'new_product_appearance_screen.dart';
import 'featured_product_settings_screen.dart';

class HomeAppearanceScreen extends StatelessWidget {
  const HomeAppearanceScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const Material(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: TabBar(
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              tabs: [
                Tab(text: 'Sản phẩm mới'),
                Tab(text: 'Sản phẩm nổi bật'),
              ],
            ),
          ),
        ),
        const Expanded(
          child: TabBarView(
            children: [
              _KeepAliveTab(child: NewProductAppearanceScreen()),
              _KeepAliveTab(child: FeaturedProductSettingsScreen()),
            ],
          ),
        ),
      ],
    ),
  );
}

class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});
  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
