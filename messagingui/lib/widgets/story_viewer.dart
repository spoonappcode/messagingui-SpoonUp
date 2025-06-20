import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import '../models/story.dart';

class StoryViewer extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final Function(String storyId)? onStoryViewed;
  final VoidCallback? onComplete;

  const StoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.onStoryViewed,
    this.onComplete,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late List<AnimationController> _progressControllers;
  Timer? _timer;
  int _currentIndex = 0;
  final int _storyDuration = 5; // seconds
  bool _isPaused = false;
  bool _isDisposed = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  bool _showReplyInput = false;
  bool _isTypingReply = false;
  bool _showUI = true;
  late AnimationController _uiAnimationController;
  late Animation<double> _uiFadeAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.stories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      return;
    }
    
    _currentIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    
    // Create progress controllers for each story
    _progressControllers = List.generate(
      widget.stories.length,
      (index) => AnimationController(
        duration: Duration(seconds: _storyDuration),
        vsync: this,
      ),
    );

    // UI fade animation controller
    _uiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _uiFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uiAnimationController,
      curve: Curves.easeInOut,
    ));

    _uiAnimationController.forward();
    _startCurrentStory();

    // Auto-hide UI after 3 seconds
    _scheduleUIHide();
  }

  void _scheduleUIHide() {
    Timer(const Duration(seconds: 3), () {
      if (mounted && !_showReplyInput && !_isPaused) {
        setState(() {
          _showUI = false;
        });
        _uiAnimationController.reverse();
      }
    });
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    
    if (_showUI) {
      _uiAnimationController.forward();
      _scheduleUIHide();
    } else {
      _uiAnimationController.reverse();
    }
  }

  void _startCurrentStory() {
    if (_isDisposed || !mounted) return;
    
    _timer?.cancel();
    
    // Reset all progress controllers
    for (int i = 0; i < _progressControllers.length; i++) {
      if (i < _currentIndex) {
        _progressControllers[i].value = 1.0; // Completed
      } else if (i == _currentIndex) {
        _progressControllers[i].reset();
        if (!_isPaused) {
          _progressControllers[i].forward();
        }
      } else {
        _progressControllers[i].reset(); // Not started
      }
    }
    
    // Mark current story as viewed
    if (_currentIndex < widget.stories.length) {
      widget.onStoryViewed?.call(widget.stories[_currentIndex].id);
    }
    
    // Auto advance timer
    if (!_isPaused) {
      _timer = Timer(Duration(seconds: _storyDuration), () {
        if (mounted && !_isPaused && !_isDisposed) {
          _nextStory();
        }
      });
    }
  }

  void _nextStory() {
    if (_isDisposed || !mounted) return;
    
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startCurrentStory();
    } else {
      _closeViewer();
    }
  }

  void _previousStory() {
    if (_isDisposed || !mounted) return;
    
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startCurrentStory();
    }
  }

  void _pauseStory() {
    if (_isDisposed || !mounted) return;
    
    setState(() {
      _isPaused = true;
    });
    _timer?.cancel();
    if (_currentIndex < _progressControllers.length) {
      _progressControllers[_currentIndex].stop();
    }
  }

  void _resumeStory() {
    if (_isDisposed || !mounted) return;
    
    setState(() {
      _isPaused = false;
    });
    
    if (_currentIndex < _progressControllers.length) {
      _progressControllers[_currentIndex].forward();
      
      final remainingTime = (_storyDuration * (1 - _progressControllers[_currentIndex].value)).round();
      if (remainingTime > 0) {
        _timer = Timer(Duration(seconds: remainingTime), () {
          if (mounted && !_isPaused && !_isDisposed) {
            _nextStory();
          }
        });
      }
    }
  }

  void _closeViewer() {
    if (_isDisposed) return;
    
    _timer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onComplete?.call();
    }
  }

  void _toggleReplyInput() {
    setState(() {
      _showReplyInput = !_showReplyInput;
      _showUI = true;
    });
    
    if (_showReplyInput) {
      _pauseStory();
      _replyFocusNode.requestFocus();
      _uiAnimationController.forward();
    } else {
      _resumeStory();
      _replyController.clear();
      _scheduleUIHide();
    }
  }

  void _sendStoryReply() {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;

    final currentStory = widget.stories[_currentIndex];
    
    // Simulate sending reply
    _showReplyConfirmation(currentStory.userName, replyText);
    
    // Clear and hide input
    _replyController.clear();
    setState(() {
      _showReplyInput = false;
    });
    
    _resumeStory();
  }

  void _sendQuickReaction(String emoji) {
    final currentStory = widget.stories[_currentIndex];
    
    // Show reaction animation
    _showReactionAnimation(emoji);
    
    // Simulate sending reaction
    _showReplyConfirmation(currentStory.userName, emoji);
  }

  void _showReplyConfirmation(String userName, String reply) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reply sent to $userName: "$reply"',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF7043),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showReactionAnimation(String emoji) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedReactionWidget(
        emoji: emoji,
        onComplete: () => overlayEntry.remove(),
      ),
    );
    
    overlay.insert(overlayEntry);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _pageController.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    _uiAnimationController.dispose();
    for (var controller in _progressControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7043)),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Nasconde la tastiera quando presente
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (_showReplyInput) return;
            
            if (details.globalPosition.dx < screenWidth / 3) {
              _previousStory();
            } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
              _nextStory();
            } else {
              _toggleUI();
            }
          },
          onVerticalDragEnd: (details) {
            if (_showReplyInput) return;
            
            if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
              _closeViewer();
            }
          },
          child: Stack(
            children: [
              // Stories content
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  if (!_isDisposed && mounted) {
                    setState(() {
                      _currentIndex = index;
                    });
                    _startCurrentStory();
                  }
                },
                itemCount: widget.stories.length,
                itemBuilder: (context, index) {
                  if (index >= widget.stories.length) return Container();
                  final story = widget.stories[index];
                  return _buildStoryContent(story);
                },
              ),
              
              // Modern minimal progress bars
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _uiFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _uiFadeAnimation.value,
                      child: Row(
                        children: List.generate(
                          widget.stories.length,
                          (index) => Expanded(
                            child: Container(
                              height: 2,
                              margin: EdgeInsets.only(
                                right: index < widget.stories.length - 1 ? 6 : 0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(1),
                              ),
                              child: index < _progressControllers.length 
                                  ? AnimatedBuilder(
                                      animation: _progressControllers[index],
                                      builder: (context, child) {
                                        return FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _progressControllers[index].value,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(1),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 0),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(),
                            ),
                          ),
                        ),
                      ),
                  );
                  },
                ),
              ),
              
              // Modern minimal top bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 24,
                left: 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _uiFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _uiFadeAnimation.value,
                      child: _currentIndex < widget.stories.length
                          ? Row(
                              children: [
                                // Clean user info
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: FaIcon(
                                          widget.stories[_currentIndex].mediaType == 'video'
                                              ? Icons.videocam
                                              : FontAwesomeIcons.spoon,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.stories[_currentIndex].userName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black54,
                                                  offset: Offset(0, 1),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _getTimeAgo(widget.stories[_currentIndex].timestamp),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ),
                                
                                const Spacer(),
                                
                                // Minimal pause indicator
                                if (_isPaused)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.pause,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                
                                const SizedBox(width: 8),
                                
                                // Close button
                                GestureDetector(
                                  onTap: _closeViewer,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(),
                    );
                  },
                ),
              ),
              
              // Modern bottom interaction area
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _uiFadeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _showReplyInput ? 0 : (1 - _uiFadeAnimation.value) * 100),
                      child: GestureDetector(
                        onTap: () {
                          // Previene la chiusura della tastiera nell'area di input
                        },
                        child: Container(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(context).padding.bottom + 20,
                            top: 20,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Quick reactions - minimal design
                              if (!_showReplyInput)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildMinimalReaction('❤️'),
                                      _buildMinimalReaction('😍'),
                                      _buildMinimalReaction('😂'),
                                      _buildMinimalReaction('🔥'),
                                      _buildMinimalReaction('👨‍🍳'),
                                    ],
                                  ),
                                ),
                              
                              // Reply input or action buttons
                              _showReplyInput
                                  ? _buildMinimalReplyInput()
                                  : _buildMinimalActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalReaction(String emoji) {
    return GestureDetector(
      onTap: () => _sendQuickReaction(emoji),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildMinimalActionButtons() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Minimal message input
          Expanded(
            child: GestureDetector(
              onTap: _toggleReplyInput,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.message_outlined,
                      color: Colors.white.withOpacity(0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reply...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Minimal heart button
          GestureDetector(
            onTap: () => _sendQuickReaction('❤️'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFE91E63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalReplyInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleReplyInput,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.9),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _replyController,
                focusNode: _replyFocusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Reply to ${widget.stories[_currentIndex].userName}...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendStoryReply(),
                onChanged: (text) {
                  setState(() {
                    _isTypingReply = text.isNotEmpty;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _isTypingReply ? _sendStoryReply : null,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: _isTypingReply 
                      ? const LinearGradient(
                          colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _isTypingReply ? null : Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.send,
                  color: _isTypingReply 
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    if (story.mediaType == 'video') {
      return _buildVideoContent(story);
    } else {
      return _buildImageContent(story);
    }
  }

  Widget _buildImageContent(Story story) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: story.mediaUrl.isNotEmpty
          ? Image.network(
              story.mediaUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                return _buildPlaceholderContent(story);
              },
            )
          : _buildPlaceholderContent(story),
    );
  }

  Widget _buildVideoContent(Story story) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[900]!,
            Colors.black,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7043).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Video Recipe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent(Story story) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF7043).withOpacity(0.8),
            const Color(0xFFFF5722).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const FaIcon(
              FontAwesomeIcons.spoon,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            story.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Recipe Story',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

// Widget for animated reactions
class AnimatedReactionWidget extends StatefulWidget {
  final String emoji;
  final VoidCallback onComplete;

  const AnimatedReactionWidget({
    super.key,
    required this.emoji,
    required this.onComplete,
  });

  @override
  State<AnimatedReactionWidget> createState() => _AnimatedReactionWidgetState();
}

class _AnimatedReactionWidgetState extends State<AnimatedReactionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -2),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.translate(
                offset: _slideAnimation.value * 100,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
