import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_type_detector.dart';
import '../../domain/entities/download_status.dart';
import '../blocs/download_bloc.dart';
import '../blocs/download_state.dart';
import '../widgets/glass_card.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const _categories = ['All Files', 'Videos', 'Images', 'Docs', 'Audio', 'Archives'];
  static final _detector = FileTypeDetector();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('KFDM',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontSize: 24, letterSpacing: 1)),
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.person, color: AppTheme.onSurfaceVariant, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Library',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface)),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.filter_list, color: AppTheme.onSurfaceVariant, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 13)),
                      selected: cat == 'All Files',
                      selectedColor: AppTheme.primaryContainer,
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      labelStyle: TextStyle(
                        color: cat == 'All Files'
                            ? Colors.white : AppTheme.onSurfaceVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                      onSelected: (_) {},
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<DownloadBloc, DownloadState>(
                builder: (context, state) {
                  if (state is DownloadLoaded) {
                    final completed = state.tasks
                        .where((t) => t.status == DownloadStatus.completed)
                        .toList();
                    if (completed.isEmpty) {
                      return GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: const Center(
                          child: Text('No files downloaded yet',
                              style: TextStyle(color: AppTheme.onSurfaceVariant)),
                        ),
                      );
                    }
                    return Column(
                      children: completed.map((task) {
                        final category = _detector.categoryFromExtension(task.fileName);
                        final icon = _iconForCategory(category);
                        final color = _colorForCategory(category);
                        final label = _detector.getCategoryLabel(category);
                        final format = NumberFormat.compact();
                        return GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.fileName,
                                      style: const TextStyle(fontSize: 14,
                                          fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('$label • ${format.format(task.totalBytes)}B',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            const Icon(Icons.more_horiz, color: AppTheme.outline, size: 20),
                          ]),
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(FileCategory cat) {
    switch (cat) {
      case FileCategory.video: return Icons.play_circle_outline;
      case FileCategory.audio: return Icons.music_note_outlined;
      case FileCategory.image: return Icons.image_outlined;
      case FileCategory.document: return Icons.description_outlined;
      case FileCategory.archive: return Icons.folder_zip_outlined;
      case FileCategory.executable: return Icons.miscellaneous_services_outlined;
      case FileCategory.other: return Icons.insert_drive_file_outlined;
    }
  }

  Color _colorForCategory(FileCategory cat) {
    switch (cat) {
      case FileCategory.video: return AppTheme.primaryContainer;
      case FileCategory.audio: return const Color(0xFFce93d8);
      case FileCategory.image: return Colors.greenAccent;
      case FileCategory.document: return AppTheme.tertiary;
      case FileCategory.archive: return Colors.orangeAccent;
      case FileCategory.executable: return const Color(0xFF90caf9);
      case FileCategory.other: return AppTheme.onSurfaceVariant;
    }
  }
}
