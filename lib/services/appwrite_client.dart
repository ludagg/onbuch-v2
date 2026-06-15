import 'package:appwrite/appwrite.dart';
import '../appwrite_config.dart';

class AppwriteClient {
  static final Client _client = Client()
      .setEndpoint(appwriteEndpoint)
      .setProject(appwriteProjectId)
      .setSelfSigned(status: true);

  static Client get instance => _client;
  static Account get account => Account(_client);
  static Databases get databases => Databases(_client);
  static Messaging get messaging => Messaging(_client);
}
