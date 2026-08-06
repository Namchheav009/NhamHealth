import 'package:flutter/material.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFF1F1F1),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 15,
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.black45,
          ),

          SizedBox(width: 12),

          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText:
                    'Search for meals, tips or healthy groceries',
                hintStyle: TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}