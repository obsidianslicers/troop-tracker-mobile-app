import 'package:flutter_dotenv/flutter_dotenv.dart';

const testTrackerUrl = 'https://tracker.example.org/';

/// Loads the .env values tests run with, instead of the developer's .env.
void loadTestEnv({String trackerUrl = testTrackerUrl, String internalDomains = ''}) {
  dotenv.testLoad(fileInput: 'TRACKER_URL=$trackerUrl\nINTERNAL_DOMAINS=$internalDomains');
}
