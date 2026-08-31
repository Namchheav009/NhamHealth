import 'package:flutter/material.dart';

import '../../../models/community/community_post.dart';

const communityAudienceOptions = <CommunityPostVisibility>[
  CommunityPostVisibility.public,
  CommunityPostVisibility.followers,
];

Future<CommunityPostVisibility?> showCommunityAudiencePicker(
  BuildContext context, {
  required CommunityPostVisibility selected,
}) => showModalBottomSheet<CommunityPostVisibility>(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFB8BFBA),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Who can see your post?',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Choose who can see this post in the Community feed and on your profile.',
            style: TextStyle(
              color: Color(0xFF718078),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          ...communityAudienceOptions.map(
            (audience) => _AudienceTile(
              audience: audience,
              selected: audience == selected,
              onTap: () => Navigator.pop(sheetContext, audience),
            ),
          ),
        ],
      ),
    ),
  ),
);

class _AudienceTile extends StatelessWidget {
  const _AudienceTile({
    required this.audience,
    required this.selected,
    required this.onTap,
  });

  final CommunityPostVisibility audience;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: selected ? const Color(0xFFEAF8EF) : const Color(0xFFF8FAF8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey<String>('audience-${audience.apiValue}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDF4E5),
                  shape: BoxShape.circle,
                ),
                child: Icon(audience.icon, color: Color(0xFF078743)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audience.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      audience.description,
                      style: const TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? const Color(0xFF078743)
                    : const Color(0xFF8B938E),
                size: 27,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
