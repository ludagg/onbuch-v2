import 'package:appwrite/appwrite.dart';

final Client client = Client()
    .setProject('6a30463b00001375e229')
    .setEndpoint('https://nyc.cloud.appwrite.io/v1');

class AppwriteClient {
  static Client get instance => client;
  static Account get account => Account(client);
  static Databases get databases => Databases(client);
  static Messaging get messaging => Messaging(client);
}
