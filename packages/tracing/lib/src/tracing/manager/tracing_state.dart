part of 'tracing_cubit.dart';

enum DrawingStates {
  error,
  initial,
  loading,
  loaded,
    tracing,

  gameFinished,
  finishedCurrentScreen
}

// ignore: must_be_immutable
class TracingState extends Equatable {
  final List<TraceCharsModel>? traceShapeModel;
  final List<TraceWordModel>? traceWordModels;
  final List<TraceGeoMetricShapeModel>? traceGeoMetricShapes;

  final List<TraceModel> traceLetter;
  final DrawingStates drawingStates;
  List<LetterPathsModel> letterPathsModels;
  final int activeIndex; // Track the active letter index
  final int index;
  final Size viewSize;
  final StateOfTracing stateOfTracing;

  final int numberOfScreens;

  TracingState({
    required this.stateOfTracing,
    this.numberOfScreens = 0,
    this.traceWordModels,
    this.traceGeoMetricShapes,
    this.traceShapeModel,
    this.viewSize = const Size(0, 0),
    this.letterPathsModels = const [],
    required this.traceLetter,
    this.drawingStates = DrawingStates.initial,
    required this.index,
    this.activeIndex = 0,
  });

  TracingState copyWith({
    int? numberOfScreens,
    List<TraceWordModel>? traceWordModels,
    List<TraceGeoMetricShapeModel>? traceGeoMetricShapes,
    List<TraceCharsModel>? traceShapeModel,
    Size? viewSize,
    DrawingStates? drawingStates,
    int? index,
    // Updated to ui.Image
    List<LetterPathsModel>? letterPathsModels,
    List<TraceModel>? traceLetter,
    StateOfTracing? stateOfTracing,
    int? activeIndex,
  }) {
    return TracingState(
      numberOfScreens: numberOfScreens ?? this.numberOfScreens,
      traceGeoMetricShapes: traceGeoMetricShapes ?? this.traceGeoMetricShapes,
      traceWordModels: traceWordModels ?? this.traceWordModels,
      traceShapeModel: traceShapeModel ?? this.traceShapeModel,
      index: index ?? this.index,
      stateOfTracing: stateOfTracing ?? this.stateOfTracing,
      letterPathsModels: letterPathsModels ?? this.letterPathsModels,
      traceLetter: traceLetter ?? this.traceLetter,
      activeIndex: activeIndex ?? this.activeIndex,
      drawingStates: drawingStates ?? this.drawingStates,
    );
  }

  TracingState clearData() {
    return TracingState(
      numberOfScreens: numberOfScreens,
      traceGeoMetricShapes: traceGeoMetricShapes,
      traceShapeModel: traceShapeModel,
      traceWordModels: traceWordModels,
      letterPathsModels: letterPathsModels,
      drawingStates: DrawingStates.initial,
      stateOfTracing: stateOfTracing,
      index: index,
      traceLetter: traceLetter,
    );
  }

  @override
  List<Object?> get props => [
        traceWordModels,
        traceShapeModel,
        drawingStates,
        viewSize,
        stateOfTracing,
        index,
        traceLetter,
        letterPathsModels.map((model) => model.copyWith()).toList(),
        activeIndex
      ];
}
