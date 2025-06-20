import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/story_reply.dart';

class StoryRepliesBottomSheet extends StatefulWidget {
  final String storyId;
  final String storyOwnerName;
  final List<StoryReply> replies;
  final Function(StoryReply)? onReplyTap;

  const StoryRepliesBottomSheet({
    super.key,
    required this.storyId,
    required this.storyOwnerName,
    required this.replies,
    this.onReplyTap,
  });

  @override
  State<StoryRepliesBottomSheet> createState() => _StoryRepliesBottomSheetState();
}

class _StoryRepliesBottomSheetState extends State<StoryRepliesBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final storyReplies = widget.replies
        .where((reply) => reply.storyId == widget.storyId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Container(
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
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7043).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.reply,
                    color: Color(0xFFFF7043),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Story Replies',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      Text(
                        '${storyReplies.length} ${storyReplies.length == 1 ? 'reply' : 'replies'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Replies list
          Flexible(
            child: storyReplies.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: storyReplies.length,
                    itemBuilder: (context, index) {
                      final reply = storyReplies[index];
                      return _buildReplyItem(reply);
                    },
                  ),
          ),
          
          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No replies yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When people reply to your story, they\'ll appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(StoryReply reply) {
    return InkWell(
      onTap: () => widget.onReplyTap?.call(reply),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: reply.isFromCurrentUser
                      ? [const Color(0xFFFF7043), const Color(0xFFFF5722)]
                      : [const Color(0xFFE64A19), const Color(0xFFD84315)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                reply.isFromCurrentUser ? Icons.person : Icons.restaurant,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Reply content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        reply.senderName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(reply.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  _buildReplyContent(reply),
                ],
              ),
            ),
            
            // Reply type indicator
            if (reply.type == StoryReplyType.reaction)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 12,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyContent(StoryReply reply) {
    switch (reply.type) {
      case StoryReplyType.reaction:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7043).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF7043).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                reply.content,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Reaction',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF7043),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
        
      case StoryReplyType.text:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Text(
            reply.content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C2C2C),
            ),
          ),
        );
        
      default:
        return Text(
          reply.content,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2C2C2C),
          ),
        );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return DateFormat('MMM dd').format(time);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
