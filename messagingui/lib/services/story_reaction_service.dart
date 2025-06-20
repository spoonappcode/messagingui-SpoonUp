import '../models/message.dart';

class StoryReactionService {
  static final StoryReactionService _instance = StoryReactionService._internal();
  factory StoryReactionService() => _instance;
  StoryReactionService._internal();

  // Optimized callback management
  Function(Message, String)? _onReactionSent;
  
  // Cache for chat ID mapping
  final Map<String, String> _chatIdCache = {};

  void setReactionCallback(Function(Message, String) callback) {
    _onReactionSent = callback;
  }

  void sendStoryReaction({
    required String storyId,
    required String storyOwnerId,
    required String storyOwnerName,
    required String reaction,
    required String currentUserId,
    required String currentUserName,
  }) {
    // Create optimized reaction message
    final reactionMessage = Message(
      id: 'reaction_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId,
      senderName: currentUserName,
      content: reaction,
      timestamp: DateTime.now(),
      isFromCurrentUser: true, // Aggiunto questo parametro
      type: MessageType.storyReaction,
      storyId: storyId,
      storyOwnerName: storyOwnerName,
    );

    // Get cached chat ID or compute new one
    final chatId = _getCachedChatId(storyOwnerId, storyOwnerName);
    
    // Notify callback if set
    _onReactionSent?.call(reactionMessage, chatId);
  }

  String _getCachedChatId(String userId, String userName) {
    final key = '${userId}_$userName';
    return _chatIdCache.putIfAbsent(
      key, 
      () => 'chat_${userName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
    );
  }

  static String formatReactionMessage(String reaction, String storyOwnerName, bool isFromCurrentUser) {
    return isFromCurrentUser
        ? 'You reacted $reaction to $storyOwnerName\'s story'
        : 'Reacted $reaction to your story';
  }
  
  // Utility method to clear cache if needed
  void clearCache() {
    _chatIdCache.clear();
  }
}
