import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/story.dart';

class StoryItem extends StatelessWidget {
  final Story story;
  final VoidCallback onTap;

  const StoryItem({
    super.key,
    required this.story,
    required this.onTap,
  });

  // Optimized color computation with caching
  static const Map<String, List<Color>> _gradientCache = {
    'viewed': [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
    'unviewed': [Color(0xFFFF7043), Color(0xFFFF5722)],
  };

  @override
  Widget build(BuildContext context) {
    // Optimize gradient selection
    final gradientKey = (story.isOwn || !story.isViewed) ? 'unviewed' : 'viewed';
    final gradientColors = _gradientCache[gradientKey];
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradientColors != null
                        ? LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: gradientColors == null ? Colors.grey[300] : null,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                      child: Icon(
                        _getStoryIcon(),
                        color: story.isOwn ? const Color(0xFFFF7043) : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),
                ),
                if (story.mediaType == 'video' && !story.isOwn)
                  const Positioned(
                    bottom: 2,
                    right: 2,
                    child: _VideoIndicator(),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(
                _getDisplayName(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Optimized icon selection
  IconData _getStoryIcon() {
    if (story.isOwn) return Icons.add;
    return story.mediaType == 'video' ? Icons.play_circle_fill : FontAwesomeIcons.spoon;
  }

  // Optimized name display
  String _getDisplayName() {
    if (story.isOwn) return 'Your Story';
    final nameParts = story.userName.split(' ');
    return nameParts.isNotEmpty ? nameParts.first : story.userName;
  }
}

// Optimized video indicator as separate widget
class _VideoIndicator extends StatelessWidget {
  const _VideoIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFFFF7043),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: const Icon(
        Icons.videocam,
        color: Colors.white,
        size: 10,
      ),
    );
  }
}
