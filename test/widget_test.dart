import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dipl/main.dart';

void main() {
  testWidgets('shows splash logo on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
