import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/download_status.dart';
import '../blocs/download_bloc.dart';
import '../blocs/download_event.dart';
import '../blocs/download_state.dart';
import '../widgets/download_card.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Completed',
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search completed files...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceContainerLow,
                ),
                style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<DownloadBloc, DownloadState>(
                builder: (context, state) {
                  if (state is DownloadLoaded) {
                    final completed = state.tasks
                        .where((t) => t.status == DownloadStatus.completed)
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    if (completed.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open_outlined, size: 48,
                                color: AppTheme.outline.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text('No completed downloads',
                                style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Completed files will appear here',
                                style: TextStyle(fontSize: 12, color: AppTheme.outline)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: completed.length + 1,
                      itemBuilder: (context, i) {
                        if (i == completed.length) return const SizedBox(height: 80);
                        final task = completed[i];
                        return DownloadCard(
                          task: task,
                          onRemove: () => context.read<DownloadBloc>()
                              .add(RemoveDownload(task.id)),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
