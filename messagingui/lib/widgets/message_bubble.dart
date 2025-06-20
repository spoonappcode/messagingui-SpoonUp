import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply; // Nuovo callback per la risposta

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.onTap,
    this.onLongPress,
    this.onSwipeReply,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('${message.id}_swipe'),
      direction: message.isFromCurrentUser 
          ? DismissDirection.endToStart 
          : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        // Non dismissare effettivamente il messaggio, solo triggare la risposta
        onSwipeReply?.call();
        return false;
      },
      background: _buildSwipeBackground(true),
      secondaryBackground: _buildSwipeBackground(false),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            mainAxisAlignment: message.isFromCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!message.isFromCurrentUser && showAvatar)
                _buildAvatar(),
              if (!message.isFromCurrentUser && showAvatar)
                const SizedBox(width: 8),
              
              Flexible(
                child: Column(
                  crossAxisAlignment: message.isFromCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Reply preview se questo messaggio è una risposta
                    if (message.isReply)
                      _buildReplyPreview(),
                    
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: message.isFromCurrentUser
                              ? [
                                  const Color(0xFFFF7043),
                                  const Color(0xFFFF5722),
                                ]
                              : [
                                  Colors.white,
                                  const Color(0xFFFFF3E0),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(
                            message.isFromCurrentUser ? 20 : 4,
                          ),
                          bottomRight: Radius.circular(
                            message.isFromCurrentUser ? 4 : 20,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: message.isFromCurrentUser
                                ? const Color(0xFFFF7043).withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: message.isFromCurrentUser
                            ? null
                            : Border.all(
                                color: const Color(0xFFFF7043).withOpacity(0.2),
                                width: 1,
                              ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!message.isFromCurrentUser && showAvatar)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                message.senderName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF7043),
                                ),
                              ),
                            ),
                          
                          _buildMessageContent(),
                          
                          const SizedBox(height: 4),
                          
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: message.isFromCurrentUser
                                      ? Colors.white.withOpacity(0.8)
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (message.isFromCurrentUser) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  message.isRead ? Icons.done_all : Icons.done,
                                  size: 14,
                                  color: message.isRead
                                      ? Colors.blue[200]
                                      : Colors.white.withOpacity(0.8),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              if (message.isFromCurrentUser && showAvatar)
                const SizedBox(width: 8),
              if (message.isFromCurrentUser && showAvatar)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7043).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.spoon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isLeftSwipe) {
    return Container(
      alignment: isLeftSwipe ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(
        left: isLeftSwipe ? 20 : 0,
        right: isLeftSwipe ? 0 : 20,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLeftSwipe) ...[
              Text(
                'Reply',
                style: TextStyle(
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.reply,
                color: Colors.white,
                size: 20,
              ),
            ),
            if (isLeftSwipe) ...[
              const SizedBox(width: 8),
              Text(
                'Reply',
                style: TextStyle(
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (message.replyToMessage == null) return const SizedBox.shrink();
    
    final replyMessage = message.replyToMessage!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: message.isFromCurrentUser
            ? Colors.white.withOpacity(0.2)
            : const Color(0xFFFF7043).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: message.isFromCurrentUser
                ? Colors.white
                : const Color(0xFFFF7043),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyMessage.isFromCurrentUser ? 'You' : replyMessage.senderName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: message.isFromCurrentUser
                  ? Colors.white
                  : const Color(0xFFFF7043),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyMessage.content.length > 50
                ? '${replyMessage.content.substring(0, 50)}...'
                : replyMessage.content,
            style: TextStyle(
              fontSize: 12,
              color: message.isFromCurrentUser
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE64A19), Color(0xFFD84315)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE64A19).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: FaIcon(
          FontAwesomeIcons.spoon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return _buildTextContent();
      case MessageType.image:
        return _buildImageContent();
      case MessageType.video:
        return _buildVideoContent();
      case MessageType.voice:
        return _buildVoiceContent();
      case MessageType.recipe:
        return _buildRecipeContent();
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return Text(
      message.content,
      style: TextStyle(
        fontSize: 15,
        color: message.isFromCurrentUser
            ? Colors.white
            : const Color(0xFF2C2C2C),
        fontWeight: FontWeight.w400,
        height: 1.3,
      ),
    );
  }

  Widget _buildImageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: 250,
            maxHeight: 300,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: message.mediaUrl != null && message.mediaUrl!.isNotEmpty
                ? Stack(
                    children: [
                      Image.network(
                        message.mediaUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFFFF7043),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildMediaPlaceholder(Icons.image, 'Image');
                        },
                      ),
                      // Download/View overlay
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.download,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildMediaPlaceholder(Icons.image, 'Image'),
          ),
        ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildTextContent(),
        ],
      ],
    );
  }

  Widget _buildVideoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 250,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[900],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Video thumbnail/placeholder
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[900]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: message.mediaUrl != null && message.mediaUrl!.isNotEmpty
                      ? Image.network(
                          message.mediaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildMediaPlaceholder(Icons.videocam, 'Video');
                          },
                        )
                      : _buildMediaPlaceholder(Icons.videocam, 'Video'),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: const Color(0xFFFF7043),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                // Duration badge
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '0:15', // Placeholder duration
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildTextContent(),
        ],
      ],
    );
  }

  Widget _buildVoiceContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isFromCurrentUser
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFFFF7043).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: message.isFromCurrentUser
              ? Colors.white.withOpacity(0.3)
              : const Color(0xFFFF7043).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: message.isFromCurrentUser
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFFFF7043).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow, // Toggle between play_arrow and pause
              color: message.isFromCurrentUser
                  ? Colors.white
                  : const Color(0xFFFF7043),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Waveform visualization
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(15, (index) {
                    final heights = [3.0, 8.0, 12.0, 6.0, 15.0, 4.0, 10.0, 7.0, 
                                   14.0, 5.0, 9.0, 11.0, 6.0, 8.0, 3.0];
                    return Container(
                      width: 2,
                      height: heights[index],
                      decoration: BoxDecoration(
                        color: (message.isFromCurrentUser
                            ? Colors.white
                            : const Color(0xFFFF7043)).withOpacity(
                          index < 5 ? 1.0 : 0.3, // Simulate progress
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                
                // Duration
                Text(
                  '0:08 / 0:15', // Progress / Total duration
                  style: TextStyle(
                    fontSize: 11,
                    color: message.isFromCurrentUser
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Speed control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: message.isFromCurrentUser
                  ? Colors.white.withOpacity(0.1)
                  : const Color(0xFFFF7043).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '1x',
              style: TextStyle(
                fontSize: 10,
                color: message.isFromCurrentUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isFromCurrentUser
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFFFF7043).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.isFromCurrentUser
              ? Colors.white.withOpacity(0.3)
              : const Color(0xFFFF7043).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: message.isFromCurrentUser
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFFFF7043).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.menu_book,
              color: message.isFromCurrentUser
                  ? Colors.white
                  : const Color(0xFFFF7043),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipe Shared',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: message.isFromCurrentUser
                        ? Colors.white
                        : const Color(0xFFFF7043),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: message.isFromCurrentUser
                        ? Colors.white.withOpacity(0.9)
                        : Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: message.isFromCurrentUser
                  ? Colors.white.withOpacity(0.1)
                  : const Color(0xFFFF7043).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              color: message.isFromCurrentUser
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFFFF7043),
              size: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPlaceholder(IconData icon, String label) {
    return Container(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7043).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: const Color(0xFFFF7043),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return DateFormat('dd/MM').format(time);
    } else {
      return DateFormat('HH:mm').format(time);
    }
  }
}
