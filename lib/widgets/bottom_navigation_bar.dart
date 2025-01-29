import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class MyBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MyBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  _MyBottomNavigationBarState createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: widget.currentIndex,
      onTap: widget.onTap,
      backgroundColor: Colors.transparent,
      color: Theme.of(context).primaryColor,
      buttonBackgroundColor: Theme.of(context).primaryColor,
      height: 60,
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      items: const [
        Icon(Icons.home, color: Colors.white),
        Icon(Icons.swap_horiz, color: Colors.white),
        Icon(Icons.bar_chart, color: Colors.white),
        Icon(Icons.person, color: Colors.white),
      ],
    );
  }
}
