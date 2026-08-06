import 'package:flutter/material.dart';

import 'inner_shadow.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF66706A).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(28),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: Color(0xFF8B8B8B), size: 25),
              SizedBox(width: 13),
              Expanded(
                child: TextField(
                  style: TextStyle(fontSize: 11, color: Color(0xFF4D4D4D)),
                  cursorColor: Color(0xFF00A651),
                  decoration: InputDecoration(
                    hintText: 'Search for meals, tips or healthy groceries',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A7A7A),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
