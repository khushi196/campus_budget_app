import 'package:flutter_test/flutter_test.dart';

import 'package:campus_budget_app/services/ai_service.dart';

void main() {
  test('uses a Gemini model with available quota for the demo key', () {
    expect(GeminiAiService.defaultModel, 'gemini-flash-lite-latest');
  });

  test('sends Gemini requests through the local C++ backend proxy', () {
    expect(GeminiAiService.defaultBackendUrl, 'http://localhost:8080');
    expect(GeminiAiService.proxyPath, '/ai/gemini');
  });
}
