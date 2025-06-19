class Chat {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String avatarUrl;
  final int unreadCount;
  final String cookingLevel; // "Novice", "Home Cook", "Chef", "Master Chef"
  final bool isOnline;
  final bool isFavorite;
  final bool isMuted;

  Chat({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.avatarUrl,
    this.unreadCount = 0,
    required this.cookingLevel,
    this.isOnline = false,
    this.isFavorite = false,
    this.isMuted = false,
  });

  Chat copyWith({
    String? id,
    String? name,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? avatarUrl,
    int? unreadCount,
    String? cookingLevel,
    bool? isOnline,
    bool? isFavorite,
    bool? isMuted,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unreadCount: unreadCount ?? this.unreadCount,
      cookingLevel: cookingLevel ?? this.cookingLevel,
      isOnline: isOnline ?? this.isOnline,
      isFavorite: isFavorite ?? this.isFavorite,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  // Sample data for testing
  static List<Chat> getSampleChats() {
    return [
      Chat(
        id: '1',
        name: 'Mario Rossi',
        lastMessage: 'I tried your carbonara recipe! 🍝',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        avatarUrl: '',
        unreadCount: 2,
        cookingLevel: 'Chef',
        isOnline: true,
      ),
      Chat(
        id: '2',
        name: 'Italian Cooking Group',
        lastMessage: 'Anyone has a good tiramisu recipe?',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
        avatarUrl: '',
        unreadCount: 0,
        cookingLevel: 'Home Cook',
        isOnline: false,
      ),
      Chat(
        id: '3',
        name: 'Chef Antonella',
        lastMessage: 'Tonight I\'ll teach how to make fresh pasta',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
        avatarUrl: '',
        unreadCount: 1,
        cookingLevel: 'Master Chef',
        isOnline: true,
      ),
      Chat(
        id: '4',
        name: 'Quick Recipes',
        lastMessage: 'Aglio e olio pasta in 10 minutes! ⚡',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        avatarUrl: '',
        unreadCount: 0,
        cookingLevel: 'Novice',
        isOnline: false,
      ),
    ];
  }
}
