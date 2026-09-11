import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_input_dialog.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/community/community_report_controller.dart';
import '../../models/community/community_report.dart';
import '../../repositories/community/community_repository.dart';

const _green = Color(0xFF08A95B);

class CommunityReportPage extends StatefulWidget {
  const CommunityReportPage({
    this.postId,
    required this.subject,
    this.commentId,
    this.profileUserId,
    this.subjectName,
    super.key,
  }) : assert(postId != null || profileUserId != null);
  final String? postId, commentId, subjectName;
  final String subject;
  final int? profileUserId;
  @override
  State<CommunityReportPage> createState() => _CommunityReportPageState();
}

class _CommunityReportPageState extends State<CommunityReportPage> {
  late final CommunityReportController controller;
  @override
  void initState() {
    super.initState();
    controller =
        Get.isRegistered<CommunityReportController>()
            ? Get.find()
            : Get.put(CommunityReportController(repository: Get.find()));
    controller.resetForm();
  }

  bool get isPost =>
      widget.subject.toLowerCase() == 'post' && widget.commentId == null;
  @override
  Widget build(BuildContext context) => _Page(
    title: 'community.report_post_title'.tr,
    child: Column(
      children: [
        _Card(
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE4FAED),
                child: Icon(Icons.shield_outlined, color: _green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'community.report_reason_question'.trParams({
                        'subject': widget.subject,
                      }),
                      style: _label(context),
                    ),
                    const SizedBox(height: 3),
                    Text('community.report_private'.tr, style: _muted(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          child: Obx(
            () => Column(
              children: [
                for (final reason in CommunityPostReportReason.values)
                  _Reason(
                    reason: reason,
                    selected: controller.selectedReason.value == reason,
                    onTap: () => controller.selectReason(reason),
                  ),
                const SizedBox(height: 12),
                _Primary(
                  label: 'common.next'.tr,
                  enabled: controller.selectedReason.value != null,
                  onTap: next,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Future<void> next() async {
    final reason = controller.selectedReason.value;
    if (reason == null) return;
    if (isPost) {
      await Get.to<void>(
        () => CommunityReportDetailsStepPage(
          postId: widget.postId!,
          controller: controller,
        ),
      );
      return;
    }
    try {
      final repository = Get.find<CommunityRepository>();
      final id = switch (reason) {
        CommunityPostReportReason.spam => 101,
        CommunityPostReportReason.harassment => 102,
        CommunityPostReportReason.inappropriateContent => 107,
        CommunityPostReportReason.falseInformation => 104,
        CommunityPostReportReason.copyright => 111,
        CommunityPostReportReason.other => 199,
      };
      if (widget.profileUserId != null) {
        await repository.reportProfile(
          userId: widget.profileUserId!,
          reasonId: id,
        );
      } else {
        await repository.reportComment(
          postId: widget.postId!,
          commentId: widget.commentId!,
          reasonId: id,
        );
      }
      if (mounted) Get.back<void>();
      await AppAlert.actionSuccess(
        title: 'community.report_submitted'.tr,
        message: 'community.report_thanks'.tr,
      );
    } on Object catch (error) {
      await AppAlert.actionError(
        title: 'community.report_submit_failed'.tr,
        message: '$error',
      );
    }
  }
}

class CommunityReportDetailsStepPage extends StatefulWidget {
  const CommunityReportDetailsStepPage({
    required this.postId,
    required this.controller,
    super.key,
  });
  final String postId;
  final CommunityReportController controller;
  @override
  State<CommunityReportDetailsStepPage> createState() => _DetailsState();
}

class _DetailsState extends State<CommunityReportDetailsStepPage> {
  late final TextEditingController details = TextEditingController(
    text: widget.controller.description.value,
  );
  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'community.report_post_title'.tr,
    step: 2,
    child: _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('community.report_more_details'.tr, style: _title(context)),
          const SizedBox(height: 4),
          Text('community.report_details_help'.tr, style: _muted(context)),
          const SizedBox(height: 12),
          TextField(
            controller: details,
            maxLength: 500,
            minLines: 5,
            maxLines: 7,
            onChanged: widget.controller.setDescription,
            decoration: InputDecoration(
              hintText: 'community.report_details_hint'.tr,
              filled: true,
              fillColor: context.appField,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Text('community.report_add_screenshots'.tr, style: _label(context)),
          const SizedBox(height: 10),
          _AttachmentPicker(controller: widget.controller),
          const SizedBox(height: 18),
          _Buttons(
            onBack: Get.back,
            onNext: () {
              widget.controller.setDescription(details.text);
              Get.to<void>(
                () => CommunityReportReviewPage(
                  postId: widget.postId,
                  controller: widget.controller,
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class CommunityReportReviewPage extends StatelessWidget {
  const CommunityReportReviewPage({
    required this.postId,
    required this.controller,
    super.key,
  });
  final String postId;
  final CommunityReportController controller;
  @override
  Widget build(BuildContext context) => _Page(
    title: 'community.report_post_title'.tr,
    step: 3,
    child: _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('community.report_review_title'.tr, style: _title(context)),
          const SizedBox(height: 4),
          Text('community.report_review_help'.tr, style: _muted(context)),
          const SizedBox(height: 12),
          _Review(
            icon: Icons.warning_amber_rounded,
            label: 'community.report_reason'.tr,
            value: controller.selectedReason.value!.labelKey.tr,
            change: () {
              Get.back<void>();
              Get.back<void>();
            },
          ),
          _Review(
            icon: Icons.description_outlined,
            label: 'community.report_description'.tr,
            value:
                controller.description.value.isEmpty
                    ? 'common.none'.tr
                    : controller.description.value,
            change: Get.back,
          ),
          _Review(
            icon: Icons.image_outlined,
            label: 'community.report_attachments'.tr,
            value: 'community.report_image_count'.trParams({
              'count': '${controller.attachments.length}',
            }),
            change: Get.back,
          ),
          const SizedBox(height: 18),
          Obx(
            () => Column(
              children: [
                if (controller.errorMessage.value case final message?) ...[
                  Text(
                    message,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed:
                              controller.isSubmitting.value ? null : Get.back,
                          child: Text('common.back'.tr),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Primary(
                        label: 'community.submit_report'.tr,
                        loading: controller.isSubmitting.value,
                        onTap: () async {
                          if (await controller.submitReport(postId) != null) {
                            Get.off<void>(
                              () => CommunityReportSuccessPage(
                                controller: controller,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'community.report_anonymous_footer'.tr,
              textAlign: TextAlign.center,
              style: _muted(context),
            ),
          ),
        ],
      ),
    ),
  );
}

class CommunityReportSuccessPage extends StatelessWidget {
  const CommunityReportSuccessPage({required this.controller, super.key});
  final CommunityReportController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    body: AppBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: AppSpacing.pagePaddingFor(context),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE0F9EA),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      size: 76,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'community.report_thank_you'.tr,
                    style: _title(context).copyWith(fontSize: 25),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'community.report_success_message'.tr,
                    textAlign: TextAlign.center,
                    style: _muted(context).copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  _Card(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE5F9ED),
                          child: Icon(Icons.shield_outlined, color: _green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'community.report_review_guidelines_message'.tr,
                            style: _label(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _Primary(
                    label: 'common.done'.tr,
                    onTap: () {
                      controller.resetForm();
                      Get.offAllNamed<void>(AppRoutes.community);
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Get.offNamed<void>(AppRoutes.myReports),
                      child: Text('community.view_my_reports'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

enum _ReportFilter { all, pending, resolved, noViolation }

class CommunityMyReportsPage extends StatefulWidget {
  const CommunityMyReportsPage({this.controller, super.key});
  final CommunityReportController? controller;
  @override
  State<CommunityMyReportsPage> createState() => _MyReportsState();
}

class _MyReportsState extends State<CommunityMyReportsPage> {
  late final CommunityReportController controller;
  _ReportFilter _selectedFilter = _ReportFilter.all;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? Get.find();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.fetchMyReports(),
    );
  }

  List<CommunityReport> _getFilteredReports(List<CommunityReport> list) {
    return switch (_selectedFilter) {
      _ReportFilter.all => list,
      _ReportFilter.pending =>
        list
            .where(
              (r) =>
                  r.status == CommunityReportStatus.pending ||
                  r.status == CommunityReportStatus.underReview,
            )
            .toList(),
      _ReportFilter.resolved =>
        list.where((r) => r.status == CommunityReportStatus.resolved).toList(),
      _ReportFilter.noViolation =>
        list
            .where(
              (r) =>
                  r.status == CommunityReportStatus.noViolation ||
                  r.status == CommunityReportStatus.rejected,
            )
            .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppSpacing.pageHorizontalFor(context);
    final contentPadding = EdgeInsets.fromLTRB(
      horizontalPadding,
      12,
      horizontalPadding,
      AppSpacing.pageBottom,
    );

    return _Page(
      title: 'community.my_reports'.tr,
      scrollable: false,
      child: Obx(() {
        if (controller.isLoading.value && controller.myReports.isEmpty) {
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: contentPadding,
            child: const PageSkeleton.reports(),
          );
        }
        if (controller.errorMessage.value != null &&
            controller.myReports.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: contentPadding,
            child: _Message(
              icon: Icons.cloud_off_rounded,
              text: controller.errorMessage.value!,
              action: controller.fetchMyReports,
            ),
          );
        }

        final reports = controller.myReports;
        final allCount = reports.length;
        final pendingCount =
            reports
                .where(
                  (r) =>
                      r.status == CommunityReportStatus.pending ||
                      r.status == CommunityReportStatus.underReview,
                )
                .length;
        final resolvedCount =
            reports
                .where((r) => r.status == CommunityReportStatus.resolved)
                .length;
        final noViolationCount =
            reports
                .where(
                  (r) =>
                      r.status == CommunityReportStatus.noViolation ||
                      r.status == CommunityReportStatus.rejected,
                )
                .length;

        final filtered = _getFilteredReports(reports);

        return RefreshIndicator(
          color: _green,
          onRefresh: controller.fetchMyReports,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: contentPadding,
            children: [
              _buildSafetyBanner(context),
              const SizedBox(height: 14),
              _buildFilterChips(
                context,
                allCount: allCount,
                pendingCount: pendingCount,
                resolvedCount: resolvedCount,
                noViolationCount: noViolationCount,
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: context.appMutedText,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'community.report_empty'.tr,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filtered.map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReportList(
                      report: report,
                      onTap:
                          () => Get.to<void>(
                            () => CommunityReportDetailPage(
                              reportId: report.id,
                              controller: controller,
                            ),
                          ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              _buildNeedHelpCard(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSafetyBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102820) : const Color(0xFFE8F7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? _green.withValues(alpha: 0.3) : const Color(0xFFBCE7D3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _green.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.shield_outlined, color: _green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'community.report_keep_safe_title'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'community.report_keep_safe_desc'.tr,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: _green,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context, {
    required int allCount,
    required int pendingCount,
    required int resolvedCount,
    required int noViolationCount,
  }) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    child: Row(
      children: [
        _FilterChipItem(
          label: 'community.report_filter_all'.tr,
          count: allCount,
          selected: _selectedFilter == _ReportFilter.all,
          onTap: () => setState(() => _selectedFilter = _ReportFilter.all),
        ),
        const SizedBox(width: 8),
        _FilterChipItem(
          label: 'community.report_filter_pending'.tr,
          count: pendingCount,
          selected: _selectedFilter == _ReportFilter.pending,
          onTap: () => setState(() => _selectedFilter = _ReportFilter.pending),
        ),
        const SizedBox(width: 8),
        _FilterChipItem(
          label: 'community.report_filter_resolved'.tr,
          count: resolvedCount,
          selected: _selectedFilter == _ReportFilter.resolved,
          onTap: () => setState(() => _selectedFilter = _ReportFilter.resolved),
        ),
        const SizedBox(width: 8),
        _FilterChipItem(
          label: 'community.report_filter_no_violation'.tr,
          count: noViolationCount,
          selected: _selectedFilter == _ReportFilter.noViolation,
          onTap:
              () => setState(() => _selectedFilter = _ReportFilter.noViolation),
        ),
      ],
    ),
  );

  Widget _buildNeedHelpCard(BuildContext context) => _Card(
    child: InkWell(
      onTap: () => Get.to<void>(() => const CommunityGuidelinesPage()),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appMutedSurface,
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: context.appText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'community.report_need_help'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'community.report_need_help_desc'.tr,
                  style: TextStyle(color: context.appMutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.appMutedText,
            size: 22,
          ),
        ],
      ),
    ),
  );
}

class CommunityReportDetailPage extends StatefulWidget {
  const CommunityReportDetailPage({
    required this.reportId,
    this.controller,
    super.key,
  });
  final int reportId;
  final CommunityReportController? controller;
  @override
  State<CommunityReportDetailPage> createState() => _ReportDetailState();
}

class _ReportDetailState extends State<CommunityReportDetailPage> {
  late final CommunityReportController controller;
  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? Get.find();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.fetchReportDetails(widget.reportId),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'community.report_details_title'.tr,
    scrollable: true,
    child: Obx(() {
      if (controller.isLoading.value) {
        return const PageSkeleton.reportDetail();
      }
      if (controller.errorMessage.value case final error?) {
        return _Message(
          icon: Icons.error_outline,
          text: error,
          action: () => controller.fetchReportDetails(widget.reportId),
        );
      }
      final report = controller.selectedReport.value;
      if (report == null || report.id != widget.reportId) {
        return const PageSkeleton.reportDetail();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, report),
          const SizedBox(height: 12),
          _buildDescriptionCard(context, report),
          const SizedBox(height: 12),
          _buildReportedContentCard(context, report),
          const SizedBox(height: 12),
          _buildStatusTimelineCard(context, report),
          const SizedBox(height: 12),
          _buildWhatHappensNextCard(context),
          if (report.status == CommunityReportStatus.pending) ...[
            const SizedBox(height: 14),
            _buildDeleteReportButton(context, report),
          ],
          const SizedBox(height: 12),
          _buildGuidelinesCard(context),
        ],
      );
    }),
  );

  Widget _buildSummaryCard(BuildContext context, CommunityReport report) =>
      _Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _reasonColor(report.reason).withValues(alpha: .12),
              ),
              child: Icon(
                _reasonIcon(report.reason),
                color: _reasonColor(report.reason),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.reason.labelKey.tr,
                    style: TextStyle(
                      color: context.appText,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    report.reason.guidelineKey.tr,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Status(status: report.status, showIcon: true),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.appMutedSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${report.id}',
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(report.createdAt),
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('h:mm a').format(report.createdAt),
                  style: TextStyle(color: context.appMutedText, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildDescriptionCard(BuildContext context, CommunityReport report) =>
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'community.report_description'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (report.status == CommunityReportStatus.pending)
                  InkWell(
                    onTap: () => _showEditDescriptionDialog(context, report),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: _green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'community.edit_description'.tr,
                            style: const TextStyle(
                              color: _green,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (report.description.isNotEmpty)
              Text(
                report.description,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 14,
                  height: 1.45,
                ),
              )
            else
              Text(
                'community.report_no_description'.tr,
                style: TextStyle(
                  color: context.appMutedText,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      );

  Widget _buildReportedContentCard(
    BuildContext context,
    CommunityReport report,
  ) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'community.reported_content_title'.tr,
            style: TextStyle(
              color: context.appText,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appMutedSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: context.appMutedSurface,
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: context.appMutedText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'User',
                      style: TextStyle(
                        color: context.appText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '@content',
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  report.postPreview.isNotEmpty
                      ? report.postPreview
                      : 'community.reported_post'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (report.attachments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 14,
                        color: context.appMutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${report.attachments.length} ${report.attachments.length == 1 ? "image" : "images"}',
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.attachments.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder:
                          (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              report.attachments[i],
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, _, _) => Container(
                                    width: 72,
                                    height: 72,
                                    color: context.appMutedSurface,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 20,
                                    ),
                                  ),
                            ),
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimelineCard(
    BuildContext context,
    CommunityReport report,
  ) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'community.report_status'.tr,
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        _ConnectedTimeline(report: report),
        if (report.adminMessage.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'community.report_review_result'.tr,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.adminMessage,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildWhatHappensNextCard(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shield_outlined, color: _green, size: 20),
            const SizedBox(width: 8),
            Text(
              'community.report_what_happens_next'.tr,
              style: TextStyle(
                color: context.appText,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'community.report_what_happens_next_desc'.tr,
          style: TextStyle(
            color: context.appMutedText,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget _buildDeleteReportButton(
    BuildContext context,
    CommunityReport report,
  ) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton.icon(
      onPressed: () => _showDeleteConfirmDialog(context, report),
      icon: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.redAccent,
        size: 18,
      ),
      label: Text(
        'community.report_delete'.tr,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.redAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _buildGuidelinesCard(BuildContext context) => _Card(
    child: InkWell(
      onTap: () => Get.to<void>(() => const CommunityGuidelinesPage()),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appMutedSurface,
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: context.appText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'community.community_guidelines'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'community.report_guidelines_desc'.tr,
                  style: TextStyle(color: context.appMutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.appMutedText,
            size: 22,
          ),
        ],
      ),
    ),
  );

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    CommunityReport report,
  ) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'common.alert_dialog'.tr,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogCtx, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: const SizedBox.expand(),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(22),
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 29, 28, 28),
                        decoration: BoxDecoration(
                          color: dialogCtx.appElevatedSurface,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: dialogCtx.appElevatedSurface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.16),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.errorCoral,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'community.report_delete_confirm'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: dialogCtx.appText,
                                fontSize: 20,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'community.report_delete_desc'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: dialogCtx.appMutedText,
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed:
                                          () => Navigator.of(
                                            dialogCtx,
                                          ).pop(false),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: dialogCtx.appBorder,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            21,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: Text('common.cancel'.tr),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: FilledButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(dialogCtx).pop(true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.errorCoral,
                                        foregroundColor: Colors.white,
                                        elevation: 5,
                                        shadowColor: AppColors.errorCoral
                                            .withValues(alpha: 0.38),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            21,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: Text('community.report_delete'.tr),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      controller.removeReportLocally(report.id);
      Get.back<void>();
      await AppAlert.actionSuccess(
        title: 'community.report_deleted_success'.tr,
        message: '',
      );
    }
  }

  Future<void> _showEditDescriptionDialog(
    BuildContext context,
    CommunityReport report,
  ) async {
    final updatedText = await AppInputDialog.show(
      context: context,
      title: 'community.report_edit_description',
      subtitle: 'community.report_edit_description_hint',
      labelText: 'community.report_description',
      prefixIcon: Icons.description_outlined,
      icon: Icons.edit_note_rounded,
      initialValue: report.description,
      minLines: 3,
      maxLines: 5,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
      confirmText: 'common.save',
      cancelText: 'common.cancel',
      allowEmpty: true,
    );

    if (updatedText != null && mounted) {
      controller.updateDescriptionLocally(report.id, updatedText);
    }
  }
}

class CommunityGuidelinesPage extends StatelessWidget {
  const CommunityGuidelinesPage({super.key});
  @override
  Widget build(BuildContext context) => _Page(
    title: 'community.community_guidelines'.tr,
    child: Column(
      children: [
        for (final reason in CommunityPostReportReason.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Card(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _reasonColor(reason).withValues(alpha: .12),
                  child: Icon(_reasonIcon(reason), color: _reasonColor(reason)),
                ),
                title: Text(reason.labelKey.tr, style: _label(context)),
                subtitle: Text(reason.guidelineKey.tr, style: _muted(context)),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.child,
    this.step,
    this.scrollable = true,
  });

  final String title;
  final Widget child;
  final int? step;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppSpacing.pageHorizontalFor(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.pageTop,
                    horizontalPadding,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.maxContentWidth,
                      ),
                      child: AppBackHeader(title: title, onBack: Get.back),
                    ),
                  ),
                ),
                if (step != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: _Steps(current: step!),
                  ),
                Expanded(
                  child:
                      scrollable
                          ? SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              12,
                              horizontalPadding,
                              AppSpacing.pageBottom,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppSpacing.maxContentWidth,
                                ),
                                child: child,
                              ),
                            ),
                          )
                          : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: AppSpacing.maxContentWidth,
                              ),
                              child: child,
                            ),
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

class _Steps extends StatelessWidget {
  const _Steps({required this.current});
  final int current;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 3; i++) ...[
        CircleAvatar(
          radius: 13,
          backgroundColor: i <= current ? _green : context.appMutedSurface,
          child:
              i < current
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                    '$i',
                    style: TextStyle(
                      color: i <= current ? Colors.white : context.appMutedText,
                    ),
                  ),
        ),
        if (i < 3)
          Container(
            width: 40,
            height: 2,
            color: i < current ? _green : context.appBorder,
          ),
      ],
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.appBorder),
      boxShadow: context.appTileShadow,
    ),
    child: child,
  );
}

class _Reason extends StatelessWidget {
  const _Reason({
    required this.reason,
    required this.selected,
    required this.onTap,
  });
  final CommunityPostReportReason reason;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _reasonColor(reason).withValues(alpha: .12),
            child: Icon(
              _reasonIcon(reason),
              color: _reasonColor(reason),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(reason.labelKey.tr, style: _label(context))),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? _green : context.appMutedText,
          ),
        ],
      ),
    ),
  );
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({required this.controller});
  final CommunityReportController controller;
  @override
  Widget build(BuildContext context) => Obx(
    () => Column(
      children: [
        if (controller.attachments.isNotEmpty)
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.attachments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder:
                  (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          controller.attachments[i].bytes,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 3,
                        top: 3,
                        child: InkWell(
                          onTap: () => controller.removeAttachment(i),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        if (controller.attachments.isNotEmpty) const SizedBox(height: 10),
        InkWell(
          onTap:
              controller.attachments.length >= 5 ? null : () => pick(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: context.appField,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appBorder),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 34,
                  color: context.appMutedText,
                ),
                const SizedBox(height: 6),
                Text('community.report_add_photo'.tr, style: _label(context)),
                Text('community.report_max_images'.tr, style: _muted(context)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Future<void> pick(BuildContext context) async {
    try {
      final images = await ImagePicker().pickMultiImage(
        imageQuality: 88,
        limit: 5 - controller.attachments.length,
      );
      final values = <CommunityReportAttachmentDraft>[];
      for (final image in images) {
        values.add(
          CommunityReportAttachmentDraft(
            bytes: await image.readAsBytes(),
            name: image.name,
          ),
        );
      }
      controller.addAttachments(values);
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

class _Review extends StatelessWidget {
  const _Review({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
  });
  final IconData icon;
  final String label, value;
  final VoidCallback change;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.appBorder)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: context.appMutedSurface,
          child: Icon(icon, color: context.appMutedText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _label(context)),
              const SizedBox(height: 4),
              Text(value, style: _muted(context)),
            ],
          ),
        ),
        TextButton(onPressed: change, child: Text('common.change'.tr)),
      ],
    ),
  );
}

class _Buttons extends StatelessWidget {
  const _Buttons({required this.onBack, required this.onNext});
  final VoidCallback onBack, onNext;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: onBack,
            child: Text('common.back'.tr),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: _Primary(label: 'common.next'.tr, onTap: onNext)),
    ],
  );
}

class _Primary extends StatelessWidget {
  const _Primary({
    required this.label,
    this.onTap,
    this.enabled = true,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool enabled, loading;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      onPressed: enabled && !loading ? onTap : null,
      style: FilledButton.styleFrom(
        backgroundColor: _green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      child:
          loading
              ? const SizedBox.square(
                dimension: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
    ),
  );
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.report, required this.onTap});
  final CommunityReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _reasonColor(report.reason).withValues(alpha: .12),
            ),
            child: Icon(
              _reasonIcon(report.reason),
              color: _reasonColor(report.reason),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.reason.labelKey.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                if (report.description.isNotEmpty)
                  Text(
                    report.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appMutedText, fontSize: 13),
                  )
                else if (report.postPreview.isNotEmpty)
                  Text(
                    report.postPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appMutedText, fontSize: 13),
                  )
                else
                  Text(
                    'community.report_no_description'.tr,
                    style: TextStyle(
                      color: context.appMutedText.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: context.appMutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(report.createdAt),
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _Status(status: report.status),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: context.appMutedText,
            size: 22,
          ),
        ],
      ),
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.status, this.showIcon = false});
  final CommunityReportStatus status;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      CommunityReportStatus.pending => (Colors.blue, Icons.access_time_rounded),
      CommunityReportStatus.underReview => (Colors.blue, Icons.sync_rounded),
      CommunityReportStatus.resolved => (
        _green,
        Icons.check_circle_outline_rounded,
      ),
      CommunityReportStatus.noViolation => (
        Colors.grey.shade700,
        Icons.remove_circle_outline_rounded,
      ),
      CommunityReportStatus.rejected => (
        Colors.redAccent,
        Icons.cancel_outlined,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            status.labelKey.tr,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedTimeline extends StatelessWidget {
  const _ConnectedTimeline({required this.report});
  final CommunityReport report;

  @override
  Widget build(BuildContext context) {
    final isReviewed = report.status != CommunityReportStatus.pending;
    final isDone =
        report.status == CommunityReportStatus.resolved ||
        report.status == CommunityReportStatus.noViolation ||
        report.status == CommunityReportStatus.rejected;

    final resolutionTitle = switch (report.status) {
      CommunityReportStatus.resolved => 'community.report_status_resolved'.tr,
      CommunityReportStatus.noViolation =>
        'community.report_status_no_violation'.tr,
      CommunityReportStatus.rejected => 'community.report_status_closed'.tr,
      _ => 'community.report_resolution'.tr,
    };

    final resolutionSubtitle = switch (report.status) {
      CommunityReportStatus.resolved =>
        report.reviewedAt != null ? _date(report.reviewedAt!) : '',
      CommunityReportStatus.noViolation =>
        report.reviewedAt != null ? _date(report.reviewedAt!) : '',
      CommunityReportStatus.rejected =>
        report.reviewedAt != null ? _date(report.reviewedAt!) : '',
      _ => '',
    };

    return Column(
      children: [
        _TimelineItem(
          isFirst: true,
          isCompleted: true,
          isActive: true,
          title: 'community.report_submitted'.tr,
          subtitle: _date(report.createdAt),
        ),
        _TimelineItem(
          isCompleted: isReviewed,
          isActive:
              isReviewed || report.status == CommunityReportStatus.pending,
          title: 'community.report_status_review'.tr,
          subtitle: isReviewed ? 'community.report_being_reviewed'.tr : '',
        ),
        _TimelineItem(
          isLast: true,
          isCompleted: isDone,
          isActive: isDone,
          title: resolutionTitle,
          subtitle: resolutionSubtitle,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.isActive = false,
    this.isFirst = false,
    this.isLast = false,
  });

  final String title, subtitle;
  final bool isCompleted, isActive, isFirst, isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor =
        isCompleted
            ? _green
            : (isActive ? Colors.blue : context.appMutedSurface);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border:
                        !isCompleted && !isActive
                            ? Border.all(color: context.appBorder, width: 2)
                            : null,
                  ),
                  child:
                      isCompleted
                          ? const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          )
                          : (isActive
                              ? const Center(
                                child: SizedBox(
                                  width: 6,
                                  height: 6,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                              : null),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? _green : context.appBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.appText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? _green : context.appElevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? _green : context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : context.appText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : context.appMutedSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: selected ? Colors.white : context.appMutedText,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.action,
  });
  final IconData icon;
  final String text;
  final Future<void> Function() action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80),
    child: Column(
      children: [
        Icon(icon, size: 52, color: context.appMutedText),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: action, child: Text('common.try_again'.tr)),
      ],
    ),
  );
}

String _date(DateTime value) => DateFormat.yMMMd().add_jm().format(value);
TextStyle _title(BuildContext c) =>
    TextStyle(color: c.appText, fontSize: 18, fontWeight: FontWeight.w800);
TextStyle _label(BuildContext c) =>
    TextStyle(color: c.appText, fontSize: 14, fontWeight: FontWeight.w700);
TextStyle _muted(BuildContext c) =>
    TextStyle(color: c.appMutedText, fontSize: 12, height: 1.4);
IconData _reasonIcon(CommunityPostReportReason r) => switch (r) {
  CommunityPostReportReason.spam => Icons.warning_amber_rounded,
  CommunityPostReportReason.harassment => Icons.person_outline_rounded,
  CommunityPostReportReason.inappropriateContent =>
    Icons.verified_user_outlined,
  CommunityPostReportReason.falseInformation => Icons.visibility_off_outlined,
  CommunityPostReportReason.copyright => Icons.copyright_rounded,
  CommunityPostReportReason.other => Icons.more_horiz_rounded,
};
Color _reasonColor(CommunityPostReportReason r) => switch (r) {
  CommunityPostReportReason.spam => Colors.redAccent,
  CommunityPostReportReason.harassment => Colors.orange,
  CommunityPostReportReason.inappropriateContent => Colors.blueAccent,
  CommunityPostReportReason.falseInformation => Colors.purpleAccent,
  CommunityPostReportReason.copyright => _green,
  CommunityPostReportReason.other => Colors.blueGrey,
};
