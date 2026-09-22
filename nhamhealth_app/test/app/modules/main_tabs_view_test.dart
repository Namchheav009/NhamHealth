import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/views/main_tabs_view.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/app/widgets/app_bottom_navigation.dart';

void main() {
  testWidgets('main tabs keep the Meals field and scroll position', (
    tester,
  ) async {
    final mounts = List<int>.filled(4, 0);
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: MainTabsView(
          initialIndex: 0,
          tabPages: [
            for (var index = 0; index < 4; index++)
              _TestTab(index: index, mounts: mounts),
          ],
        ),
      ),
    );

    expect(mounts, [1, 0, 0, 0]);
    await tester.tap(find.byKey(const ValueKey('nav-meals')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(mounts, [1, 1, 0, 0]);

    await tester.enterText(find.byKey(const ValueKey('tab-field-1')), 'oats');
    await tester.drag(
      find.byKey(const ValueKey('tab-list-1')),
      const Offset(0, -300),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final before =
        tester.state<_TestTabState>(find.byType(_TestTab)).scrollOffset;
    expect(before, greaterThan(0));

    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('nav-meals')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(mounts, [1, 1, 0, 0]);
    expect(find.text('oats'), findsOneWidget);
    final after =
        tester.state<_TestTabState>(find.byType(_TestTab)).scrollOffset;
    expect(after, closeTo(before, 0.1));
  });
}

class _TestTab extends StatefulWidget {
  const _TestTab({required this.index, required this.mounts});

  final int index;
  final List<int> mounts;

  @override
  State<_TestTab> createState() => _TestTabState();
}

class _TestTabState extends State<_TestTab> {
  final ScrollController _scrollController = ScrollController();

  double get scrollOffset => _scrollController.offset;

  @override
  void initState() {
    super.initState();
    widget.mounts[widget.index]++;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextField(key: ValueKey('tab-field-${widget.index}')),
        Expanded(
          child: ListView.builder(
            key: ValueKey('tab-list-${widget.index}'),
            controller: _scrollController,
            itemCount: 30,
            itemBuilder:
                (context, item) =>
                    SizedBox(height: 52, child: Text('Item $item')),
          ),
        ),
      ],
    ),
    bottomNavigationBar: AppBottomNavigation(
      selectedIndex: widget.index,
      onSelect: (_) {},
    ),
  );
}
