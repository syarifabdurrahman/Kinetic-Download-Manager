import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/download_local_datasource.dart';
import 'data/datasources/remote/background_download_service.dart';
import 'data/datasources/remote/download_engine.dart';
import 'data/models/download_task_model.g.dart';
import 'data/repositories/download_repository_impl.dart';
import 'domain/usecases/get_download_queue.dart';
import 'domain/usecases/pause_download.dart';
import 'domain/usecases/remove_download.dart';
import 'domain/usecases/resume_download.dart';
import 'presentation/blocs/download_bloc.dart';
import 'presentation/screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
    debugPrint('STACK: ${details.stack}');
  };

  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);
  Hive.registerAdapter(DownloadTaskModelAdapter());

  final localDatasource = DownloadLocalDatasource();
  try {
    await localDatasource.init();
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  final repository = DownloadRepositoryImpl(localDatasource);
  final engine = DownloadEngine();

  final bgService = BackgroundDownloadService();
  unawaited(
    bgService.initialize().then((_) => bgService.start()).catchError((e) {
      debugPrint('Background service error: $e');
    }),
  );

  runApp(KineticDownloadApp(repository: repository, engine: engine));
}

class KineticDownloadApp extends StatelessWidget {
  final DownloadRepositoryImpl repository;
  final DownloadEngine engine;

  const KineticDownloadApp({
    super.key,
    required this.repository,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KFDM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return BlocProvider(
          create: (_) => DownloadBloc(
            pauseDownload: PauseDownloadUseCase(repository),
            resumeDownload: ResumeDownloadUseCase(repository),
            getDownloadQueue: GetDownloadQueue(repository),
            removeDownload: RemoveDownloadUseCase(repository),
            engine: engine,
            repository: repository,
          ),
          child: child!,
        );
      },
      home: const MainShell(),
    );
  }
}
