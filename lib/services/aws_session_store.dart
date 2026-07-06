import 'aws_auth_service.dart';
import 'aws_session_store_stub.dart'
    if (dart.library.html) 'aws_session_store_web.dart'
    if (dart.library.js_interop) 'aws_session_store_web.dart';

abstract class AwsSessionStore {
  AwsSession? loadSession();
  void saveSession(AwsSession session);
  void clearSession();
}

AwsSessionStore createAwsSessionStore() => createPlatformAwsSessionStore();
