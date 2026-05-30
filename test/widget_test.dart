import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv_remote/app.dart';

void main() {
  testWidgets('App renders discovery screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TvRemoteApp()),
    );
    await tester.pump();

    // Verify the app bar title and scan button are shown
    expect(find.text('TV Remote'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Nearby TVs'), findsOneWidget);
    expect(find.text('Saved TVs'), findsOneWidget);

    // Let SSDP discovery timer complete
    await tester.pump(const Duration(seconds: 6));
  });
}
