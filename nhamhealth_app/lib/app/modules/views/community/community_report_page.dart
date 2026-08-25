import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_background.dart';

/// Lets a member choose an anonymous reason for reporting community content.
class CommunityReportPage extends StatefulWidget {
  const CommunityReportPage({required this.subject, super.key});

  /// For example, `post` or `comment`.
  final String subject;

  @override
  State<CommunityReportPage> createState() => _CommunityReportPageState();
}

class _CommunityReportPageState extends State<CommunityReportPage> {
  int? _selectedReason;

  static const _reasons = [
    _ReportReason('Spam', Icons.warning_amber_rounded, Color(0xFFFF1D25)),
    _ReportReason('Harassment', Icons.person_outline_rounded, Color(0xFFFF9D16)),
    _ReportReason('False information', Icons.verified_user_outlined, Color(0xFF3D7CFF)),
    _ReportReason('Inappropriate content', Icons.visibility_off_outlined, Color(0xFFA741FF)),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: Get.back,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF087B3A)),
                tooltip: 'Back',
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 38),
              Text(
                'Why are you reporting this ${widget.subject}?',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              const Text(
                'Your report is anonymous.',
                style: TextStyle(fontSize: 13, color: Color(0xFF697386)),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .86),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < _reasons.length; index++) ...[
                      _reasonTile(index),
                      if (index < _reasons.length - 1)
                        const Divider(height: 1, color: Color(0xFFD9DCE1)),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _selectedReason == null ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF087B3A),
                          disabledBackgroundColor: const Color(0xFFE1E4E9),
                          disabledForegroundColor: const Color(0xFF747C8B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _reasonTile(int index) {
    final reason = _reasons[index];
    final selected = _selectedReason == index;
    return InkWell(
      onTap: () => setState(() => _selectedReason = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Icon(reason.icon, color: reason.color, size: 25),
            const SizedBox(width: 24),
            Expanded(child: Text(reason.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? const Color(0xFF087B3A) : const Color(0xFF737D8D),
              size: 27,
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    Get.back<void>();
    Get.snackbar('Report submitted', 'Thanks for helping keep the community safe.');
  }
}

class _ReportReason {
  const _ReportReason(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
