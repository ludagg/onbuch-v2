import 'package:appwrite/appwrite.dart';

/// Global Appwrite client for OnBuch by LudAgg.
///
/// Project details are hardcoded as required by the setup:
///   - Project ID:   6a30463b00001375e229
///   - Endpoint:     https://nyc.cloud.appwrite.io/v1
final Client client = Client()
    .setProject("6a30463b00001375e229")
    .setEndpoint("https://nyc.cloud.appwrite.io/v1");
