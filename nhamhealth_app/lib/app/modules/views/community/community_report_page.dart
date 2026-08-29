import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
import '../../models/community/community_report_reason.dart';
import '../../repositories/community/community_repository.dart';

/// Lets a member select an admin-managed reason and report a community post.
class CommunityReportPage extends StatefulWidget {
  const CommunityReportPage({
    required this.postId,
    required this.subject,
    this.commentId,
    super.key,
  });

  final String postId;
  final String subject;
  final String? commentId;

  @override
  State<CommunityReportPage> createState() => _CommunityReportPageState();
}

class _CommunityReportPageState extends State<CommunityReportPage> {
  final CommunityRepository _repository = Get.find<CommunityRepository>();
  List<CommunityReportReason> _reasons = const [];
  int? _selectedReasonId;
  String? _error;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reasons = await _repository.getReportReasons();
      if (!mounted) return;
      setState(() => _reasons = reasons);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 28, 30, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBackButton(onPressed: _submitting ? null : Get.back),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Report',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Why are you reporting this ${widget.subject}?',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Your report is anonymous.',
                style: TextStyle(fontSize: 12, color: Color(0xFF697386)),
              ),
              const SizedBox(height: 26),
              _content(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _content() {
    if (_loading) {
      return const SizedBox(
        height: 276,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF087B3A)),
        ),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 276,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 38,
              color: Color(0xFF697386),
            ),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _loadReasons,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (_reasons.isEmpty) {
      return const SizedBox(
        height: 276,
        child: Center(
          child: Text(
            'Reporting is not available right now.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 0, 7, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: math.min(_reasons.length * 47.0, 188),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _reasons.length,
              separatorBuilder:
                  (_, _) => const Divider(
                    height: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Color(0xFFD9DCE1),
                  ),
              itemBuilder: (_, index) => _reasonTile(_reasons[index], index),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              onPressed:
                  _selectedReasonId == null || _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF087B3A),
                disabledBackgroundColor: const Color(0xFFE1E4E9),
                disabledForegroundColor: const Color(0xFF747C8B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:
                  _submitting
                      ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonTile(CommunityReportReason reason, int index) {
    final selected = _selectedReasonId == reason.id;
    final icons = [
      Icons.warning_amber_rounded,
      Icons.person_outline_rounded,
      Icons.verified_user_outlined,
      Icons.visibility_off_outlined,
    ];
    final colors = [
      const Color(0xFFFF1D25),
      const Color(0xFFFF9D16),
      const Color(0xFF3D7CFF),
      const Color(0xFFA741FF),
    ];
    return SizedBox(
      height: 46,
      child: InkWell(
        onTap:
            _submitting
                ? null
                : () => setState(() => _selectedReasonId = reason.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              Icon(
                icons[index % icons.length],
                color: colors[index % colors.length],
                size: 23,
              ),
              const SizedBox(width: 23),
              Expanded(
                child: Text(
                  reason.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color:
                    selected
                        ? const Color(0xFF087B3A)
                        : const Color(0xFF737D8D),
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final reasonId = _selectedReasonId;
    if (reasonId == null) return;
    setState(() => _submitting = true);
    try {
      final commentId = widget.commentId;
      if (commentId == null) {
        await _repository.reportPost(postId: widget.postId, reasonId: reasonId);
      } else {
        await _repository.reportComment(
          postId: widget.postId,
          commentId: commentId,
          reasonId: reasonId,
        );
      }
      if (!mounted) return;
      Get.back<void>();
      Get.snackbar(
        'Report submitted',
        'Thanks for helping keep the community safe.',
      );
    } on Object catch (error) {
      if (mounted) Get.snackbar('Could not submit report', error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
