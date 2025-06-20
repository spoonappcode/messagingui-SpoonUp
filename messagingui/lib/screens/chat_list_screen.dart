import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/story.dart';
import '../widgets/chat_list_item.dart';
import '../widgets/stories_bar.dart';
import '../widgets/chat_settings_bottom_sheet.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> chats = [];
  List<Story> stories = [];
  TextEditingController searchController = TextEditingController();
  List<Chat> filteredChats = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    chats = Chat.getSampleChats();
    stories = Story.getSampleStories();
    _updateFilteredChats();
    searchController.addListener(_filterChats);
  }

  void _filterChats() {
    final query = searchController.text.toLowerCase();
    setState(() {
      var filtered = chats.where((chat) {
        return chat.name.toLowerCase().contains(query) ||
               chat.lastMessage.toLowerCase().contains(query);
      }).toList();
      
      _sortChats(filtered);
      filteredChats = filtered;
    });
  }

  void _updateFilteredChats() {
    setState(() {
      filteredChats = List.from(chats);
      _sortChats(filteredChats);
    });
  }

  void _sortChats(List<Chat> chatList) {
    chatList.sort((a, b) {
      // First, sort by favorite status
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      
      // Then sort by last message time
      return b.lastMessageTime.compareTo(a.lastMessageTime);
    });
  }

  void _showChatSettings(Chat chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ChatSettingsBottomSheet(
        chat: chat,
        onAction: (action) => _handleChatAction(chat, action),
      ),
    );
  }

  void _handleChatAction(Chat chat, String action) {
    setState(() {
      final index = chats.indexWhere((c) => c.id == chat.id);
      if (index != -1) {
        switch (action) {
          case 'favorite':
            chats[index] = chat.copyWith(isFavorite: !chat.isFavorite);
            _showSnackBar(
              chat.isFavorite 
                  ? '${chat.name} removed from favorites'
                  : '${chat.name} added to favorites',
              chat.isFavorite ? Icons.star_border : Icons.star,
            );
            break;
          case 'mute':
            chats[index] = chat.copyWith(isMuted: !chat.isMuted);
            _showSnackBar(
              chat.isMuted 
                  ? 'Notifications enabled for ${chat.name}'
                  : '${chat.name} muted',
              chat.isMuted ? Icons.volume_up : Icons.volume_off,
            );
            break;
          case 'delete':
            chats.removeAt(index);
            _showSnackBar(
              'Chat with ${chat.name} deleted',
              Icons.delete,
            );
            break;
        }
        _updateFilteredChats();
      }
    });
  }

  void _showSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF7043),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _refreshChats() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    // Simulate network refresh
    await Future.delayed(const Duration(seconds: 1));
    
    // Refresh the data (in a real app, this would fetch from API)
    setState(() {
      chats = Chat.getSampleChats();
      stories = Story.getSampleStories();
      _isRefreshing = false;
    });
    
    _updateFilteredChats();
    
    _showSnackBar(
      'Chat list refreshed',
      Icons.refresh,
    );
  }

  void _handleSwipeToFavorite(Chat chat) {
    setState(() {
      final index = chats.indexWhere((c) => c.id == chat.id);
      if (index != -1) {
        chats[index] = chat.copyWith(isFavorite: !chat.isFavorite);
        _updateFilteredChats();
        _showSnackBar(
          chat.isFavorite 
              ? '${chat.name} removed from favorites'
              : '${chat.name} added to favorites',
          chat.isFavorite ? Icons.star_border : Icons.star,
        );
      }
    });
  }

  Future<bool> _confirmDelete(Chat chat) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: const Color(0xFFE53935),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Delete chat',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete the chat with ${chat.name}? This action cannot be undone.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
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
        );
      },
    );
    return result ?? false;
  }

  void _handleSwipeToDelete(Chat chat) async {
    final shouldDelete = await _confirmDelete(chat);
    if (shouldDelete) {
      setState(() {
        chats.removeWhere((c) => c.id == chat.id);
        _updateFilteredChats();
      });
      _showSnackBar(
        'Chat with ${chat.name} deleted',
        Icons.delete,
      );
    }
  }

  Widget _buildSwipeableChatItem(Chat chat, int index) {
    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Add to favorites
          _handleSwipeToFavorite(chat);
          return false; // Don't actually dismiss
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left - Delete with confirmation
          return await _confirmDelete(chat);
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // If we get here, the user confirmed deletion in confirmDismiss
          setState(() {
            chats.removeWhere((c) => c.id == chat.id);
            _updateFilteredChats();
          });
          _showSnackBar(
            'Chat with ${chat.name} deleted',
            Icons.delete,
          );
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFC107).withOpacity(0.1),
              const Color(0xFFFFC107).withOpacity(0.3),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                chat.isFavorite ? Icons.star_border : Icons.star,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              chat.isFavorite ? 'Remove from\nfavorites' : 'Add to\nfavorites',
              style: const TextStyle(
                color: Color(0xFFFFC107),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE53935).withOpacity(0.1),
              const Color(0xFFE53935).withOpacity(0.3),
            ],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete\nchat',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
      child: ChatListItem(
        chat: chat,
        onTap: () {
          // Navigate to specific chat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chat: chat),
            ),
          );
        },
        onLongPress: () => _showChatSettings(chat),
      ),
    );
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Start a new conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to connect with other food lovers',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            
            // New chat option
            _buildChatOption(
              icon: Icons.person_add,
              title: 'New Chat',
              subtitle: 'Start a conversation with another chef',
              color: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.pop(context);
                _showNewChatDialog();
              },
            ),
            
            const SizedBox(height: 20),
            
            // Group chat option
            _buildChatOption(
              icon: Icons.group_add,
              title: 'Create Group',
              subtitle: 'Cook together with multiple people',
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupDialog();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatDialog() {
    final TextEditingController nameController = TextEditingController();
    final List<String> cookingLevels = ['Novice', 'Home Cook', 'Chef', 'Master Chef'];
    String selectedLevel = cookingLevels.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'New Chat',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Chef Name',
                      hintText: 'Enter the name of the chef...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF4CAF50)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Cooking Level',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLevel,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4CAF50)),
                        items: cookingLevels.map((String level) {
                          return DropdownMenuItem<String>(
                            value: level,
                            child: Row(
                              children: [
                                Icon(
                                  _getCookingLevelIcon(level),
                                  size: 20,
                                  color: _getCookingLevelColor(level),
                                ),
                                const SizedBox(width: 8),
                                Text(level),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLevel = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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
                    if (nameController.text.trim().isNotEmpty) {
                      _createNewChat(nameController.text.trim(), selectedLevel);
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final List<String> groupTypes = ['Recipe Sharing', 'Cooking Challenge', 'Local Chefs', 'Diet Specific'];
    String selectedType = groupTypes.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.group_add,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Create Group',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: groupNameController,
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        hintText: 'Enter group name...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2196F3)),
                        ),
                        prefixIcon: const Icon(Icons.group, color: Color(0xFF2196F3)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'What\'s this group about?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2196F3)),
                        ),
                        prefixIcon: const Icon(Icons.description, color: Color(0xFF2196F3)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Group Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2196F3)),
                          items: groupTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    _getGroupTypeIcon(type),
                                    size: 20,
                                    color: const Color(0xFF2196F3),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(type),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedType = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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
                    if (groupNameController.text.trim().isNotEmpty) {
                      _createNewGroup(
                        groupNameController.text.trim(),
                        descriptionController.text.trim(),
                        selectedType,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _createNewChat(String name, String cookingLevel) {
    final newChat = Chat(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      lastMessage: 'Say hello to start cooking together! 👋',
      lastMessageTime: DateTime.now(),
      avatarUrl: '',
      unreadCount: 0,
      cookingLevel: cookingLevel,
      isOnline: false,
      isFavorite: false,
      isMuted: false,
    );

    setState(() {
      chats.insert(0, newChat);
      _updateFilteredChats();
    });

    _showSnackBar(
      'New chat with $name created!',
      Icons.check,
    );
  }

  void _createNewGroup(String groupName, String description, String groupType) {
    final newGroup = Chat(
      id: 'group_${DateTime.now().millisecondsSinceEpoch}',
      name: groupName,
      lastMessage: description.isNotEmpty ? description : 'Group created! Start sharing recipes 🍳',
      lastMessageTime: DateTime.now(),
      avatarUrl: '',
      unreadCount: 0,
      cookingLevel: 'Home Cook', // Default for groups
      isOnline: true,
      isFavorite: false,
      isMuted: false,
    );

    setState(() {
      chats.insert(0, newGroup);
      _updateFilteredChats();
    });

    _showSnackBar(
      'Group "$groupName" created successfully!',
      Icons.group,
    );
  }

  Color _getCookingLevelColor(String level) {
    switch (level) {
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

  IconData _getCookingLevelIcon(String level) {
    switch (level) {
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

  IconData _getGroupTypeIcon(String type) {
    switch (type) {
      case 'Recipe Sharing':
        return Icons.menu_book;
      case 'Cooking Challenge':
        return Icons.emoji_events;
      case 'Local Chefs':
        return Icons.location_on;
      case 'Diet Specific':
        return Icons.eco;
      default:
        return Icons.group;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Nasconde la tastiera quando si tocca fuori dall'area di ricerca
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFFF7043),
          title: const Row(
            children: [
              Icon(Icons.restaurant, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'SpoonUp',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                _showAppMenu();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            StoriesBar(stories: stories),
            Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFFFFF3E0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search chats or recipes...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFF7043)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            Expanded(
              child: filteredChats.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No chats found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start a new conversation!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshChats,
                      color: const Color(0xFFFF7043),
                      backgroundColor: Colors.white,
                      strokeWidth: 2.5,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          return _buildSwipeableChatItem(chat, index);
                        },
                      ),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showNewChatOptions,
          backgroundColor: const Color(0xFFFF7043),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showAppMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // App menu title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7043).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Color(0xFFFF7043),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'SpoonUp Menu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Search option
            _buildMenuOption(
              icon: Icons.search,
              title: 'Search',
              subtitle: 'Search chats and recipes',
              color: const Color(0xFF2196F3),
              onTap: () {
                Navigator.pop(context);
                _showSearchDialog();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Settings option
            _buildMenuOption(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'App preferences and account',
              color: const Color(0xFF757575),
              onTap: () {
                Navigator.pop(context);
                _showSettingsDialog();
              },
            ),
            
            const SizedBox(height: 16),
            
            // About option
            _buildMenuOption(
              icon: Icons.info_outline,
              title: 'About SpoonUp',
              subtitle: 'Version and app information',
              color: const Color(0xFFFF7043),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
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
                  const SizedBox(height: 2),
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

  void _showSearchDialog() {
    final TextEditingController searchTextController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.search,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Search',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: searchTextController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search chats, recipes, or ingredients...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2196F3)),
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2196F3)),
            ),
            onChanged: (value) {
              searchController.text = value;
              _filterChats();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
                Navigator.of(context).pop();
                searchController.text = searchTextController.text;
                _filterChats();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Search',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF757575).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF757575),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.notifications, color: Color(0xFFFF7043), size: 20),
                  SizedBox(width: 12),
                  Text('Notifications enabled'),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.dark_mode, color: Color(0xFF757575), size: 20),
                  SizedBox(width: 12),
                  Text('Light theme'),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.language, color: Color(0xFF2196F3), size: 20),
                  SizedBox(width: 12),
                  Text('English (Default)'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar('Settings saved', Icons.check);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF757575),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                  Icons.restaurant,
                  color: Color(0xFFFF7043),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About SpoonUp',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SpoonUp - Cook & Chat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF7043),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Connect with fellow food lovers, share recipes, and discover new cooking techniques together!',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.email, color: Color(0xFF2196F3), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'support@spoonup.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.web, color: Color(0xFF4CAF50), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'www.spoonup.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFFFF7043),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
