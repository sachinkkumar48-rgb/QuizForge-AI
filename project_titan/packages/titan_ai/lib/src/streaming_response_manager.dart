import 'dart:async';

/// Represents current state of a streaming AI response.
enum StreamingState {
  idle,
  connecting,
  streaming,
  completed,
  error,
}

/// Event model representing stream updates emitted by [StreamingResponseManager].
class StreamChunkEvent {
  final String delta;
  final String fullText;
  final StreamingState state;
  final Object? error;

  const StreamChunkEvent({
    required this.delta,
    required this.fullText,
    required this.state,
    this.error,
  });

  bool get isCompleted => state == StreamingState.completed;
  bool get hasError => state == StreamingState.error;
}

/// Pure Dart manager for controlling, parsing, and buffering streaming AI completions.
class StreamingResponseManager {
  final StringBuffer _buffer = StringBuffer();
  final StreamController<StreamChunkEvent> _controller =
      StreamController<StreamChunkEvent>.broadcast();
  StreamingState _state = StreamingState.idle;
  StreamSubscription<String>? _rawSubscription;

  /// Current accumulated text content.
  String get currentText => _buffer.toString();

  /// Current streaming state.
  StreamingState get state => _state;

  /// Broadcast stream of chunk events.
  Stream<StreamChunkEvent> get stream => _controller.stream;

  /// Connects to a raw text stream source and handles aggregation & state events.
  Stream<StreamChunkEvent> processStream(Stream<String> rawStream) {
    _reset();
    _state = StreamingState.connecting;
    _emitEvent(delta: '');

    _rawSubscription = rawStream.listen(
      (chunk) {
        if (_state == StreamingState.connecting) {
          _state = StreamingState.streaming;
        }
        _buffer.write(chunk);
        _emitEvent(delta: chunk);
      },
      onError: (Object err) {
        _state = StreamingState.error;
        _emitEvent(delta: '', error: err);
        _controller.close();
      },
      onDone: () {
        if (_state != StreamingState.error) {
          _state = StreamingState.completed;
          _emitEvent(delta: '');
        }
        _controller.close();
      },
      cancelOnError: true,
    );

    return stream;
  }

  /// Cancels any active raw stream processing.
  Future<void> cancel() async {
    await _rawSubscription?.cancel();
    _rawSubscription = null;
    if (_state == StreamingState.streaming ||
        _state == StreamingState.connecting) {
      _state = StreamingState.idle;
      _emitEvent(delta: '');
    }
  }

  void _emitEvent({required String delta, Object? error}) {
    if (!_controller.isClosed) {
      _controller.add(StreamChunkEvent(
        delta: delta,
        fullText: currentText,
        state: _state,
        error: error,
      ));
    }
  }

  void _reset() {
    _rawSubscription?.cancel();
    _rawSubscription = null;
    _buffer.clear();
    _state = StreamingState.idle;
  }

  /// Closes internal controllers.
  Future<void> close() async {
    await cancel();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
