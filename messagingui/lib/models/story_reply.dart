class StoryReply {
  final String id;
  final String storyId;
  final String storyOwnerId;
  final String storyOwnerName;
  final String senderId;
  final String senderName;
  final String content;
  final StoryReplyType type;
  final DateTime timestamp;
  final bool isRead;

  StoryReply({
    required this.id,
    required this.storyId,
    required this.storyOwnerId,
    required this.storyOwnerName,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  bool get isFromCurrentUser => senderId == 'current_user';

  StoryReply copyWith({
    String? id,
    String? storyId,
    String? storyOwnerId,
    String? storyOwnerName,
    String? senderId,
    String? senderName,
    String? content,
    StoryReplyType? type,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return StoryReply(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      storyOwnerId: storyOwnerId ?? this.storyOwnerId,
      storyOwnerName: storyOwnerName ?? this.storyOwnerName,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  // Convert to chat message format
  String toChatMessage() {
    switch (type) {
      case StoryReplyType.reaction:
        return 'Reacted with $content to your story';
      case StoryReplyType.text:
        return 'Replied to your story: "$content"';
      default:
        return content;
    }
  }

  // Sample story replies for testing
  static List<StoryReply> getSampleReplies() {
    final now = DateTime.now();
    return [
      StoryReply(
        id: 'reply_1',
        storyId: 'story_1',
        storyOwnerId: '1',
        storyOwnerName: 'Mario Rossi',
        senderId: 'current_user',
        senderName: 'You',
        content: 'Looks delicious! 😋',
        type: StoryReplyType.text,
        timestamp: now.subtract(const Duration(minutes: 10)),
      ),
      StoryReply(
        id: 'reply_2',
        storyId: 'story_2',
        storyOwnerId: '3',
        storyOwnerName: 'Anna Smith',
        senderId: 'current_user',
        senderName: 'You',
        content: '❤️',
        type: StoryReplyType.reaction,
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      StoryReply(
        id: 'reply_3',
        storyId: 'story_own',
        storyOwnerId: 'current_user',
        storyOwnerName: 'You',
        senderId: '1',
        senderName: 'Mario Rossi',
        content: 'Great recipe! Can you share the ingredients?',
        type: StoryReplyType.text,
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
    ];
  }
}

enum StoryReplyType {
  text,
  reaction,
  voice,
}
