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
final tagsProvider = StateProvider<List<String>>((ref) => []);

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
  bool _showEditor = false;
  bool _isLoading = false;
  late PostMode _mode;

  @override
  void initState() {
    super.initState();

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
        setState(() => _showEditor = true);
      } else if (_mode == PostMode.editDraft && widget.draftData != null) {
        _loadPostData(widget.draftData!);
        setState(() => _showEditor = true);
      } else if (widget.type != null) {
        ref.read(postTypeProvider.notifier).state = widget.type!;
      }
    });
  }

  void _loadPostData(Map<String, dynamic> data) {
    ref.read(titleProvider.notifier).state = data['title'] ?? '';
    ref.read(descriptionProvider.notifier).state = data['description'] ?? '';
    ref.read(postTypeProvider.notifier).state = data['workType'] ?? 'Poetry';

    if (data['tags'] != null) {
      ref.read(tagsProvider.notifier).state = List<String>.from(data['tags']);
    }

    if (data['richText'] != null && data['richText'].isNotEmpty) {
      try {
        // Parse the richText safely
        dynamic richTextData;
        if (data['richText'] is String) {
          richTextData = jsonDecode(data['richText']);
        } else {
          richTextData = data['richText'];
        }

        if (richTextData is List) {
          final delta = Delta.fromJson(richTextData);
          final controller = ref.read(quillControllerProvider);
          controller.document = Document.fromDelta(delta);
          debugPrint('✅ Rich text loaded successfully');
        } else {
          debugPrint('⚠️ Rich text is not in the expected format');
          _loadPlainTextAsFallback(data);
        }
      } catch (e) {
        debugPrint('❌ Error loading rich text: $e');
        _loadPlainTextAsFallback(data);
      }
    } else if (data['plainText'] != null && data['plainText'].isNotEmpty) {
      _loadPlainTextAsFallback(data);
    }
  }

  void _loadPlainTextAsFallback(Map<String, dynamic> data) {
    try {
      final plainText = data['plainText'] ?? '';
      if (plainText.isNotEmpty) {
        final controller = ref.read(quillControllerProvider);
        controller.document = Document()..insert(0, plainText);
        debugPrint('ℹ️ Loaded plain text as fallback');
      }
    } catch (e) {
      debugPrint('❌ Error loading plain text: $e');
    }
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
    return _showEditor ? _buildEditorView() : _buildDetailsView();
  }

  // Step 1: Post Details
  Widget _buildDetailsView() {
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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 48 : 20,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPostTypeSelector(theme),
              const SizedBox(height: 32),
              _buildTitleInput(theme),
              const SizedBox(height: 24),
              _buildDescriptionInput(theme),
              const SizedBox(height: 24),
              _buildTagsSection(theme),
              const SizedBox(height: 48),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _validateAndContinue,
                  icon: const Icon(Icons.edit_note_rounded, size: 24),
                  label: const Text(
                    'Continue to Editor',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Fill in the details above to start writing',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 2: Full Page Editor
  Widget _buildEditorView() {
    final theme = Theme.of(context);
    final controller = ref.watch(quillControllerProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _showEditor = false);
          },
          tooltip: 'Back to details',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ref.watch(titleProvider),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              ref.watch(postTypeProvider),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          // Draft button
          if (_mode != PostMode.editPost)
            TextButton.icon(
              onPressed: _isLoading ? null : () => _savePost('draft'),
              icon: const Icon(Icons.save_outlined, size: 20),
              label: const Text('Draft'),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
            ),
          const SizedBox(width: 8),
          // Publish/Update button
          FilledButton.icon(
            onPressed: _isLoading ? null : () => _savePost('publish'),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _mode == PostMode.editPost ? Icons.check : Icons.publish,
                    size: 20,
                  ),
            label: Text(_mode == PostMode.editPost ? 'Update' : 'Publish'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Fixed Toolbar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
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
                showDividers: true,
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
                toolbarSize: 40,
              ),
            ),
          ),

          // Scrollable Editor
          Expanded(
            child: QuillEditor.basic(
              controller: controller,
              config: QuillEditorConfig(
                padding: const EdgeInsets.all(24),
                placeholder: _getPlaceholder(ref.watch(postTypeProvider)),
                scrollable: true,
                autoFocus: true,
                expands: true,
                customStyles: DefaultStyles(
                  placeHolder: DefaultTextBlockStyle(
                    theme.textTheme.bodyLarge!.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      height: 1.8,
                      fontSize: 17,
                    ),
                    const HorizontalSpacing(0, 0),
                    const VerticalSpacing(8, 0),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                  paragraph: DefaultTextBlockStyle(
                    TextStyle(
                      fontSize: 17,
                      color: theme.colorScheme.onSurface,
                      height: 1.8,
                    ),
                    const HorizontalSpacing(0, 0),
                    const VerticalSpacing(8, 0),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                ),
              ),
            ),
          ),

          // Word count footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final text = controller.document.toPlainText();
                final wordCount = text
                    .trim()
                    .split(RegExp(r'\s+'))
                    .where((word) => word.isNotEmpty)
                    .length;
                final charCount = text.length;
                final selectedType = ref.watch(postTypeProvider);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$wordCount words  •  $charCount characters',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedType == 'Microfiction')
                      Row(
                        children: [
                          Icon(
                            wordCount <= 55
                                ? Icons.check_circle
                                : Icons.warning,
                            size: 16,
                            color: wordCount <= 55
                                ? Colors.green
                                : theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            wordCount <= 55
                                ? 'Perfect length'
                                : '${wordCount - 55} words over',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: wordCount <= 55
                                  ? Colors.green
                                  : theme.colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTypeSelector(ThemeData theme) {
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
          'What are you creating?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: postTypes.map((type) {
            final isSelected = selectedType == type;

            return FilterChip(
              label: Text(
                type,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(postTypeProvider.notifier).state = type;
                }
              },
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              selectedColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide.none,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Title',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Required',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: TextEditingController(text: ref.watch(titleProvider))
            ..selection = TextSelection.collapsed(
              offset: ref.watch(titleProvider).length,
            ),
          onChanged: (value) {
            ref.read(titleProvider.notifier).state = value;
          },
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Give your work a compelling title...',
            hintStyle: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(20),
            counterStyle: theme.textTheme.bodySmall,
          ),
          maxLength: 100,
        ),
      ],
    );
  }

  Widget _buildDescriptionInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Description',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optional)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
            hintText: 'Add a brief description or context...',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(20),
            counterStyle: theme.textTheme.bodySmall,
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
    final tags = ref.watch(tagsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optional)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _showTagDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: tags.isEmpty
                ? Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add tags to help people discover your work',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...tags.map(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(
                                tag,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                final updatedTags = List<String>.from(tags);
                                updatedTags.remove(tag);
                                ref.read(tagsProvider.notifier).state =
                                    updatedTags;
                              },
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        ActionChip(
                          label: const Text('Add more'),
                          avatar: const Icon(Icons.add, size: 16),
                          onPressed: _showTagDialog,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _getPlaceholder(String selectedType) {
    switch (selectedType) {
      case 'Poetry':
        return '✍️ Let your verses flow... Start writing your poem here. Express your emotions, paint with words, and let your creativity shine.';
      case 'Lyrics':
        return '🎵 Write your song... Add verses, chorus, bridge. Express your melody in words and create something unforgettable.';
      case 'Stories':
        return '📖 Once upon a time... Begin your story here. Take your readers on an unforgettable journey through your imagination.';
      case 'Quotes & Aphorisms':
        return '💭 Share your wisdom... Write your thoughts, quotes, or aphorisms here. Inspire others with your insights.';
      case 'Microfiction':
        return '⚡ Tell your micro story... (Maximum 55 words) Every word counts. Make them meaningful. Craft a complete narrative in just a few sentences.';
      default:
        return 'Start writing...';
    }
  }

  void _validateAndContinue() {
    final title = ref.read(titleProvider);

    if (title.trim().isEmpty) {
      _showSnackBar(context, 'Please add a title to continue', isError: true);
      return;
    }

    setState(() => _showEditor = true);
  }

  Future<void> _showTagDialog() async {
    final selectedTags = await showDialog<List<String>>(
      context: context,
      builder: (context) =>
          TagSelectionDialog(initialTags: ref.read(tagsProvider)),
    );

    if (selectedTags != null) {
      ref.read(tagsProvider.notifier).state = selectedTags;
    }
  }

  Future<void> _savePost(String action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final title = ref.read(titleProvider);
      final description = ref.read(descriptionProvider);
      final postType = ref.read(postTypeProvider);
      final tags = ref.read(tagsProvider);
      final controller = ref.read(quillControllerProvider);

      final plainTextContent = controller.document.toPlainText();

      // Safely encode rich text content
      String richTextContent;
      try {
        richTextContent = jsonEncode(controller.document.toDelta().toJson());
      } catch (e) {
        debugPrint('❌ Error encoding rich text: $e');
        // Fallback to plain text if encoding fails
        richTextContent = jsonEncode([
          {'insert': plainTextContent},
        ]);
      }

      // Validation for publish only
      if (action == 'publish') {
        if (title.trim().isEmpty) {
          _showSnackBar(
            context,
            '📝 Please add a title to your ${postType.toLowerCase()}',
            isError: true,
          );
          setState(() => _isLoading = false);
          return;
        }

        if (plainTextContent.trim().isEmpty) {
          _showSnackBar(
            context,
            '✍️ Your ${postType.toLowerCase()} needs some content before publishing',
            isError: true,
          );
          setState(() => _isLoading = false);
          return;
        }

        // Additional validation for Microfiction
        if (postType == 'Microfiction') {
          final wordCount = plainTextContent
              .trim()
              .split(RegExp(r'\s+'))
              .where((word) => word.isNotEmpty)
              .length;
          if (wordCount > 55) {
            _showSnackBar(
              context,
              '⚡ Microfiction must be 55 words or less. Your story has $wordCount words.',
              isError: true,
            );
            setState(() => _isLoading = false);
            return;
          }
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
        if (tags.isNotEmpty) 'tags': tags,
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
          _showSnackBar(context, '💾 Draft updated successfully!');
        } else {
          postData['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('drafts')
              .add(postData);
          _showSnackBar(context, '💾 Saved as draft!');
        }
      } else if (action == 'publish') {
        // Use batch for atomic operations
        final batch = FirebaseFirestore.instance.batch();

        if (_mode == PostMode.editPost) {
          // Update existing post
          final postRef = FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId);
          batch.update(postRef, postData);
          _showSnackBar(context, '✅ Post updated successfully!');
        } else {
          // Publish new post
          postData['createdAt'] =
              widget.postData?['createdAt'] ?? FieldValue.serverTimestamp();
          postData['likeCount'] = widget.postData?['likeCount'] ?? 0;
          postData['commentCount'] = widget.postData?['commentCount'] ?? 0;
          postData['shareCount'] = widget.postData?['shareCount'] ?? 0;
          postData['viewCount'] = widget.postData?['viewCount'] ?? 0;

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

          _showSnackBar(context, '🎉 Post published successfully!');
        }

        await batch.commit();
      }

      // Clear form and navigate back
      ref.read(titleProvider.notifier).state = '';
      ref.read(descriptionProvider.notifier).state = '';
      ref.read(tagsProvider.notifier).state = [];
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

// Tag Selection Dialog
class TagSelectionDialog extends StatefulWidget {
  final List<String> initialTags;

  const TagSelectionDialog({super.key, this.initialTags = const []});

  @override
  State<TagSelectionDialog> createState() => _TagSelectionDialogState();
}

class _TagSelectionDialogState extends State<TagSelectionDialog> {
  late List<String> _selectedTags;
  final TextEditingController _customTagController = TextEditingController();
  bool _isLoadingTags = true;
  List<String> _availableTags = [];

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
    _loadTags();
  }

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('tags')
          .get();

      if (doc.exists && doc.data()?['available_tags'] != null) {
        setState(() {
          _availableTags = List<String>.from(doc.data()!['available_tags']);
          _isLoadingTags = false;
        });
      } else {
        setState(() {
          _availableTags = [
            'Love',
            'Nature',
            'Life',
            'Emotions',
            'Inspiration',
            'Sadness',
            'Joy',
            'Hope',
            'Dreams',
            'Memories',
          ];
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      setState(() {
        _availableTags = ['Love', 'Nature', 'Life', 'Emotions', 'Inspiration'];
        _isLoadingTags = false;
      });
    }
  }

  Future<void> _addCustomTag() async {
    final tag = _customTagController.text.trim();
    if (tag.isEmpty) return;

    if (tag.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tag must be at least 2 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (tag.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tag must be less than 20 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_availableTags.contains(tag) || _selectedTags.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tag already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      _customTagController.clear();
      return;
    }

    setState(() {
      _selectedTags.add(tag);
      _availableTags.add(tag);
    });

    try {
      await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('tags')
          .set({
            'available_tags': FieldValue.arrayUnion([tag]),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving tag: $e');
    }

    _customTagController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: screenHeight * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tag,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Tags',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Help others discover your work',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected tags
                    if (_selectedTags.isNotEmpty) ...[
                      Text(
                        'Selected (${_selectedTags.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedTags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() => _selectedTags.remove(tag));
                            },
                            backgroundColor: theme.colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Add custom tag
                    Text(
                      'Create New Tag',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customTagController,
                            decoration: InputDecoration(
                              hintText: 'Enter tag name...',
                              prefixIcon: const Icon(Icons.add),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              counterText: '',
                            ),
                            maxLength: 20,
                            textCapitalization: TextCapitalization.words,
                            onSubmitted: (_) => _addCustomTag(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _addCustomTag,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Available tags
                    Text(
                      'Popular Tags',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _isLoadingTags
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableTags.map((tag) {
                              final isSelected = _selectedTags.contains(tag);
                              return FilterChip(
                                label: Text(tag),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTags.add(tag);
                                    } else {
                                      _selectedTags.remove(tag);
                                    }
                                  });
                                },
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                selectedColor:
                                    theme.colorScheme.primaryContainer,
                                checkmarkColor:
                                    theme.colorScheme.onPrimaryContainer,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, _selectedTags),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_selectedTags.isEmpty ? 'Skip' : 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _selectedTags),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        _selectedTags.isEmpty
                            ? 'Continue without tags'
                            : 'Done (${_selectedTags.length})',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
