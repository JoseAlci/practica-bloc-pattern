import "package:rxdart/rxdart.dart";
import "package:meta/meta.dart";

import "transition.dart";
import "bloc_supervisor.dart";

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

  void onTransition(Transition<Evento, Estado> transition) => null;

  void onError(Object error, StackTrace stacktrace) => null;

  void onEvent(Evento event) => null;

  void dispactch(Evento evento) {
    try {
      BlocSupervisor.delegate.onEvent(this, evento);
      onEvent(evento);
      _eventSubject.sink.add(evento);
    } catch (error) {
      _handleError(error);
    }
  }

  Stream<Estado> transform(
    Stream<Evento> eventos,
    Stream<Estado> next(Evento evento),
  ) {
    return eventos.asyncExpand(next);
  }

  Stream<Estado> mapEventToState(Evento evento);

  void _bindStateSubject() {
    Evento currentEvent;

    transform(
      _eventSubject,
      (Evento evento) {
        currentEvent = evento;
        return mapEventToState(currentEvent).handleError(_handleError);
      },
    ).forEach((Estado nextState) {
      if (currentState == nextState || _stateSubject.isClosed) return;
      final transition = Transition(
        currentState: currentState,
        event: currentEvent,
        nextState: nextState,
      );
      BlocSupervisor.delegate.onTransition(this, transition);
      onTransition(transition);
      _stateSubject.sink.add(nextState);
    });
  }

  void _handleError(Object error, [StackTrace stacktrace]) {
    BlocSupervisor.delegate.onError(this, error, stacktrace);
    onError(error, stacktrace);
  }
}
