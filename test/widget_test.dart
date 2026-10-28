import 'package:flutter_test/flutter_test.dart';
import 'package:acitivy2mc/main.dart';
import 'package:acitivy2mc/services/network_monitor_service.dart';
import 'package:acitivy2mc/services/request_queue_manager.dart';

void main() {
  setUp(() async {
    await NetworkMonitorService.instance.initialize();
    RequestQueueManager.instance.initialize();
  });

  testWidgets('App displays master compilation home screen with activity card', (WidgetTester tester) async {
    await tester.pumpWidget(const MasterCompilationApp());
    await tester.pump();

    // Verify home screen title and activity card exist
    expect(find.text('Mobile Computing Master App'), findsOneWidget);
    expect(find.text('Active Network Monitor & Handover Handling'), findsOneWidget);
    expect(find.text('Activity 2 (Featured)'), findsOneWidget);
  });
}
