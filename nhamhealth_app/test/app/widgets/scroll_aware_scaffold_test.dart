import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/widgets/app_bottom_navigation.dart';
import 'package:nhamhealth_flutter/app/widgets/scroll_aware_scaffold.dart';

void main() {
  testWidgets('pins header, hides nav items, and keeps chatbot visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: ScrollAwareScaffold(
          body: Column(
            children: [
              const SizedBox(
                key: ValueKey<String>('sticky-header'),
                height: 64,
                child: Text('Header'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 40,
                  itemBuilder:
                      (context, index) =>
                          SizedBox(height: 56, child: Text('Item $index')),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: AppBottomNavigation(selectedIndex: 0, onSelect: (_) {}),
          ),
        ),
      ),
    );

    final header = find.byKey(const ValueKey<String>('sticky-header'));
    final navigation = find.byKey(
      const ValueKey<String>('scroll-aware-navigation-items'),
    );
    final chatbot = find.byKey(const ValueKey<String>('nav-chatbot'));
    final initialHeaderPosition = tester.getTopLeft(header);
    final initialChatbotPosition = tester.getTopLeft(chatbot);

    expect(tester.widget<AnimatedSlide>(navigation).offset, Offset.zero);

    await tester.drag(find.byType(ListView), const Offset(0, -280));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.getTopLeft(header), initialHeaderPosition);
    expect(tester.getTopLeft(chatbot), initialChatbotPosition);
    expect(chatbot, findsOneWidget);
    expect(tester.widget<AnimatedSlide>(navigation).offset.dy, greaterThan(1));

    await tester.drag(find.byType(ListView), const Offset(0, 160));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.getTopLeft(header), initialHeaderPosition);
    expect(tester.widget<AnimatedSlide>(navigation).offset, Offset.zero);
    expect(tester.takeException(), isNull);
  });
}
