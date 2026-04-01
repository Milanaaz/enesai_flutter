import 'package:dipl/app/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({required this.currentIndex, super.key});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: const Color(0xFF98A2B3),
        selectedFontSize: 24,
        unselectedFontSize: 24,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        iconSize: 22,
        onTap: (int index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: _ActiveNavIcon(icon: Icons.home_outlined),
            label: '\u0413\u043b\u0430\u0432\u043d\u0430\u044f',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: _ActiveNavIcon(icon: Icons.menu_book_outlined),
            label: '\u041a\u0443\u0440\u0441\u044b',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: _ActiveNavIcon(icon: Icons.book_outlined),
            label: '\u0421\u043b\u043e\u0432\u0430\u0440\u044c',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: _ActiveNavIcon(icon: Icons.chat_bubble_outline),
            label: '\u0427\u0430\u0442',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/courses');
        break;
      case 2:
        context.go('/dictionary');
        break;
      case 3:
        context.go('/chat');
        break;
      default:
        break;
    }
  }
}

class _ActiveNavIcon extends StatelessWidget {
  const _ActiveNavIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
