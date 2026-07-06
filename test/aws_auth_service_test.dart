import 'package:flutter_test/flutter_test.dart';

import 'package:campus_budget_app/services/aws_auth_service.dart';

void main() {
  test('serializes and restores an AWS session', () {
    const session = AwsSession(
      accessToken: 'access-token',
      idToken: 'id-token',
      refreshToken: 'refresh-token',
    );

    final restored = AwsSession.fromJson(session.toJson());

    expect(restored.accessToken, 'access-token');
    expect(restored.idToken, 'id-token');
    expect(restored.refreshToken, 'refresh-token');
  });
}
