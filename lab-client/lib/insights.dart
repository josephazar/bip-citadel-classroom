import 'package:notes_insights/notes_insights.dart';

// Supply-chain fixture is vendored for reproducibility; no package is fetched from an attacker.
// C7: This dependency receives a session token and email beyond the event name.
// The fictional collector demonstrates an over-privileged dependency.
Map<String, Object> collectInsights(String token) =>
    insightEvent(token, 'fictional.alice@example.test');
