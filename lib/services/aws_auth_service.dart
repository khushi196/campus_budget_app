import 'dart:convert';

import 'package:http/http.dart' as http;

class AwsSession {
  const AwsSession({
    required this.accessToken,
    required this.idToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String idToken;
  final String refreshToken;

  factory AwsSession.fromJson(Map<String, dynamic> json) {
    return AwsSession(
      accessToken: json['accessToken'] as String? ?? '',
      idToken: json['idToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'idToken': idToken,
      'refreshToken': refreshToken,
    };
  }

  bool get isValid => accessToken.isNotEmpty && idToken.isNotEmpty;
}

class AwsAuthService {
  AwsAuthService({
    required this.region,
    required this.userPoolClientId,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String region;
  final String userPoolClientId;
  final http.Client _client;

  Uri get _endpoint => Uri.parse('https://cognito-idp.$region.amazonaws.com/');

  Future<void> signUp({required String email, required String password}) async {
    await _send(
      target: 'AWSCognitoIdentityProviderService.SignUp',
      body: {
        'ClientId': userPoolClientId,
        'Username': email,
        'Password': password,
        'UserAttributes': [
          {'Name': 'email', 'Value': email},
        ],
      },
    );
  }

  Future<void> confirmSignUp({
    required String email,
    required String code,
  }) async {
    await _send(
      target: 'AWSCognitoIdentityProviderService.ConfirmSignUp',
      body: {
        'ClientId': userPoolClientId,
        'Username': email,
        'ConfirmationCode': code,
      },
    );
  }

  Future<void> forgotPassword({required String email}) async {
    await _send(
      target: 'AWSCognitoIdentityProviderService.ForgotPassword',
      body: {'ClientId': userPoolClientId, 'Username': email},
    );
  }

  Future<void> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _send(
      target: 'AWSCognitoIdentityProviderService.ConfirmForgotPassword',
      body: {
        'ClientId': userPoolClientId,
        'Username': email,
        'ConfirmationCode': code,
        'Password': newPassword,
      },
    );
  }

  Future<AwsSession> signIn({
    required String email,
    required String password,
  }) async {
    final decoded = await _send(
      target: 'AWSCognitoIdentityProviderService.InitiateAuth',
      body: {
        'ClientId': userPoolClientId,
        'AuthFlow': 'USER_PASSWORD_AUTH',
        'AuthParameters': {'USERNAME': email, 'PASSWORD': password},
      },
    );

    final result = decoded['AuthenticationResult'] as Map<String, dynamic>;
    return AwsSession(
      accessToken: result['AccessToken'] as String,
      idToken: result['IdToken'] as String,
      refreshToken: result['RefreshToken'] as String,
    );
  }

  Future<Map<String, dynamic>> _send({
    required String target,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/x-amz-json-1.1',
            'X-Amz-Target': target,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 400) {
      throw AwsAuthException(response.body);
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}

class AwsAuthException implements Exception {
  const AwsAuthException(this.message);

  final String message;

  @override
  String toString() => 'AwsAuthException: $message';
}
