import 'package:flutter/foundation.dart';

typedef LoadableTask<T> = Future<T> Function();

class LoadableController<T> extends ChangeNotifier {
  LoadableController({required LoadableTask<T> loader}) : _loader = loader;

  final LoadableTask<T> _loader;

  bool _isLoading = false;
  bool _hasAttemptedLoad = false;
  bool _isDisposed = false;
  Object? _error;
  T? _data;

  bool get isLoading => _isLoading;
  bool get hasAttemptedLoad => _hasAttemptedLoad;
  Object? get error => _error;
  T? get data => _data;

  Future<void> load({bool force = false}) async {
    if (_isLoading) {
      return;
    }
    if (_hasAttemptedLoad && !force) {
      return;
    }

    _hasAttemptedLoad = true;
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      _data = await _loader();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> refresh() {
    return load(force: true);
  }

  void replaceData(T data) {
    _data = data;
    _error = null;
    _hasAttemptedLoad = true;
    _notifySafely();
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
