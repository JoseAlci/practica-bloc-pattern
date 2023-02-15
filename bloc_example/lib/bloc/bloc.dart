import "package:rxdart/rxdart.dart";
import "package:meta/meta.dart";

abstract class Bloc<Evento, Estado> {
  final PublishSubject<Evento> _eventSubject = PublishSubject<Evento>();
  BehaviorSubject<Estado> _stateSubject;

  Estado get initialState;

  Estado get currentState => _stateSubject.value;

  Stream<Estado> get state => _stateSubject.stream;

  Bloc() {
    _stateSubject = BehaviorSubject<Estado>.seeded(initialState);
    _bindStateSubject();
  }

  @mustCallSuper
  void dispose() {
    _eventSubject.close();
    _stateSubject.close();
  }

  void onError(Object error, StackTrace stacktrace) => null;

  void onEvent(Evento event) => null;

  void dispactch(Evento evento) {
    try {
      onEvent(evento);
      _eventSubject.sink.add(evento);
    } catch (error) {
      _handleError(error);
    }
  }

  Stream<Estado> mapEventToState(Evento evento);

  void _bindStateSubject() {
    _eventSubject.asyncExpand(
      (Evento evento) {
        return mapEventToState(evento).handleError(_handleError);
      },
    ).forEach((Estado nextState) {
      if (currentState == nextState || _stateSubject.isClosed) return;
      _stateSubject.sink.add(nextState);
    });
  }

  void _handleError(Object error, [StackTrace stacktrace]) {
    onError(error, stacktrace);
  }
}
