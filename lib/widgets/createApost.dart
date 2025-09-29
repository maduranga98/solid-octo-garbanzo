import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';

// Providers for managing form state
final titleProvider = StateProvider<String>((ref) => '');
final descriptionProvider = StateProvider<String>((ref) => '');
final postTypeProvider = StateProvider<String>((ref) => 'Poetry');

// Quill controller provider
final quillControllerProvider = StateProvider<QuillController>((ref) {
  return QuillController.basic();
});

enum PostMode { create, editPost, editDraft }

class Createapost extends ConsumerStatefulWidget {
  final String? type;
  final String? userID;
  final String? name;

  // For editing existing post
  final String? postId;
  final Map<String, dynamic>? postData;

  // For editing draft
  final String? draftId;
  final Map<String, dynamic>? draftData;

  const Createapost({
    super.key,
    this.type,
    this.userID,
    this.name,
    this.postId,
    this.postData,
    this.draftId,
    this.draftData,
  });

  @override
  ConsumerState<Createapost> createState() => _CreateapostState();
}

class _CreateapostState extends ConsumerState<Createapost> {
  late FocusNode _contentFocusNode;
  late ScrollController _scrollController;
  bool _isLoading = false;
  late PostMode _mode;

  @override
  void initState() {
    super.initState();
    _contentFocusNode = FocusNode();
    _scrollController = ScrollController();

    // Determine mode
    if (widget.postId != null && widget.postData != null) {
      _mode = PostMode.editPost;
    } else if (widget.draftId != null && widget.draftData != null) {
      _mode = PostMode.editDraft;
    } else {
      _mode = PostMode.create;
    }

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mode == PostMode.editPost && widget.postData != null) {
        _loadPostData(widget.postData!);
      } else if (_mode == PostMode.editDraft && widget.draftData != null) {
        _loadPostData(widget.draftData!);
      } else if (widget.type != null) {
        ref.read(postTypeProvider.notifier).state = widget.type!;
      }
    });
  }

  void _loadPostData(Map<String, dynamic> data) {
    ref.read(titleProvider.notifier).state = data['title'] ?? '';
    ref.read(descriptionProvider.notifier).state = data['description'] ?? '';
    ref.read(postTypeProvider.notifier).state = data['workType'] ?? 'Poetry';

    if (data['richText'] != null && data['richText'].isNotEmpty) {
      try {
        final delta = Delta.fromJson(jsonDecode(data['richText']) as List);
        final controller = ref.read(quillControllerProvider);
        controller.document = Document.fromDelta(delta);
      } catch (e) {
        debugPrint('Error loading rich text: $e');
      }
    }
  }

  @override
  void dispose() {
    _contentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _appBarTitle {
    switch (_mode) {
      case PostMode.editPost:
        return 'Edit Post';
      case PostMode.editDraft:
        return 'Edit Draft';
      case PostMode.create:
        return 'Create Post';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          _appBarTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostTypeSelector(context),
                    const SizedBox(height: 24),
                    _buildTitleInput(context),
                    const SizedBox(height: 20),
                    _buildDescriptionInput(context),
                    const SizedBox(height: 24),
                    _buildRichTextEditor(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildBottomActionBar(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Draft button (only show if not editing an existing post)
          if (_mode != PostMode.editPost) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _savePost('draft'),
                icon: const Icon(Icons.drafts, size: 18),
                label: const Text('Draft'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.orange.withValues(alpha: 0.5)),
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Publish/Update button
          Expanded(
            flex: _mode == PostMode.editPost ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _savePost('publish'),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _mode == PostMode.editPost ? Icons.update : Icons.publish,
                      size: 18,
                    ),
              label: Text(
                _isLoading
                    ? 'Saving...'
                    : _mode == PostMode.editPost
                    ? 'Update'
                    : 'Publish',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final selectedType = ref.watch(postTypeProvider);

    final postTypes = [
      'Poetry',
      'Lyrics',
      'Stories',
      'Quotes & Aphorisms',
      'Microfiction',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: postTypes.length,
            itemBuilder: (context, index) {
              final type = postTypes[index];
              final isSelected = selectedType == type;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    type,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(postTypeProvider.notifier).state = type;
                    }
                  },
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  selectedColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTitleInput(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: ref.watch(titleProvider))
            ..selection = TextSelection.collapsed(
              offset: ref.watch(titleProvider).length,
            ),
          onChanged: (value) {
            ref.read(titleProvider.notifier).state = value;
          },
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your title...',
            hintStyle: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          maxLength: 100,
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) {
                return Text(
                  '$currentLength/${maxLength ?? 0}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              },
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller:
              TextEditingController(text: ref.watch(descriptionProvider))
                ..selection = TextSelection.collapsed(
                  offset: ref.watch(descriptionProvider).length,
                ),
          onChanged: (value) {
            ref.read(descriptionProvider.notifier).state = value;
          },
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Add a brief description about your post...',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          maxLines: 2,
          maxLength: 200,
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) {
                return Text(
                  '$currentLength/${maxLength ?? 0}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              },
        ),
      ],
    );
  }

  Widget _buildRichTextEditor(BuildContext context) {
    final theme = Theme.of(context);
    final selectedType = ref.watch(postTypeProvider);
    final controller = ref.watch(quillControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Content',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedType,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: QuillSimpleToolbar(
                  controller: controller,
                  config: const QuillSimpleToolbarConfig(
                    multiRowsDisplay: false,
                    showDividers: false,
                    showFontFamily: false,
                    showFontSize: false,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: true,
                    showInlineCode: false,
                    showColorButton: true,
                    showBackgroundColorButton: true,
                    showListNumbers: true,
                    showListBullets: true,
                    showListCheck: false,
                    showCodeBlock: false,
                    showQuote: true,
                    showIndent: true,
                    showLink: false,
                    showUndo: true,
                    showRedo: true,
                    showDirection: false,
                    showSearchButton: false,
                    toolbarSize: 36,
                  ),
                ),
              ),
              SizedBox(
                height: 300,
                child: QuillEditor(
                  focusNode: _contentFocusNode,
                  scrollController: _scrollController,
                  controller: controller,
                  config: QuillEditorConfig(
                    padding: const EdgeInsets.all(20),
                    showCursor: true,
                    enableInteractiveSelection: true,
                    scrollable: true,
                    autoFocus: false,
                    expands: false,
                    placeholder: _getPlaceholder(selectedType),
                    customStyles: DefaultStyles(
                      placeHolder: DefaultTextBlockStyle(
                        theme.textTheme.bodyLarge!.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                          height: 1.6,
                        ),
                        const HorizontalSpacing(0, 0),
                        const VerticalSpacing(6, 0),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                      paragraph: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                          height: 1.6,
                        ),
                        const HorizontalSpacing(0, 0),
                        const VerticalSpacing(6, 0),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, child) {
            final controller = ref.watch(quillControllerProvider);
            final text = controller.document.toPlainText();
            final wordCount = text
                .trim()
                .split(RegExp(r'\s+'))
                .where((word) => word.isNotEmpty)
                .length;
            final charCount = text.length;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Words: $wordCount • Characters: $charCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (selectedType == 'Microfiction')
                  Text(
                    wordCount <= 55
                        ? '✓ Perfect length'
                        : 'Too long for microfiction',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: wordCount <= 55
                          ? Colors.green
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _getPlaceholder(String selectedType) {
    switch (selectedType) {
      case 'Poetry':
        return 'Write your poem here... Let your words flow like verses';
      case 'Lyrics':
        return 'Write your lyrics here... Add verses and chorus';
      case 'Stories':
        return 'Tell your story here... Once upon a time';
      case 'Quotes & Aphorisms':
        return 'Share your wisdom here...';
      case 'Microfiction':
        return 'Craft your micro story here (55 words or less)...';
      default:
        return 'Start writing your content here...';
    }
  }

  Future<void> _savePost(String action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final title = ref.read(titleProvider);
      final description = ref.read(descriptionProvider);
      final postType = ref.read(postTypeProvider);
      final controller = ref.read(quillControllerProvider);

      final plainTextContent = controller.document.toPlainText();
      final richTextContent = jsonEncode(
        controller.document.toDelta().toJson(),
      );

      // Validation for publish only
      if (action == 'publish') {
        if (title.trim().isEmpty) {
          _showSnackBar(context, 'Please add a title', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        if (plainTextContent.trim().isEmpty) {
          _showSnackBar(context, 'Please add some content', isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar(context, 'User not authenticated', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final postData = {
        'title': title,
        'description': description,
        'plainText': plainTextContent,
        'richText': richTextContent,
        'workType': postType,
        'createdBy': user.uid,
        'authorName': widget.name ?? user.displayName ?? 'Anonymous',
        'updatedAt': FieldValue.serverTimestamp(),
        'viewCount': 0,
        'shareCount': 0,
        'likeCount': 0,
        'commentCount': 0,
        'wordCount': plainTextContent
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .length,
        'characterCount': plainTextContent.length,
      };

      if (action == 'draft') {
        // Save/Update draft
        if (widget.draftId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('drafts')
              .doc(widget.draftId)
              .update(postData);
          _showSnackBar(context, 'Draft updated successfully!');
        } else {
          postData['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('drafts')
              .add(postData);
          _showSnackBar(context, 'Saved as draft!');
        }
      } else if (action == 'publish') {
        // Use batch for atomic operations
        final batch = FirebaseFirestore.instance.batch();

        if (_mode == PostMode.editPost) {
          // Update existing post - no postCount change
          final postRef = FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId);
          batch.update(postRef, postData);
          _showSnackBar(context, 'Post updated successfully!');
        } else {
          // Publish new post or draft
          postData['createdAt'] =
              widget.postData?['createdAt'] ?? FieldValue.serverTimestamp();
          postData['likeCount'] = widget.postData?['likeCount'] ?? 0;
          postData['commentCount'] = widget.postData?['commentCount'] ?? 0;
          postData['shareCount'] = widget.postData?['shareCount'] ?? 0;
          postData['viewCount'] = widget.postData?['viewCount'] ?? 0;

          // Add new post
          final postRef = FirebaseFirestore.instance.collection('posts').doc();
          batch.set(postRef, postData);

          // Increment user's postCount
          final userRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);
          batch.update(userRef, {'postCount': FieldValue.increment(1)});

          // Delete draft if publishing from draft
          if (widget.draftId != null) {
            final draftRef = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('drafts')
                .doc(widget.draftId);
            batch.delete(draftRef);
          }

          _showSnackBar(context, 'Post published successfully!');
        }

        // Commit all changes atomically
        await batch.commit();
      }

      // Clear form and navigate back
      ref.read(titleProvider.notifier).state = '';
      ref.read(descriptionProvider.notifier).state = '';
      controller.clear();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar(context, 'Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
