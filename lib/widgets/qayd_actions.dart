// ==============================================================================
// Shared Qayd & Folder Management Actions (Dialogs & Bottom Sheets)
// File: lib/widgets/qayd_actions.dart
//
// Centralizes Rename, Edit Transcript, Move to Folder, Delete Qayd, and
// Folder Rename/Delete interactions so HomeScreen and DetailScreen behave
// identically without duplicating dialog code.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/folder_model.dart';
import '../data/models/qayd_model.dart';
import '../providers/qayd_provider.dart';

/// Shows a bottom sheet listing all file-management actions for a [qayd].
Future<void> showQaydCardActionsSheet(
  BuildContext context,
  Qayd qayd,
) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final theme = Theme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        qayd.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(isArabic ? 'إعادة تسمية' : 'Rename'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (context.mounted) {
                    showRenameQaydDialog(context, qayd);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(isArabic ? 'نقل إلى مجلد' : 'Move to Folder'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (context.mounted) {
                    showMoveToFolderDialog(context, qayd);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.notes),
                title: Text(isArabic ? 'تعديل النص' : 'Edit Transcript'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (context.mounted) {
                    showEditTranscriptDialog(context, qayd);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: theme.colorScheme.error),
                title: Text(
                  isArabic ? 'حذف' : 'Delete',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (context.mounted) {
                    showDeleteQaydDialog(context, qayd);
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows a dialog to rename a lecture [qayd].
Future<void> showRenameQaydDialog(BuildContext context, Qayd qayd) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return showDialog<void>(
    context: context,
    builder: (ctx) => _SingleInputDialog(
      title: isArabic ? 'إعادة تسمية المحاضرة' : 'Rename Lecture',
      labelText: isArabic ? 'العنوان' : 'Title',
      initialValue: qayd.title,
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      confirmText: isArabic ? 'حفظ' : 'Save',
      onConfirm: (value) {
        context.read<QaydProvider>().renameQayd(qayd.id, value);
      },
    ),
  );
}

/// Shows a keyboard-safe scrollable dialog to edit the full transcript of [qayd].
Future<void> showEditTranscriptDialog(BuildContext context, Qayd qayd) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EditTranscriptDialog(qayd: qayd),
  );
}

/// Shows a dialog to assign [qayd] to a folder or move it back to Unfiled.
Future<void> showMoveToFolderDialog(BuildContext context, Qayd qayd) {
  final provider = context.read<QaydProvider>();
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final folders = ctx.watch<QaydProvider>().folders;
      return AlertDialog(
        title: Text(isArabic ? 'نقل إلى مجلد' : 'Move to Folder'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.inbox),
                title: Text(isArabic ? 'بدون مجلد (عام)' : 'Unfiled'),
                selected: qayd.folderId == null,
                onTap: () {
                  provider.moveQaydToFolder(qayd.id, null);
                  Navigator.pop(ctx);
                },
              ),
              ...folders.map(
                (f) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(f.name),
                  selected: qayd.folderId == f.id,
                  onTap: () {
                    provider.moveQaydToFolder(qayd.id, f.id);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              showCreateFolderDialog(ctx);
            },
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: Text(isArabic ? 'مجلد جديد' : 'New Folder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
        ],
      );
    },
  );
}

/// Shows a confirmation dialog and deletes [qayd].
///
/// Optional [beforeDelete] runs after closing the dialog and before deleting
/// storage data (useful for stopping audio playback on DetailScreen).
/// Optional [onDeleted] runs after deletion finishes.
Future<void> showDeleteQaydDialog(
  BuildContext context,
  Qayd qayd, {
  Future<void> Function()? beforeDelete,
  VoidCallback? onDeleted,
}) {
  final provider = context.read<QaydProvider>();
  final theme = Theme.of(context);
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isArabic ? 'حذف المحاضرة؟' : 'Delete Qayd?'),
      content: Text(
        isArabic
            ? 'هل أنت متأكد من حذف هذه المحاضرة وجميع ملفاتها نهائياً؟'
            : 'Are you sure you want to delete this Qayd and its local audio file permanently?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            await beforeDelete?.call();
            await provider.deleteQayd(qayd.id);
            onDeleted?.call();
          },
          child: Text(isArabic ? 'حذف' : 'Delete'),
        ),
      ],
    ),
  );
}

