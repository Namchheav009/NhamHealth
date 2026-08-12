import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
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
        boxShadow: AppShadows.search,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(28),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: AppColors.secondaryText,
                size: 25,
              ),
              SizedBox(width: 13),
              Expanded(
                child: TextField(
                  style: TextStyle(fontSize: 11, color: AppColors.primaryText),
                  cursorColor: AppColors.primaryGreen,
                  decoration: InputDecoration(
                    hintText: 'Search for meals, tips or healthy groceries',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
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
