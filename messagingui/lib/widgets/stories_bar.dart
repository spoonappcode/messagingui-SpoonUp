import 'package:flutter/material.dart';
import '../models/story.dart';
import 'story_item.dart';
import 'story_viewer.dart';

class StoriesBar extends StatefulWidget {
  final List<Story> stories;

  const StoriesBar({
    super.key,
    required this.stories,
  });

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  late List<Story> _stories;

  @override
  void initState() {
    super.initState();
    _stories = List.from(widget.stories);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF3E0),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFFF7043),
            width: 0.3,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];
          return StoryItem(
            story: story,
            onTap: () => _viewStory(story, index),
          );
        },
      ),
    );
  }

  void _viewStory(Story story, int index) {
    if (story.isOwn) {
      // Handle "Add Story" action for own story
      _showAddStoryDialog();
      return;
    }

    // Filter out own stories for viewing sequence
    final viewableStories = _stories.where((s) => !s.isOwn).toList();
    if (viewableStories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No stories available to view'),
          backgroundColor: Color(0xFFFF7043),
        ),
      );
      return;
    }
    
    final viewableIndex = viewableStories.indexWhere((s) => s.id == story.id);
    if (viewableIndex == -1) return;

    // Show full-screen story viewer with navigation
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            StoryViewer(
              stories: viewableStories,
              initialIndex: viewableIndex,
              onStoryViewed: (storyId) => _markStoryAsViewedById(storyId),
              onComplete: () {
                // Mark all viewed stories when exiting
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    // Mark current story as viewed immediately when opened
    _markStoryAsViewedById(story.id);
  }

  void _markStoryAsViewed(int index) {
    if (index < _stories.length && !_stories[index].isViewed) {
      setState(() {
        _stories[index] = _stories[index].copyWith(isViewed: true);
      });
    }
  }

  void _markStoryAsViewedById(String storyId) {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1 && !_stories[index].isViewed) {
      setState(() {
        _stories[index] = _stories[index].copyWith(isViewed: true);
      });
    }
  }

  void _showAddStoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_a_photo,
                color: Color(0xFFFF7043),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add to Story',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Share your cooking moments with other food lovers!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _simulateAddStory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7043),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            label: const Text(
              'Add Photo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateAddStory() {
    // Simulate adding a new story
    final newStory = Story(
      id: 'story_new_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_own',
      userName: 'Your Story',
      mediaUrl: 'https://via.placeholder.com/400x600/FF7043/FFFFFF?text=New+Recipe',
      mediaType: 'image',
      timestamp: DateTime.now(),
      isOwn: true,
      isViewed: false,
    );

    setState(() {
      // Replace the "Add Story" placeholder with actual story
      final ownStoryIndex = _stories.indexWhere((story) => story.isOwn);
      if (ownStoryIndex != -1) {
        _stories[ownStoryIndex] = newStory;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Story added successfully!'),
          ],
        ),
        backgroundColor: Color(0xFFFF7043),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
