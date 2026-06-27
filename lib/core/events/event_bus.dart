import 'dart:async';

class EventBus {
  final StreamController<dynamic> _streamController =
      StreamController<dynamic>.broadcast();

  Stream<T> on<T>() {
    if (T == dynamic) {
      return _streamController.stream as Stream<T>;
    }
    return _streamController.stream.where((event) => event is T).cast<T>();
  }

  void fire(dynamic event) {
    _streamController.add(event);
  }

  void dispose() {
    _streamController.close();
  }
}
