import 'package:flutter/material.dart';
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
    
    _startCurrentStory();
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

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _pageController.dispose();
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            // Left tap - previous story (don't pause)
            _previousStory();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            // Right tap - next story (don't pause)
            _nextStory();
          } else {
            // Center tap - pause
            _pauseStory();
          }
        },
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx >= screenWidth / 3 && 
              details.globalPosition.dx <= screenWidth * 2 / 3) {
            // Center tap up - resume
            _resumeStory();
          }
        },
        onTapCancel: () {
          _resumeStory();
        },
        onVerticalDragEnd: (details) {
          // Handle vertical swipe down to close
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            _closeViewer();
          }
        },
        child: Stack(
          children: [
            // Stories PageView
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
            
            // Top overlay with progress bars and user info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 16,
                  16,
                  16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Progress bars
                    Row(
                      children: List.generate(
                        widget.stories.length,
                        (index) => Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(
                              right: index < widget.stories.length - 1 ? 4 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
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
                                            borderRadius: BorderRadius.circular(2),
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
                    const SizedBox(height: 16),
                    
                    // User info
                    if (_currentIndex < widget.stories.length)
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFFF7043),
                              child: Icon(
                                widget.stories[_currentIndex].mediaType == 'video'
                                    ? Icons.videocam
                                    : Icons.restaurant,
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
                                  widget.stories[_currentIndex].userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(widget.stories[_currentIndex].timestamp),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isPaused)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pause,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Paused',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          IconButton(
                            onPressed: _closeViewer,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Navigation hints (left/right areas)
            if (_currentIndex > 0)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width / 3,
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _isPaused ? 0.8 : 0.3,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_currentIndex < widget.stories.length - 1)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width / 3,
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _isPaused ? 0.8 : 0.3,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            // Bottom story info with swipe down hint
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Swipe down indicator
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: AnimatedOpacity(
                        opacity: _isPaused ? 0.8 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                              size: 20,
                            ),
                            Text(
                              'Swipe down to close',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_currentIndex < widget.stories.length)
                      Text(
                        widget.stories[_currentIndex].mediaType == 'video'
                            ? '🎥 Recipe Video'
                            : '📸 Recipe Photo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_currentIndex + 1} of ${widget.stories.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(
                              Icons.swipe_left,
                              color: Colors.white60,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tap sides to navigate',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFFFF7043),
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
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFF7043),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Video Playing...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Recipe by ${story.userName}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
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
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7043),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            story.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Recipe Story',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
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
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
