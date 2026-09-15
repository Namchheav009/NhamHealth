import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/favorites/favorites_controller.dart';

class PostFilterSheet extends StatefulWidget {
  const PostFilterSheet({
    super.key,
    required this.initialSort,
    required this.onApply,
  });

  final FavoritePostSort initialSort;
  final ValueChanged<FavoritePostSort> onApply;

  @override
  State<PostFilterSheet> createState() => _PostFilterSheetState();
}

class _PostFilterSheetState extends State<PostFilterSheet> {
  late FavoritePostSort selectedSort;

  @override
  void initState() {
    super.initState();
    selectedSort = widget.initialSort;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.appStrongBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 21,
                  color: context.appColorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'favorites.filter_by_post'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed:
                    selectedSort == FavoritePostSort.newest
                        ? null
                        : () => setState(
                          () => selectedSort = FavoritePostSort.newest,
                        ),
                child: Text('common.reset'.tr),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SortOption(
                  label: 'favorites.new'.tr,
                  selected: selectedSort == FavoritePostSort.newest,
                  onTap:
                      () => setState(
                        () => selectedSort = FavoritePostSort.newest,
                      ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SortOption(
                  label: 'favorites.oldest'.tr,
                  selected: selectedSort == FavoritePostSort.oldest,
                  onTap:
                      () => setState(
                        () => selectedSort = FavoritePostSort.oldest,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () {
                widget.onApply(selectedSort);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: context.appColorScheme.primary,
                foregroundColor: context.appColorScheme.onPrimary,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'common.apply_filter'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.appColorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 46,
            decoration: BoxDecoration(
              color:
                  selected
                      ? context.appSelectedSurface
                      : context.appSubtleSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? accent : context.appBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Icon(Icons.check_circle_rounded, color: accent, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? accent : context.appText,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
