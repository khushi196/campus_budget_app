import 'aws_auth_service.dart';
import 'aws_session_store.dart';

AwsSessionStore createPlatformAwsSessionStore() => MemoryAwsSessionStore();

class MemoryAwsSessionStore implements AwsSessionStore {
  AwsSession? _session;

  @override
  AwsSession? loadSession() => _session;

  @override
  void saveSession(AwsSession session) {
    _session = session;
  }

  @override
  void clearSession() {
    _session = null;
  }
}
