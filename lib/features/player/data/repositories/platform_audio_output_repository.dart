import '../../domain/entities/audio_output.dart';
import '../../domain/repositories/audio_output_repository.dart';
import '../datasources/audio_output_source.dart';

class PlatformAudioOutputRepository implements AudioOutputRepository {
  PlatformAudioOutputRepository(this._source);

  final AudioOutputSource _source;

  @override
  @override
  Stream<void> watchChanges() => _source.changes;

  @override
  Future<AudioOutput?> current() async {
    final m = await _source.current();
    if (m == null) return null;
    final kind = switch (m['type']) {
      'speaker' => AudioOutputKind.speaker,
      'wired' => AudioOutputKind.wired,
      'bluetooth' => AudioOutputKind.bluetooth,
      'usb' => AudioOutputKind.usb,
      _ => AudioOutputKind.other,
    };
    return AudioOutput(kind: kind, name: m['name'] ?? '');
  }
}
