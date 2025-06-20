import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({
    super.key,
    required this.chat,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<Message> _messages = [];
  bool _isTyping = false;
  bool _isOnline = true;
  bool _isRecording = false;
  bool _showMediaOptions = false;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  Message? _replyingToMessage; // Messaggio a cui si sta rispondendo

  @override
  void initState() {
    super.initState();
    _messages = Message.getSampleMessages(widget.chat.id);
    _isOnline = widget.chat.isOnline;
    
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));

    // Simulate typing indicator
    _messageController.addListener(_onTextChanged);
    
    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
      _simulateOtherUserTyping();
    } else if (_messageController.text.isEmpty && _isTyping) {
      setState(() {
        _isTyping = false;
      });
      _typingAnimationController.stop();
    }
  }

  void _simulateOtherUserTyping() {
    _typingAnimationController.repeat();
    
    // Stop typing after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _typingAnimationController.stop();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'current_user',
      senderName: 'You',
      content: text,
      timestamp: DateTime.now(),
      isSent: false,
      replyToMessage: _replyingToMessage, // Aggiungi la risposta se presente
    );

    setState(() {
      _messages.add(newMessage);
      _isTyping = false;
      _replyingToMessage = null; // Reset della risposta
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate message sending
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(isSent: true);
          }
        });
      }
    });

    // Simulate auto-reply after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      _simulateAutoReply(text);
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  void _simulateAutoReply(String originalMessage) {
    if (!mounted) return;

    final responses = [
      'Interessante! Dimmi di più 🤔',
      'Sono d\'accordo con te!',
      'Che bella idea per una ricetta! 👨‍🍳',
      'Non vedo l\'ora di provarlo!',
      'Grazie per il consiglio! 😄',
      'Hai mai provato questa variante?',
    ];

    final randomResponse = responses[DateTime.now().millisecond % responses.length];

    final replyMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: widget.chat.id,
      senderName: widget.chat.name,
      content: randomResponse,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(replyMessage);
    });

    _scrollToBottom();
  }

  void _showMessageOptions(Message message) {
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
            
            _buildMessageOption(
              icon: Icons.reply,
              title: 'Reply',
              subtitle: 'Reply to this message',
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(message);
              },
            ),
            
            _buildMessageOption(
              icon: Icons.copy,
              title: 'Copy',
              subtitle: 'Copy message text',
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
                _showSnackBar('Message copied to clipboard');
              },
            ),
            
            if (message.isFromCurrentUser)
              _buildMessageOption(
                icon: Icons.delete,
                title: 'Delete',
                subtitle: 'Delete this message',
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
                isDestructive: true,
              ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
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
                color: (isDestructive ? Colors.red : const Color(0xFFFF7043))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFFFF7043),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : const Color(0xFF2C2C2C),
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
          ],
        ),
      ),
    );
  }

  void _replyToMessage(Message message) {
    setState(() {
      _replyingToMessage = message;
    });
    _focusNode.requestFocus();
    
    // Vibrazione per feedback
    HapticFeedback.selectionClick();
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  void _deleteMessage(Message message) {
    setState(() {
      _messages.removeWhere((m) => m.id == message.id);
    });
    _showSnackBar('Message deleted');
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

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Reactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 6,
                children: [
                  '😄', '😍', '👍', '👎', '❤️', '😮',
                  '😂', '🤔', '👨‍🍳', '🍝', '🍕', '🥘',
                  '🔥', '💯', '👌', '🙌', '😋', '🤤',
                ].map((emoji) => InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _messageController.text += emoji;
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCookingLevelColor() {
    switch (widget.chat.cookingLevel) {
      case 'Novice':
        return const Color(0xFFFF7043);
      case 'Home Cook':
        return const Color(0xFFFF5722);
      case 'Chef':
        return const Color(0xFFE64A19);
      case 'Master Chef':
        return const Color(0xFFD84315);
      default:
        return const Color(0xFFFF7043);
    }
  }

  IconData _getCookingLevelIcon() {
    switch (widget.chat.cookingLevel) {
      case 'Novice':
        return Icons.egg_outlined;
      case 'Home Cook':
        return Icons.kitchen;
      case 'Chef':
        return Icons.restaurant;
      case 'Master Chef':
        return Icons.military_tech;
      default:
        return Icons.person;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Nasconde la tastiera quando si tocca fuori dall'input
        FocusScope.of(context).unfocus();
      },
      onHorizontalDragEnd: (details) {
        // Rileva lo swipe verso destra per uscire dalla chat
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3E0),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFF7043),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _getCookingLevelColor(),
                      _getCookingLevelColor().withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    _getCookingLevelIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chat.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isTyping 
                              ? 'typing...' 
                              : (_isOnline ? 'online' : 'offline'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white),
              onPressed: () {
                _showSnackBar('Video call feature coming soon!');
              },
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () {
                _showSnackBar('Voice call feature coming soon!');
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                _showSnackBar('More options coming soon!');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Nasconde la tastiera quando si tocca nell'area messaggi
                  FocusScope.of(context).unfocus();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    
                    final message = _messages[index];
                    final showAvatar = index == _messages.length - 1 ||
                        _messages[index + 1].senderId != message.senderId;
                    
                    return MessageBubble(
                      message: message,
                      showAvatar: showAvatar,
                      onLongPress: () => _showMessageOptions(message),
                      onSwipeReply: () => _replyToMessage(message),
                    );
                  },
                ),
              ),
            ),
            
            // Media options
            if (_showMediaOptions)
              _buildMediaOptions(),
            
            // Reply preview
            if (_replyingToMessage != null)
              _buildReplyInputPreview(),
            
            // Message input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Media picker button
                    IconButton(
                      icon: Icon(
                        _showMediaOptions ? Icons.close : Icons.add,
                        color: const Color(0xFFFF7043),
                      ),
                      onPressed: _showMediaPicker,
                    ),
                    
                    // Emoji button
                    IconButton(
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: Color(0xFFFF7043),
                      ),
                      onPressed: _showEmojiPicker,
                    ),
                    
                    // Text input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFFFF7043).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: _replyingToMessage != null 
                                ? 'Reply to ${_replyingToMessage!.senderName}...'
                                : 'Type a message...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Send/Voice button
                    GestureDetector(
                      onTap: _messageController.text.trim().isNotEmpty 
                          ? _sendMessage 
                          : _toggleVoiceRecording,
                      onLongPress: _messageController.text.trim().isEmpty 
                          ? _toggleVoiceRecording 
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isRecording 
                                ? [Colors.red, Colors.red[700]!]
                                : [const Color(0xFFFF7043), const Color(0xFFFF5722)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? Colors.red : const Color(0xFFFF7043))
                                  .withOpacity(0.3),
                              blurRadius: _isRecording ? 12 : 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isRecording ? 60 : 48,
                          height: _isRecording ? 60 : 48,
                          child: Icon(
                            _messageController.text.trim().isNotEmpty 
                                ? Icons.send
                                : (_isRecording ? Icons.stop : Icons.mic),
                            color: Colors.white,
                            size: _isRecording ? 28 : 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE64A19), Color(0xFFD84315)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF7043).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    const SizedBox(width: 3),
                    _buildTypingDot(1),
                    const SizedBox(width: 3),
                    _buildTypingDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    final double animationValue = _typingAnimation.value;
    final double delay = index * 0.2;
    final double opacity = ((animationValue - delay) % 1.0).clamp(0.0, 1.0);
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFFF7043).withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildReplyInputPreview() {
    if (_replyingToMessage == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7043),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: const Color(0xFFFF7043),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Replying to ${_replyingToMessage!.isFromCurrentUser ? 'yourself' : _replyingToMessage!.senderName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF7043),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingToMessage!.content.length > 50
                      ? '${_replyingToMessage!.content.substring(0, 50)}...'
                      : _replyingToMessage!.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 20,
              color: Colors.grey,
            ),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaPicker() {
    setState(() {
      _showMediaOptions = !_showMediaOptions;
    });
  }

  void _sendImageMessage() {
    final newMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'current_user',
      senderName: 'You',
      content: 'Photo shared',
      timestamp: DateTime.now(),
      type: MessageType.image,
      mediaUrl: 'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}',
      isSent: false,
      replyToMessage: _replyingToMessage,
    );

    setState(() {
      _messages.add(newMessage);
      _replyingToMessage = null;
      _showMediaOptions = false;
    });

    _scrollToBottom();
    HapticFeedback.lightImpact();

    // Simulate sending
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(isSent: true);
          }
        });
      }
    });
  }

  void _sendVideoMessage() {
    final newMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'current_user',
      senderName: 'You',
      content: 'Video shared',
      timestamp: DateTime.now(),
      type: MessageType.video,
      mediaUrl: 'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}',
      isSent: false,
      replyToMessage: _replyingToMessage,
    );

    setState(() {
      _messages.add(newMessage);
      _replyingToMessage = null;
      _showMediaOptions = false;
    });

    _scrollToBottom();
    HapticFeedback.lightImpact();

    // Simulate sending
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(isSent: true);
          }
        });
      }
    });
  }

  void _toggleVoiceRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    HapticFeedback.heavyImpact();

    // Simulate recording completion after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_isRecording && mounted) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    
    // Send voice message
    final newMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'current_user',
      senderName: 'You',
      content: 'Voice message',
      timestamp: DateTime.now(),
      type: MessageType.voice,
      isSent: false,
      replyToMessage: _replyingToMessage,
    );

    setState(() {
      _messages.add(newMessage);
      _replyingToMessage = null;
    });

    _scrollToBottom();
    HapticFeedback.mediumImpact();

    // Simulate sending
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(isSent: true);
          }
        });
      }
    });
  }

  Widget _buildMediaOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMediaOption(
            icon: Icons.photo_camera,
            label: 'Camera',
            color: const Color(0xFF4CAF50),
            onTap: () {
              _sendImageMessage();
              _showSnackBar('Photo captured!');
            },
          ),
          _buildMediaOption(
            icon: Icons.photo_library,
            label: 'Gallery',
            color: const Color(0xFF2196F3),
            onTap: () {
              _sendImageMessage();
              _showSnackBar('Photo selected from gallery');
            },
          ),
          _buildMediaOption(
            icon: Icons.videocam,
            label: 'Video',
            color: const Color(0xFF9C27B0),
            onTap: () {
              _sendVideoMessage();
              _showSnackBar('Video recorded!');
            },
          ),
          _buildMediaOption(
            icon: Icons.menu_book,
            label: 'Recipe',
            color: const Color(0xFFFF7043),
            onTap: () {
              final recipeMessage = Message(
                id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
                senderId: 'current_user',
                senderName: 'You',
                content: 'Homemade Carbonara Recipe',
                timestamp: DateTime.now(),
                type: MessageType.recipe,
                isSent: false,
                replyToMessage: _replyingToMessage,
              );
              
              setState(() {
                _messages.add(recipeMessage);
                _replyingToMessage = null;
                _showMediaOptions = false;
              });
              
              _scrollToBottom();
              _showSnackBar('Recipe shared!');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
