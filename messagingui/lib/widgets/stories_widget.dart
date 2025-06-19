import 'package:flutter/material.dart';
import '../models/story.dart';

class StoriesWidget extends StatefulWidget {
  const StoriesWidget({super.key});

  @override
  State<StoriesWidget> createState() => _StoriesWidgetState();
}

class _StoriesWidgetState extends State<StoriesWidget> {
  List<Story> stories = Story.getSampleStories();

  void _addStory() {
    // Simulate adding a new story
    setState(() {
      stories.insert(0, Story(
        id: 'story_new_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_own',
        userName: 'Your Story',
        mediaUrl: 'https://via.placeholder.com/150/FF7043/FFFFFF?text=New+Story',
        mediaType: 'image',
        timestamp: DateTime.now(),
        isOwn: true,
        isViewed: false,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildStoryItem(story),
          );
        },
      ),
    );
  }

  Widget _buildStoryItem(Story story) {
    return GestureDetector(
      onTap: story.isOwn ? _addStory : () => _viewStory(story),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: story.isViewed 
                    ? Colors.grey.shade300 
                    : const Color(0xFFFF7043),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: story.isOwn && story.mediaUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFFFF3E0),
                      child: const Icon(
                        Icons.add,
                        color: Color(0xFFFF7043),
                        size: 24,
                      ),
                    )
                  : story.mediaUrl.isNotEmpty
                      ? Image.network(
                          story.mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFFFF3E0),
                              child: Icon(
                                Icons.person,
                                color: const Color(0xFFFF7043).withOpacity(0.8),
                                size: 24,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFFFF3E0),
                          child: Icon(
                            Icons.person,
                            color: const Color(0xFFFF7043).withOpacity(0.8),
                            size: 24,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              story.userName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _viewStory(Story story) {
    // Mark story as viewed
    setState(() {
      final index = stories.indexWhere((s) => s.id == story.id);
      if (index != -1) {
        stories[index] = story.copyWith(isViewed: true);
      }
    });
    
    // Show story viewer (you can implement a full-screen story viewer here)
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                story.userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: story.mediaUrl.isNotEmpty
                    ? Image.network(
                        story.mediaUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFFFF3E0),
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Color(0xFFFF7043),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFFFFF3E0),
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Color(0xFFFF7043),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
