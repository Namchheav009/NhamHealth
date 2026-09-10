import 'package:get/get.dart';

import '../../models/community/community_report.dart';
import '../../repositories/community/community_repository.dart';

class CommunityReportController extends GetxController {
  CommunityReportController({required CommunityRepository repository})
    : _repository = repository;

  final CommunityRepository _repository;
  final selectedReason = Rxn<CommunityPostReportReason>();
  final description = ''.obs;
  final attachments = <CommunityReportAttachmentDraft>[].obs;
  final isSubmitting = false.obs;
  final myReports = <CommunityReport>[].obs;
  final selectedReport = Rxn<CommunityReport>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  void selectReason(CommunityPostReportReason reason) =>
      selectedReason.value = reason;
  void setDescription(String value) =>
      description.value =
          value.runes.length <= 500
              ? value
              : String.fromCharCodes(value.runes.take(500));

  void addAttachments(Iterable<CommunityReportAttachmentDraft> values) {
    final available = 5 - attachments.length;
    if (available <= 0) return;
    attachments.addAll(values.take(available));
  }

  void removeAttachment(int index) {
    if (index >= 0 && index < attachments.length) attachments.removeAt(index);
  }

  Future<CommunityReport?> submitReport(String postId) async {
    final reason = selectedReason.value;
    if (reason == null || isSubmitting.value) return null;
    isSubmitting.value = true;
    errorMessage.value = null;
    try {
      final report = await _repository.submitPostReport(
        postId: postId,
        reason: reason,
        description: description.value,
        attachments: attachments.toList(growable: false),
      );
      selectedReport.value = report;
      return report;
    } on Object catch (error) {
      errorMessage.value =
          error.toString().replaceFirst('Exception: ', '').trim();
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> fetchMyReports() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      myReports.assignAll(await _repository.getMyReports());
    } on Object catch (error) {
      errorMessage.value =
          error.toString().replaceFirst('Exception: ', '').trim();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchReportDetails(int id) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      selectedReport.value = await _repository.getReportDetails(id);
    } on Object catch (error) {
      errorMessage.value =
          error.toString().replaceFirst('Exception: ', '').trim();
    } finally {
      isLoading.value = false;
    }
  }

  void resetForm() {
    selectedReason.value = null;
    description.value = '';
    attachments.clear();
    errorMessage.value = null;
  }
}
