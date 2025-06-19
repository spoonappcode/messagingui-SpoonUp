class Story {
  final String id;
  final String userId;
  final String userName;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final DateTime timestamp;
  final bool isViewed;
  final bool isOwn;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.mediaUrl,
    required this.mediaType,
    required this.timestamp,
    this.isViewed = false,
    this.isOwn = false,
  });

  // Copy with method for updating stories
  Story copyWith({
    String? id,
    String? userId,
    String? userName,
    String? mediaUrl,
    String? mediaType,
    DateTime? timestamp,
    bool? isViewed,
    bool? isOwn,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      timestamp: timestamp ?? this.timestamp,
      isViewed: isViewed ?? this.isViewed,
      isOwn: isOwn ?? this.isOwn,
    );
  }

  // Sample stories for testing
  static List<Story> getSampleStories() {
    return [
      Story(
        id: 'story_own',
        userId: 'user_own',
        userName: 'Your Story',
        mediaUrl: 'https://via.placeholder.com/150/FFB6C1/FFFFFF?text=Your+Story',
        mediaType: 'image',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isOwn: true,
        isViewed: false,
      ),
      Story(
        id: 'story_1',
        userId: '1',
        userName: 'Mario Rossi',
        mediaUrl: 'https://via.placeholder.com/150/FFB6C1/FFFFFF?text=Mario',
        mediaType: 'image',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isViewed: false,
      ),
      Story(
        id: 'story_2',
        userId: '3',
        userName: 'Anna Smith',
        mediaUrl: 'https://via.placeholder.com/150/FFB6C1/FFFFFF?text=Anna',
        mediaType: 'video',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isViewed: true,
      ),
      Story(
        id: 'story_3',
        userId: '5',
        userName: 'Luke Green',
        mediaUrl: 'https://via.placeholder.com/150/FFB6C1/FFFFFF?text=Luke',
        mediaType: 'image',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isViewed: false,
      ),
      Story(
        id: 'story_4',
        userId: '7',
        userName: 'Sofia Black',
        mediaUrl: 'https://via.placeholder.com/150/FFB6C1/FFFFFF?text=Sofia',
        mediaType: 'image',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isViewed: false,
      ),
    ];
  }
}
