import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv_remote/app.dart';
import 'package:tv_remote/presentation/providers/tv_provider.dart';

void main() {
  testWidgets('App renders discovery screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Prevent auto-scan from firing and changing the button label
          scanNetworkProvider.overrideWith((ref) => () async {}),
        ],
        child: const TvRemoteApp(),
      ),
    );
    await tester.pump();

    // Verify the app bar title and scan button are shown
    expect(find.text('TV Remote'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Nearby TVs'), findsOneWidget);
    expect(find.text('Saved TVs'), findsOneWidget);

    // Let any pending timers complete
    await tester.pump(const Duration(seconds: 6));
  });
}
