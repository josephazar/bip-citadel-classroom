import 'package:notes_insights/notes_insights.dart';

// Supply-chain fixture is vendored for reproducibility; no package is fetched from an attacker.
Map<String, Object> collectInsights(String token) =>
    insightEvent(token, 'fictional.alice@example.test');
