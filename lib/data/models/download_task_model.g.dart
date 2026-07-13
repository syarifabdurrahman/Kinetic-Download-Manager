import 'package:hive/hive.dart';
import 'download_task_model.dart';

class DownloadTaskModelAdapter extends TypeAdapter<DownloadTaskModel> {
  @override
  final int typeId = 0;

  @override
  DownloadTaskModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadTaskModel(
      id: fields[0] as String,
      url: fields[1] as String,
      fileName: fields[2] as String,
      totalBytes: fields[3] as int,
      downloadedBytes: fields[4] as int,
      status: fields[5] as String,
      chunksCount: fields[6] as int,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadTaskModel obj) {
    writer.writeByte(8);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.url);
    writer.writeByte(2);
    writer.write(obj.fileName);
    writer.writeByte(3);
    writer.write(obj.totalBytes);
    writer.writeByte(4);
    writer.write(obj.downloadedBytes);
    writer.writeByte(5);
    writer.write(obj.status);
    writer.writeByte(6);
    writer.write(obj.chunksCount);
    writer.writeByte(7);
    writer.write(obj.createdAt);
  }
}
