import 'openrouter_service.dart';

class ApiConnectionTestService {
  const ApiConnectionTestService(this._openRouter);

  final OpenRouterService _openRouter;

  Future<void> test(String apiKey) {
    return _openRouter.testConnection(apiKey);
  }
}
