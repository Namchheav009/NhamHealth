import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
import '../../models/community/community_report_reason.dart';
import '../../repositories/community/community_repository.dart';

/// Lets a member select an admin-managed reason and report a community post.
class CommunityReportPage extends StatefulWidget {
  const CommunityReportPage({
    this.postId,
    required this.subject,
    this.commentId,
    this.profileUserId,
    this.subjectName,
    super.key,
  }) : assert(postId != null || profileUserId != null);

  final String? postId;
  final String subject;
  final String? commentId;
  final int? profileUserId;
  final String? subjectName;

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppBackButton(
                          onPressed: _submitting ? null : Get.back,
                        ),
                      ),
                      Text(
                        'Report ${widget.subject}',
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appElevatedSurface.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: context.appSoftGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF087B3A),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Why are you reporting ${_subjectLabel}?',
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 14,
                                height: 1.35,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Your report is anonymous and will be reviewed.',
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _content(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  String get _subjectLabel {
    final name = widget.subjectName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return 'this ${widget.subject}';
  }

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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            height: math.min(_reasons.length * 59.0, 236),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _reasons.length,
              separatorBuilder:
                  (_, _) => const Divider(
                    height: 1,
                    indent: 62,
                  ),
              itemBuilder: (_, index) => _reasonTile(_reasons[index], index),
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: context.appBorder),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed:
                  _selectedReasonId == null || _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF087B3A),
                disabledBackgroundColor: const Color(0xFFE1E4E9),
                disabledForegroundColor: const Color(0xFF747C8B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
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
      height: 58,
      child: InkWell(
        onTap:
            _submitting
                ? null
                : () => setState(() => _selectedReasonId = reason.id),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected ? context.appSelectedSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors[index % colors.length].withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icons[index % icons.length],
                  color: colors[index % colors.length],
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reason.name,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
                size: 24,
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
      final profileUserId = widget.profileUserId;
      final commentId = widget.commentId;
      if (profileUserId != null) {
        await _repository.reportProfile(
          userId: profileUserId,
          reasonId: reasonId,
        );
      } else if (commentId == null) {
        await _repository.reportPost(
          postId: widget.postId!,
          reasonId: reasonId,
        );
      } else {
        await _repository.reportComment(
          postId: widget.postId!,
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
