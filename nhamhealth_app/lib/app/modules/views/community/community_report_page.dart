import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
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
    body: AppBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.all(20),
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

class CommunityMyReportsPage extends StatefulWidget {
  const CommunityMyReportsPage({this.controller, super.key});
  final CommunityReportController? controller;
  @override
  State<CommunityMyReportsPage> createState() => _MyReportsState();
}

class _MyReportsState extends State<CommunityMyReportsPage> {
  late final CommunityReportController controller;
  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? Get.find();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.fetchMyReports(),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'community.my_reports'.tr,
    child: Obx(() {
      if (controller.isLoading.value && controller.myReports.isEmpty) {
        return const PageSkeleton.reports();
      }
      if (controller.errorMessage.value != null &&
          controller.myReports.isEmpty) {
        return _Message(
          icon: Icons.cloud_off_rounded,
          text: controller.errorMessage.value!,
          action: controller.fetchMyReports,
        );
      }
      if (controller.myReports.isEmpty) {
        return _Message(
          icon: Icons.flag_outlined,
          text: 'community.report_empty'.tr,
          action: controller.fetchMyReports,
        );
      }
      return RefreshIndicator(
        onRefresh: controller.fetchMyReports,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: controller.myReports.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final report = controller.myReports[index];
            return _ReportList(
              report: report,
              onTap:
                  () => Get.to<void>(
                    () => CommunityReportDetailPage(
                      reportId: report.id,
                      controller: controller,
                    ),
                  ),
            );
          },
        ),
      );
    }),
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
    child: Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _green));
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
        return const SizedBox.shrink();
      }
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _reasonColor(
                    report.reason,
                  ).withValues(alpha: .12),
                  child: Icon(
                    _reasonIcon(report.reason),
                    color: _reasonColor(report.reason),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.reason.labelKey.tr, style: _title(context)),
                      const SizedBox(height: 4),
                      _Status(status: report.status),
                    ],
                  ),
                ),
                Text('#${report.id}', style: _muted(context)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${'community.report_submitted_on'.tr}\n${_date(report.createdAt)}',
              style: _muted(context),
            ),
            const Divider(height: 28),
            _Section(
              title: 'community.report_description'.tr,
              value:
                  report.description.isEmpty
                      ? 'common.none'.tr
                      : report.description,
            ),
            if (report.postPreview.isNotEmpty)
              _Section(
                title: 'community.reported_post'.tr,
                value: report.postPreview,
              ),
            if (report.attachments.isNotEmpty) ...[
              Text(
                '${'community.report_attachments'.tr} (${report.attachments.length})',
                style: _label(context),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.attachments.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder:
                      (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          report.attachments[i],
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 22),
            ],
            _Timeline(report: report),
            if (report.adminMessage.isNotEmpty) ...[
              const Divider(height: 28),
              _Section(
                title: 'community.report_review_result'.tr,
                value: report.adminMessage,
              ),
            ],
          ],
        ),
      );
    }),
  );
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
                subtitle: Text(
                  'community.report_guideline_${reason.name}'.tr,
                  style: _muted(context),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.child, this.step});
  final String title;
  final Widget child;
  final int? step;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                  child: AppBackHeader(title: title, onBack: Get.back),
                ),
                if (step != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: _Steps(current: step!),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _reasonColor(report.reason).withValues(alpha: .12),
            child: Icon(
              _reasonIcon(report.reason),
              color: _reasonColor(report.reason),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.reason.labelKey.tr, style: _label(context)),
                const SizedBox(height: 5),
                Text(_date(report.createdAt), style: _muted(context)),
                if (report.postPreview.isNotEmpty)
                  Text(
                    report.postPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _muted(context),
                  ),
              ],
            ),
          ),
          _Status(status: report.status),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.status});
  final CommunityReportStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      CommunityReportStatus.pending ||
      CommunityReportStatus.underReview => Colors.blue,
      CommunityReportStatus.resolved => _green,
      CommunityReportStatus.noViolation ||
      CommunityReportStatus.rejected => context.appMutedText,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.labelKey.tr,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.report});
  final CommunityReport report;
  @override
  Widget build(BuildContext context) {
    final reviewed = report.status != CommunityReportStatus.pending;
    final done =
        report.status == CommunityReportStatus.resolved ||
        report.status == CommunityReportStatus.noViolation ||
        report.status == CommunityReportStatus.rejected;
    return Column(
      children: [
        _Line(
          active: true,
          title: 'community.report_submitted'.tr,
          subtitle: _date(report.createdAt),
        ),
        _Line(
          active: reviewed,
          title: 'community.report_status_review'.tr,
          subtitle: reviewed ? 'community.report_being_reviewed'.tr : '',
        ),
        _Line(
          active: done,
          title:
              done
                  ? report.status.labelKey.tr
                  : 'community.report_resolution'.tr,
          subtitle: '',
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.active,
    required this.title,
    required this.subtitle,
  });
  final bool active;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? _green : context.appMutedSurface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _label(context)),
              if (subtitle.isNotEmpty) Text(subtitle, style: _muted(context)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.value});
  final String title, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _label(context)),
        const SizedBox(height: 5),
        Text(value, style: _muted(context).copyWith(fontSize: 14)),
      ],
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
