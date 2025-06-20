import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/story.dart';
import 'story_item.dart';
import 'story_viewer.dart';
import 'story_replies_bottom_sheet.dart';
import '../models/story_reply.dart';

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
  List<StoryReply> _storyReplies = [];

  @override
  void initState() {
    super.initState();
    _stories = List.from(widget.stories);
    _storyReplies = StoryReply.getSampleReplies();
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
      // Show options for own story
      _showOwnStoryOptions(story);
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

  void _showOwnStoryOptions(Story story) {
    final storyReplies = _storyReplies
        .where((reply) => reply.storyId == story.id)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7043).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.spoon,
                    color: Color(0xFFFF7043),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Your Story',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // View replies option
            _buildStoryOption(
              icon: Icons.reply_all,
              title: 'View Replies',
              subtitle: '${storyReplies.length} ${storyReplies.length == 1 ? 'reply' : 'replies'}',
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.pop(context);
                _showStoryReplies(story);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Add to story option
            _buildStoryOption(
              icon: Icons.add_a_photo,
              title: 'Add to Story',
              subtitle: 'Share another moment',
              color: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.pop(context);
                _simulateAddStory();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Delete story option
            _buildStoryOption(
              icon: Icons.delete_outline,
              title: 'Delete Story',
              subtitle: 'Remove this story',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteStory(story);
              },
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryReplies(Story story) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: StoryRepliesBottomSheet(
          storyId: story.id,
          storyOwnerName: story.userName,
          replies: _storyReplies,
          onReplyTap: (reply) {
            Navigator.pop(context);
            // Navigate to chat with the person who replied
            _showSnackBar('Opening chat with ${reply.senderName}');
          },
        ),
      ),
    );
  }

  void _confirmDeleteStory(Story story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Delete Story',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this story? This action cannot be undone.',
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStory(story);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Delete',
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

  void _deleteStory(Story story) {
    setState(() {
      _stories.removeWhere((s) => s.id == story.id);
      // Also remove associated replies
      _storyReplies.removeWhere((reply) => reply.storyId == story.id);
    });
    
    _showSnackBar('Story deleted');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF7043),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
