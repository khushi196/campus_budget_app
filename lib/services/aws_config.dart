class AwsConfig {
  const AwsConfig._();

  static const region = String.fromEnvironment('AWS_REGION');
  static const apiBaseUrl = String.fromEnvironment('AWS_API_BASE_URL');
  static const userPoolClientId = String.fromEnvironment(
    'AWS_USER_POOL_CLIENT_ID',
  );

  static bool get isConfigured =>
      region.isNotEmpty && apiBaseUrl.isNotEmpty && userPoolClientId.isNotEmpty;
}
