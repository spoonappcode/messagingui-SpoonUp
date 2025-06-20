enum MessageType {
  text,
  image,
  video,
  voice,
  recipe,
  storyReaction,
}

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isFromCurrentUser;
  final bool isRead;
  final bool isSent;
  final MessageType type;
  final String? mediaUrl;
  final String? storyId;
  final String? storyOwnerName;
  final Message? replyToMessage;
  final bool isReply;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isFromCurrentUser = false,
    this.isRead = false,
    this.isSent = true,
    this.type = MessageType.text,
    this.mediaUrl,
    this.storyId,
    this.storyOwnerName,
    this.replyToMessage,
  }) : isReply = replyToMessage != null;

  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    bool? isFromCurrentUser,
    bool? isRead,
    bool? isSent,
    MessageType? type,
    String? mediaUrl,
    String? storyId,
    String? storyOwnerName,
    Message? replyToMessage,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
      isRead: isRead ?? this.isRead,
      isSent: isSent ?? this.isSent,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      storyId: storyId ?? this.storyId,
      storyOwnerName: storyOwnerName ?? this.storyOwnerName,
      replyToMessage: replyToMessage ?? this.replyToMessage,
    );
  }

  // Optimized sample messages with lazy loading and caching
  static final Map<String, List<Message>> _messageCache = {};
  
  static List<Message> getSampleMessages(String chatId) {
    // Return cached messages if available
    if (_messageCache.containsKey(chatId)) {
      return _messageCache[chatId]!;
    }
    
    final now = DateTime.now();
    final messages = [
      Message(
        id: 'msg1_$chatId',
        senderId: chatId,
        senderName: 'Mario Rossi',
        content: 'Ciao! Ho provato la tua ricetta della carbonara ed è fantastica! 🍝',
        timestamp: now.subtract(const Duration(hours: 2)),
        isFromCurrentUser: false,
      ),
      Message(
        id: 'msg2_$chatId',
        senderId: 'current_user',
        senderName: 'You',
        content: 'Grazie! Sono felice che ti sia piaciuta. Hai usato il guanciale?',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 50)),
        isFromCurrentUser: true,
      ),
      Message(
        id: 'msg3_$chatId',
        senderId: chatId,
        senderName: 'Mario Rossi',
        content: 'Sì, ho trovato del guanciale fantastico al mercato. Che differenza rispetto alla pancetta!',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        isFromCurrentUser: false,
      ),
      Message(
        id: 'msg4_$chatId',
        senderId: 'current_user',
        senderName: 'You',
        content: 'Esatto! Il guanciale rende tutto più autentico. Hai altri piatti che vorresti imparare?',
        timestamp: now.subtract(const Duration(hours: 1)),
        isFromCurrentUser: true,
      ),
      Message(
        id: 'msg5_$chatId',
        senderId: chatId,
        senderName: 'Mario Rossi',
        content: 'Mi piacerebbe imparare a fare un buon risotto. Hai qualche consiglio?',
        timestamp: now.subtract(const Duration(minutes: 30)),
        isFromCurrentUser: false,
      ),
      Message(
        id: 'msg6_$chatId',
        senderId: 'current_user',
        senderName: 'You',
        content: 'Certamente! Il segreto è nella mantecatura finale. Ti mando una foto del mio risotto ai funghi 📸',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isFromCurrentUser: true,
        type: MessageType.image,
        mediaUrl: 'https://picsum.photos/400/300?random=1',
      ),
      Message(
        id: 'msg7_$chatId',
        senderId: chatId,
        senderName: 'Mario Rossi',
        content: 'Wow! Sembra delizioso. Non vedo l\'ora di provare! 😍',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isFromCurrentUser: false,
      ),
    ];
    
    // Cache the messages for better performance
    _messageCache[chatId] = messages;
    return messages;
  }
  
  // Utility method to clear cache if needed
  static void clearMessageCache() {
    _messageCache.clear();
  }
}
