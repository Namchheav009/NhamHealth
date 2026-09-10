import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/services/dynamic_notification_sync_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_alert.dart';

class DynamicNotificationStudioSheet extends StatefulWidget {
  const DynamicNotificationStudioSheet({super.key});

  static void show(BuildContext context) {
    Get.bottomSheet<void>(
      const DynamicNotificationStudioSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
    );
  }

  @override
  State<DynamicNotificationStudioSheet> createState() =>
      _DynamicNotificationStudioSheetState();
}

class _DynamicNotificationStudioSheetState
    extends State<DynamicNotificationStudioSheet> {
  bool _isCustomExpanded = false;
  final _titleController = TextEditingController(text: 'Healthy Meal Reminder');
  final _messageController = TextEditingController(
    text: 'Time for Lunch! 🥗 Keep your healthy streak going.',
  );
  final _subTextController = TextEditingController(text: 'NhamHealth Alert');
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _subTextController.dispose();
    super.dispose();
  }

  Future<void> _sendPreset(DynamicAlertPreset preset) async {
    if (_isSending) return;
    setState(() => _isSending = true);

    Get.back<void>();
    AppAlert.notification(
      title: 'profile.alert_scheduled_title'.tr,
      message: 'profile.alert_sent_toast'.tr,
    );

    try {
      final syncService = DynamicNotificationSyncService.instance;
      if (syncService != null) {
        await syncService.triggerDynamicScenario(
          preset,
          delay: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendCustom() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final subText = _subTextController.text.trim();
    if (title.isEmpty) return;

    if (_isSending) return;
    setState(() => _isSending = true);

    Get.back<void>();
    AppAlert.notification(
      title: 'profile.alert_scheduled_title'.tr,
      message: 'profile.alert_sent_toast'.tr,
    );

    try {
      final syncService = DynamicNotificationSyncService.instance;
      if (syncService != null) {
        await syncService.triggerCustomDynamicAlert(
          title: title,
          body: message,
          subText: subText.isNotEmpty ? subText : null,
          delay: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'profile.dynamic_notification_title'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'profile.dynamic_notification_desc'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _presetTile(
                context,
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFF2E8BFF),
                title: 'profile.alert_community_comment'.tr,
                subtitle: 'Kun Kaknika · "How cute 🫣🫶"',
                badge: 'c.zen_03',
                onTap: () => _sendPreset(DynamicAlertPreset.communityComment),
              ),
              const SizedBox(height: 10),

              _presetTile(
                context,
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFFF3B5C),
                title: 'profile.alert_community_like'.tr,
                subtitle: 'Sophea Chan liked your healthy recipe',
                badge: 'sophea.healthy',
                onTap: () => _sendPreset(DynamicAlertPreset.communityLike),
              ),
              const SizedBox(height: 10),

              _presetTile(
                context,
                icon: Icons.restaurant_rounded,
                iconColor: const Color(0xFF00A651),
                title: 'profile.alert_meal_reminder'.tr,
                subtitle: 'Time for Lunch! 🥗 Keep your streak going',
                badge: 'NhamHealth Nutrition',
                onTap: () => _sendPreset(DynamicAlertPreset.mealReminder),
              ),
              const SizedBox(height: 10),

              _presetTile(
                context,
                icon: Icons.campaign_rounded,
                iconColor: const Color(0xFFFF9800),
                title: 'profile.alert_broadcast'.tr,
                subtitle: '📢 7-Day Clean Eating Challenge has begun!',
                badge: 'Broadcast',
                onTap: () => _sendPreset(DynamicAlertPreset.adminBroadcast),
              ),
              const SizedBox(height: 14),

              InkWell(
                onTap:
                    () =>
                        setState(() => _isCustomExpanded = !_isCustomExpanded),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 20,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'profile.alert_custom'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isCustomExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),

              if (_isCustomExpanded) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Notification Title',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _messageController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notification Body / Message',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _subTextController,
                  decoration: InputDecoration(
                    labelText: 'Subtext / Tag (Optional)',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _sendCustom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text(
                      'Send Real-Time Alert (3s Delay)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceContainer.withValues(
              alpha: isDark ? 0.5 : 0.7,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
