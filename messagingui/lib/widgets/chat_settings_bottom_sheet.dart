import 'package:flutter/material.dart';
import '../models/chat.dart';

class ChatSettingsBottomSheet extends StatelessWidget {
  final Chat chat;
  final Function(String action) onAction;

  const ChatSettingsBottomSheet({
    super.key,
    required this.chat,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          
          // Chat info
          Row(
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
                  radius: 25,
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    _getCookingLevelIcon(),
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      chat.cookingLevel,
                      style: TextStyle(
                        fontSize: 14,
                        color: _getCookingLevelColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Settings options
          _buildSettingOption(
            icon: chat.isFavorite ? Icons.star : Icons.star_border,
            title: chat.isFavorite ? 'Remove from favorites' : 'Add to favorites',
            subtitle: chat.isFavorite 
                ? 'Remove from top of chat list' 
                : 'Pin to top of chat list',
            onTap: () {
              Navigator.pop(context);
              onAction('favorite');
            },
            iconColor: const Color(0xFFFFC107),
          ),
          
          _buildSettingOption(
            icon: chat.isMuted ? Icons.volume_off : Icons.volume_up,
            title: chat.isMuted ? 'Unmute notifications' : 'Mute chat',
            subtitle: chat.isMuted 
                ? 'Turn on notifications for this chat' 
                : 'You won\'t receive notifications from this chat',
            onTap: () {
              Navigator.pop(context);
              onAction('mute');
            },
            iconColor: const Color(0xFF2196F3),
          ),
          
          _buildSettingOption(
            icon: Icons.delete_outline,
            title: 'Delete chat',
            subtitle: 'Remove this chat from the list',
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
            iconColor: const Color(0xFFFF5722),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
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
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
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
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete chat',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          content: Text(
            'Are you sure you want to delete the chat with ${chat.name}? This action cannot be undone.',
            style: TextStyle(
              color: Colors.grey[700],
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
                onAction('delete');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
  }

  Color _getCookingLevelColor() {
    switch (chat.cookingLevel) {
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
    switch (chat.cookingLevel) {
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
}
