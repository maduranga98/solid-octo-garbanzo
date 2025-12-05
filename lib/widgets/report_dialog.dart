import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';
import '../repositories/user_repository.dart';
import '../providers/user_provider.dart';

class ReportDialog extends ConsumerStatefulWidget {
  final ReportType reportType;
  final String contentId;
  final String contentAuthorId;
  final String? contentTitle;
  final String? contentText;
  final String? contentAuthorName;
  final String? chatId;

  const ReportDialog({
    Key? key,
    required this.reportType,
    required this.contentId,
    required this.contentAuthorId,
    this.contentTitle,
    this.contentText,
    this.contentAuthorName,
    this.chatId,
  }) : super(key: key);

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ReportReason _selectedReason = ReportReason.inappropriateContent;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _getReportTypeTitle() {
    switch (widget.reportType) {
      case ReportType.post:
        return 'Report Post';
      case ReportType.comment:
        return 'Report Comment';
      case ReportType.profile:
        return 'Report Profile';
      case ReportType.message:
        return 'Report Message';
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final reportRepo = ref.read(reportRepositoryProvider);
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user data from Firestore
      final userRepo = ref.read(userRepositoryProvider);
      final currentUser = await userRepo.getUserData(firebaseUser.uid);

      if (currentUser == null) {
        throw Exception('User data not found');
      }

      switch (widget.reportType) {
        case ReportType.post:
          await reportRepo.reportPost(
            reportedBy: currentUser.uid,
            reporterEmail: currentUser.email,
            reporterName: '${currentUser.firstname} ${currentUser.lastname}',
            postId: widget.contentId,
            postTitle: widget.contentTitle ?? 'Untitled',
            postAuthor: widget.contentAuthorId,
            reason: _selectedReason,
            description: _descriptionController.text.trim(),
          );
          break;

        case ReportType.comment:
          await reportRepo.reportComment(
            reportedBy: currentUser.uid,
            reporterEmail: currentUser.email,
            reporterName: '${currentUser.firstname} ${currentUser.lastname}',
            postId: widget.chatId ?? '',
            commentId: widget.contentId,
            commentText: widget.contentText ?? '',
            commentAuthor: widget.contentAuthorId,
            reason: _selectedReason,
            description: _descriptionController.text.trim(),
          );
          break;

        case ReportType.profile:
          await reportRepo.reportProfile(
            reportedBy: currentUser.uid,
            reporterEmail: currentUser.email,
            reporterName: '${currentUser.firstname} ${currentUser.lastname}',
            profileId: widget.contentAuthorId,
            profileUsername: widget.contentAuthorName ?? '',
            reason: _selectedReason,
            description: _descriptionController.text.trim(),
          );
          break;

        case ReportType.message:
          await reportRepo.reportMessage(
            reportedBy: currentUser.uid,
            reporterEmail: currentUser.email,
            reporterName: '${currentUser.firstname} ${currentUser.lastname}',
            chatId: widget.chatId ?? '',
            messageId: widget.contentId,
            messageText: widget.contentText ?? '',
            messageAuthor: widget.contentAuthorId,
            reason: _selectedReason,
            description: _descriptionController.text.trim(),
          );
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Report submitted successfully. We will review this within 24 hours.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getReportTypeTitle()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please select a reason and provide details:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReportReason>(
                value: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: ReportReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(_getReasonText(reason)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedReason = value!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Please provide more details...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 500,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We will review your report and take action within 24 hours.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }

  String _getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.harassment:
        return 'Harassment or Bullying';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.violence:
        return 'Violence or Threats';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.childSafety:
        return 'Child Safety Concern';
      case ReportReason.sexualContent:
        return 'Sexual Content';
      case ReportReason.falseInformation:
        return 'False Information';
      case ReportReason.other:
        return 'Other';
    }
  }
}

// Helper function to show the report dialog
void showReportDialog(
  BuildContext context, {
  required ReportType reportType,
  required String contentId,
  required String contentAuthorId,
  String? contentTitle,
  String? contentText,
  String? contentAuthorName,
  String? chatId,
}) {
  showDialog(
    context: context,
    builder: (context) => ReportDialog(
      reportType: reportType,
      contentId: contentId,
      contentAuthorId: contentAuthorId,
      contentTitle: contentTitle,
      contentText: contentText,
      contentAuthorName: contentAuthorName,
      chatId: chatId,
    ),
  );
}
