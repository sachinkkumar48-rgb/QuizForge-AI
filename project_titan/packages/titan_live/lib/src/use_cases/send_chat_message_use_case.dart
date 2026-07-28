import '../models/live_models.dart';
import '../repository/live_class_repository.dart';

/// Use case for sending a chat message during a live class.
class SendChatMessageUseCase {
  final LiveClassRepository repository;

  const SendChatMessageUseCase(this.repository);

  Future<ChatMessage> execute(ChatMessage message) {
    return repository.sendChatMessage(message);
  }
}
