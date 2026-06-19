import 'package:flutter_test/flutter_test.dart';

import 'package:path_of_kings/main.dart';

void main() {
  testWidgets('앱이 정상적으로 빌드된다', (WidgetTester tester) async {
    await tester.pumpWidget(const PathOfKingsApp());
    await tester.pump();
    // 상단 구역 라벨이 보이는지 확인
    expect(find.textContaining('구역'), findsOneWidget);
  });
}