/// Shows a dialog to create a new course/subject folder.
Future<void> showCreateFolderDialog(BuildContext context) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return showDialog<void>(
    context: context,
    builder: (ctx) => _SingleInputDialog(
      title: isArabic ? 'إنشاء مجلد جديد' : 'New Course Folder',
      labelText: isArabic ? 'اسم المادة أو المقرر' : 'Course / Subject Name',
      hintText:
          isArabic ? 'مثال: الذكاء الاصطناعي' : 'e.g. Artificial Intelligence',
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      confirmText: isArabic ? 'إنشاء' : 'Create',
      onConfirm: (value) {
        context.read<QaydProvider>().createFolder(value);
      },
    ),
  );
}

/// Shows Rename / Delete actions for a [folder].
Future<void> showFolderActionsSheet(BuildContext context, QaydFolder folder) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final theme = Theme.of(context);

  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(isArabic ? 'إعادة تسمية المجلد' : 'Rename Folder'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (context.mounted) {
                    showRenameFolderDialog(context, folder);
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: theme.colorScheme.error),
                title: Text(
                  isArabic ? 'حذف المجلد' : 'Delete Folder',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  if (context.mounted) {
                    showDeleteFolderDialog(context, folder);
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows a dialog to rename an existing [folder].
Future<void> showRenameFolderDialog(BuildContext context, QaydFolder folder) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return showDialog<void>(
    context: context,
    builder: (ctx) => _SingleInputDialog(
      title: isArabic ? 'إعادة تسمية المجلد' : 'Rename Folder',
      labelText: isArabic ? 'اسم المجلد' : 'Folder Name',
      initialValue: folder.name,
      cancelText: isArabic ? 'إلغاء' : 'Cancel',
      confirmText: isArabic ? 'حفظ' : 'Save',
      onConfirm: (value) {
        context.read<QaydProvider>().renameFolder(folder.id, value);
      },
    ),
  );
}

/// Confirms deleting [folder]; its lectures remain intact as Unfiled.
Future<void> showDeleteFolderDialog(BuildContext context, QaydFolder folder) {
  final provider = context.read<QaydProvider>();
  final theme = Theme.of(context);
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isArabic ? 'حذف المجلد؟' : 'Delete Folder?'),
      content: Text(
        isArabic
            ? 'سيتم حذف المجلد "${folder.name}" فقط مع بقاء المحاضرات بداخله ضمن "جميع القيود".'
            : 'Delete folder "${folder.name}"? Lectures inside will stay safe under All Qayds.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            await provider.deleteFolder(folder.id);
          },
          child: Text(isArabic ? 'حذف' : 'Delete'),
        ),
      ],
    ),
  );
}

class _SingleInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String? hintText;
  final String initialValue;
  final String cancelText;
  final String confirmText;
  final void Function(String value) onConfirm;

  const _SingleInputDialog({
    required this.title,
    required this.labelText,
    required this.cancelText,
    required this.confirmText,
    required this.onConfirm,
    this.hintText,
    this.initialValue = '',
  });

  @override
  State<_SingleInputDialog> createState() => _SingleInputDialogState();
}

class _SingleInputDialogState extends State<_SingleInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty) {
      widget.onConfirm(trimmed);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelText),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}

class _EditTranscriptDialog extends StatefulWidget {
  final Qayd qayd;

  const _EditTranscriptDialog({required this.qayd});

  @override
  State<_EditTranscriptDialog> createState() => _EditTranscriptDialogState();
}

class _EditTranscriptDialogState extends State<_EditTranscriptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.qayd.transcript);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(isArabic ? 'تعديل النص المفرغ' : 'Edit Transcript'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.qayd.segments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'ملاحظة: حفظ تعديل النص الكامل يزيل الطوابع الزمنية. للحفاظ عليها، اضغط أيقونة التعديل بجانب كل مقطع.'
                      : 'Note: Saving the full transcript removes per-line timestamps. To keep timestamps, edit individual segments in the Transcript tab.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        FilledButton(
          onPressed: () {
            context
                .read<QaydProvider>()
                .editTranscript(widget.qayd.id, _controller.text);
            Navigator.pop(context);
          },
          child: Text(isArabic ? 'حفظ' : 'Save'),
        ),
      ],
    );
  }
}
