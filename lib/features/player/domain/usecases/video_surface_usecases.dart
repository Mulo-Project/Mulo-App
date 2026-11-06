import '../../../../core/usecase/usecase.dart';
import '../entities/video_surface_info.dart';
import '../repositories/video_surface.dart';

class AttachVideoSurface implements UseCase<VideoSurfaceInfo?, NoParams> {
  const AttachVideoSurface(this._surface);
  final VideoSurface _surface;

  @override
  Future<VideoSurfaceInfo?> call(NoParams params) => _surface.attach();
}

class DetachVideoSurface implements UseCase<void, NoParams> {
  const DetachVideoSurface(this._surface);
  final VideoSurface _surface;

  @override
  Future<void> call(NoParams params) => _surface.detach();
}

class WatchVideoSurface implements StreamUseCase<VideoSurfaceEvent, NoParams> {
  const WatchVideoSurface(this._surface);
  final VideoSurface _surface;

  @override
  Stream<VideoSurfaceEvent> call(NoParams params) => _surface.watch();
}
