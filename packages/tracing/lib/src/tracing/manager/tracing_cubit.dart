import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:svg_path_parser/svg_path_parser.dart';
import 'package:tracing_game/src/tracing/model/letter_paths_model.dart';
import 'package:tracing_game/src/tracing/model/trace_model.dart';
import 'package:tracing_game/tracing_game.dart';

import '../../get_shape_helper/enum_of_arabic_and_numbers_letters.dart';

part 'tracing_state.dart';

class TracingCubit extends Cubit<TracingState> {
  TracingCubit({
    List<TraceWordModel>? traceWordModels,
    List<TraceGeoMetricShapeModel>? traceGeoMetricShapeModel,
    List<TraceCharsModel>? traceShapeModel,
    required StateOfTracing stateOfTracing,
  }) : super(TracingState(
          numberOfScreens: stateOfTracing == StateOfTracing.chars
              ? traceShapeModel!.length
              : stateOfTracing == StateOfTracing.traceShapes
                  ? traceGeoMetricShapeModel!.length
                  : stateOfTracing == StateOfTracing.traceWords
                      ? traceWordModels!.length
                      : 0,
          traceWordModels: traceWordModels,
          traceGeoMetricShapes: traceGeoMetricShapeModel,
          traceShapeModel: traceShapeModel,
          index: 0,
          stateOfTracing: stateOfTracing,
          traceLetter: const [],
          letterPathsModels: const [],
        )) {
    updateTheTraceLetter();
  }
  updateIndex() {
    int index = state.index;
    index++;
    if (index < state.numberOfScreens) {
      emit(state.copyWith(index: index, drawingStates: DrawingStates.loaded));
      updateTheTraceLetter();
    }
  }

  updateTheTraceLetter() async {
    emit(state.clearData());
    emit(state.copyWith(
        activeIndex: 0,
        stateOfTracing: state.stateOfTracing,
        traceLetter: TypeExtensionTracking().getTracingData(
            geometryShapes: state.stateOfTracing == StateOfTracing.traceShapes &&  state.traceGeoMetricShapes!.isNotEmpty
                ? state.traceGeoMetricShapes![state.index].shapes
                : null,
            chars: state.stateOfTracing == StateOfTracing.chars &&  state.traceShapeModel!.isNotEmpty
                ? state.traceShapeModel![state.index].chars
                : null,
                word:state.stateOfTracing == StateOfTracing.traceWords &&  state.traceWordModels!.isNotEmpty
                ? state.traceWordModels![state.index]
                : null ,
            currentOfTracking: state.stateOfTracing)));
    await loadAssets();
  }

  final viewSize = const Size(200, 200);
  Future<void> loadAssets() async {
    emit(state.copyWith(drawingStates: DrawingStates.loading));

    List<LetterPathsModel> model = [];
    for (var e in state.traceLetter) {
      final letterModel = e;
      final parsedPath = parseSvgPath(letterModel.letterPath);

      final dottedIndexPath = parseSvgPath(letterModel.indexPath);
      final dottedPath = parseSvgPath(letterModel.dottedPath);

      final transformedPath = _applyTransformation(
        parsedPath,
        viewSize,
      );

      final dottedPathTransformed = _applyTransformationForOtherPathsDotted(
          dottedPath,
          viewSize,
          letterModel.positionDottedPath,
          letterModel.scaledottedPath);
      final indexPathTransformed = _applyTransformationForOtherPathsIndex(
          dottedIndexPath,
          viewSize,
          letterModel.positionIndexPath,
          letterModel.scaleIndexPath);

      final allStrokePoints = await _loadPointsFromJson(
        letterModel.pointsJsonFile,
        viewSize,
      );
      final anchorPos =
          allStrokePoints.isNotEmpty ? allStrokePoints[0][0] : Offset.zero;

      model.add(LetterPathsModel(
          isSpace: letterModel.isSpace,
          viewSize: letterModel.letterViewSize,
          disableDivededStrokes: letterModel.disableDividedStrokes,
          strokeIndex: letterModel.strokeIndex,
          strokeWidth: letterModel.strokeWidth,
          dottedIndex: dottedPathTransformed,
          letterIndex: indexPathTransformed,
          dottedColor: letterModel.dottedColor,
          indexColor: letterModel.indexColor,
          innerPaintColor: letterModel.innerPaintColor,
          outerPaintColor: letterModel.outerPaintColor,
          allStrokePoints: allStrokePoints,
          letterImage: transformedPath,
          anchorPos: anchorPos,
          distanceToCheck: letterModel.distanceToCheck,
          indexPathPaintStyle: letterModel.indexPathPaintStyle,
          dottedPathPaintStyle: letterModel.dottedPathPaintStyle));
    }

    emit(state.copyWith(
      letterPathsModels: model,
      drawingStates: DrawingStates.loaded,
    ));
  }

  Path _applyTransformation(
    Path path,
    Size viewSize,
  ) {
    // Get the bounds of the original path
    final Rect originalBounds = path.getBounds();
    final Size originalSize = Size(originalBounds.width, originalBounds.height);

    // Calculate the scale factor to fit the SVG within the view size
    final double scaleX = viewSize.width / originalSize.width;
    final double scaleY = viewSize.height / originalSize.height;
    double scale = math.min(scaleX, scaleY);
    // Calculate the translation needed to center the path within the view size
    final double translateX =
        (viewSize.width - originalSize.width * scale) / 2 -
            originalBounds.left * scale;
    final double translateY =
        (viewSize.height - originalSize.height * scale) / 2 -
            originalBounds.top * scale;

    // Create a matrix for the transformation

    Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(translateX, translateY);

    // Apply the transformation to the path
    return path.transform(matrix.storage);
  }

  Path _applyTransformationForOtherPathsIndex(
      Path path, Size viewSize, Size? size, double? pathscale) {
    final Rect originalBounds = path.getBounds();
    final Size originalSize = Size(originalBounds.width, originalBounds.height);

    // Calculate the scale factor to fit the SVG within the view size
    final double scaleX = viewSize.width / originalSize.width;
    final double scaleY = viewSize.height / originalSize.height;

    double scale = math.min(scaleX, scaleY);
    scale = pathscale == null ? scale : scale * pathscale;

    // Calculate the translation needed to center the path within the view size
    final double translateX =
        (viewSize.width - originalSize.width * scale) / 2 -
            originalBounds.left * scale;
    final double translateY =
        (viewSize.height - originalSize.height * scale) / 2 -
            originalBounds.top * scale;

    // Create a matrix for the transformation

    Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(translateX, translateY);

    if (size != null) {
      matrix = Matrix4.identity()
        ..scale(scale, scale)
        ..translate(translateX + size.width, translateY + size.height);
    }
    // Apply the transformation to the path
    return path.transform(matrix.storage);
  }

  Path _applyTransformationForOtherPathsDotted(
      Path path, Size viewSize, Size? size, double? pathscale) {
    // Get the bounds of the original path
    final Rect originalBounds = path.getBounds();
    final Size originalSize = Size(originalBounds.width, originalBounds.height);

    // Calculate the scale factor to fit the SVG within the view size
    final double scaleX = viewSize.width / originalSize.width;
    final double scaleY = viewSize.height / originalSize.height;
    double scale = math.min(scaleX, scaleY);
    scale = pathscale == null ? scale : scale * pathscale;

    // Calculate the translation needed to center the path within the view size
    final double translateX =
        (viewSize.width - originalSize.width * scale) / 2 -
            originalBounds.left * scale;
    final double translateY =
        (viewSize.height - originalSize.height * scale) / 2 -
            originalBounds.top * scale;

    // Create a matrix for the transformation

    Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(translateX, translateY);

    if (size != null) {
      matrix = Matrix4.identity()
        ..scale(scale, scale)
        ..translate(translateX + size.width, translateY + size.height);
    }
    // Apply the transformation to the path
    return path.transform(matrix.storage);
  }

  Future<List<List<Offset>>> _loadPointsFromJson(
      String path, Size viewSize) async {
    final jsonString = await rootBundle.loadString('packages/tracing_game/$path');

    final jsonData = jsonDecode(jsonString);
    final List<List<Offset>> strokePointsList = [];

    for (var stroke in jsonData['strokes']) {
      final List<dynamic> strokePointsData = stroke['points'];
      final points = strokePointsData.map<Offset>((pointString) {
        final coords =
            pointString.split(',').map((e) => double.parse(e)).toList();
        return Offset(coords[0] * viewSize.width, coords[1] * viewSize.height);
      }).toList();
      strokePointsList.add(points);
    }

    return strokePointsList;
  }

  void handlePanStart(Offset position) {
    if (!isTracingStartPoint(position)) {
      return;
    }
emit(state.copyWith(drawingStates: DrawingStates.tracing));
    final currentStrokePoints =
        state.letterPathsModels[state.activeIndex].allStrokePoints[
            state.letterPathsModels[state.activeIndex].currentStroke];

    if (state.letterPathsModels[state.activeIndex].currentStrokeProgress >= 0 &&
        state.letterPathsModels[state.activeIndex].currentStrokeProgress <
            currentStrokePoints.length) {
      if (currentStrokePoints.length == 1) {
        final singlePoint = currentStrokePoints[0];
        if (isValidPoint(singlePoint, position,
            state.letterPathsModels[state.activeIndex].distanceToCheck)) {
          final newDrawingPath = Path()
            ..moveTo(singlePoint.dx, singlePoint.dy)
            ..lineTo(
                currentStrokePoints.first.dx, currentStrokePoints.first.dy);

          state.letterPathsModels[state.activeIndex].anchorPos = singlePoint;
          state.letterPathsModels[state.activeIndex].currentDrawingPath =
              newDrawingPath;

          completeStroke();
          return;
        }
      }
    } else if (state
            .letterPathsModels[state.activeIndex].currentStrokeProgress ==
        -1) {
      final currentStrokePoints =
          state.letterPathsModels[state.activeIndex].allStrokePoints[
              state.letterPathsModels[state.activeIndex].currentStroke];

      if (currentStrokePoints.length == 1) {
        final singlePoint = currentStrokePoints[0];
        if (isValidPoint(singlePoint, position,
            state.letterPathsModels[state.activeIndex].distanceToCheck)) {
          final newDrawingPath = Path()..moveTo(singlePoint.dx, singlePoint.dy);
          state.letterPathsModels[state.activeIndex].currentDrawingPath =
              newDrawingPath..lineTo(singlePoint.dx, singlePoint.dy);
          state.letterPathsModels[state.activeIndex].currentStrokeProgress = 1;
          completeStroke();
        } else {}
      } else {
        if (state.letterPathsModels[state.activeIndex].anchorPos != null) {
          final newDrawingPath = Path()
            ..moveTo(state.letterPathsModels[state.activeIndex].anchorPos!.dx,
                state.letterPathsModels[state.activeIndex].anchorPos!.dy);

          state.letterPathsModels[state.activeIndex].currentDrawingPath =
              newDrawingPath;
          state.letterPathsModels[state.activeIndex].currentStrokeProgress = 1;
          emit(state.copyWith(
            letterPathsModels: state.letterPathsModels,
          ));
        } 
      }
    }
  }

  void handlePanUpdate(Offset position) {
    final currentStrokePoints =
        state.letterPathsModels[state.activeIndex].allStrokePoints[
            state.letterPathsModels[state.activeIndex].currentStroke];

    if (state.letterPathsModels[state.activeIndex].currentStrokeProgress >= 0 &&
        state.letterPathsModels[state.activeIndex].currentStrokeProgress <
            currentStrokePoints.length) {
      if (currentStrokePoints.length == 1) {
        final singlePoint = currentStrokePoints[0];
        if (isValidPoint(singlePoint, position,
            state.letterPathsModels[state.activeIndex].distanceToCheck)) {
          final newDrawingPath = state
              .letterPathsModels[state.activeIndex].currentDrawingPath
            ..lineTo(
                currentStrokePoints.first.dx, currentStrokePoints.first.dy);

          state.letterPathsModels[state.activeIndex].anchorPos = singlePoint;
          state.letterPathsModels[state.activeIndex].currentDrawingPath =
              newDrawingPath;

          completeStroke();
          return;
        } else {}
      } else {
        if (isValidPoint(
            currentStrokePoints[state
                .letterPathsModels[state.activeIndex].currentStrokeProgress],
            position,
            state.letterPathsModels[state.activeIndex].distanceToCheck)) {
          state.letterPathsModels[state.activeIndex].currentStrokeProgress =
              state.letterPathsModels[state.activeIndex].currentStrokeProgress +
                  1;

          final point = currentStrokePoints[
              state.letterPathsModels[state.activeIndex].currentStrokeProgress -
                  1];

          final newDrawingPath = state
              .letterPathsModels[state.activeIndex].currentDrawingPath
            ..lineTo(point.dx, point.dy);

          state.letterPathsModels[state.activeIndex].anchorPos = point;
          state.letterPathsModels[state.activeIndex].currentDrawingPath =
              newDrawingPath;

          emit(state.copyWith(letterPathsModels: state.letterPathsModels));
        } else {}
      }
    }

    if (state.letterPathsModels[state.activeIndex].currentStrokeProgress >=
        currentStrokePoints.length) {
      completeStroke();
    }
  }

  void completeStroke() {
    final currentModel = state.letterPathsModels[state.activeIndex];
    final currentStrokeIndex = currentModel.currentStroke;

    if (currentStrokeIndex < currentModel.allStrokePoints.length - 1) {
      currentModel.paths.add(currentModel.currentDrawingPath);

      currentModel.currentStroke = currentStrokeIndex + 1;
      currentModel.currentStrokeProgress = 0;

      final previousStrokePoints =
          currentModel.allStrokePoints[currentStrokeIndex];
      final endPointOfPreviousStroke = previousStrokePoints.isNotEmpty
          ? currentModel
              .allStrokePoints[currentModel.disableDivededStrokes != null &&
                      currentModel.disableDivededStrokes!
                  ? currentStrokeIndex + 1
                  : currentStrokeIndex]
              .first
          : Offset.zero;

      final newDrawingPath = Path()
        ..moveTo(endPointOfPreviousStroke.dx, endPointOfPreviousStroke.dy);
      currentModel.currentDrawingPath = newDrawingPath;
      currentModel.anchorPos =
          currentModel.allStrokePoints[currentModel.currentStroke].first;
      emit(state.copyWith(letterPathsModels: state.letterPathsModels));
    } else if (!currentModel.letterTracingFinished) {
      currentModel.letterTracingFinished = true;
      currentModel.hasFinishedOneStroke = true;
      if (state.activeIndex < state.letterPathsModels.length - 1) {
        emit(state.copyWith(
          activeIndex: (state.activeIndex + 1),
          letterPathsModels: state.letterPathsModels,
        ));
      } else if (state.index == state.numberOfScreens-1 ) {
    
        emit(state.copyWith(
            activeIndex: (state.activeIndex),
            letterPathsModels: state.letterPathsModels,
            drawingStates: DrawingStates.gameFinished));
      } else {
        emit(state.copyWith(
            activeIndex: (state.activeIndex),
            letterPathsModels: state.letterPathsModels,
            drawingStates: DrawingStates.finishedCurrentScreen));
      }
    }
  }

  bool isTracingStartPoint(Offset position) {
    final currentStrokePoints =
        state.letterPathsModels[state.activeIndex].allStrokePoints[
            state.letterPathsModels[state.activeIndex].currentStroke];

    if (currentStrokePoints.length == 1) {
      return true;
    } else if (state.letterPathsModels[state.activeIndex].anchorPos != null) {
      final anchorRect = Rect.fromCenter(
          center: state.letterPathsModels[state.activeIndex].anchorPos!,
          width: 50,
          height: 50);
      bool contains = anchorRect.contains(position);
      return contains;
    }
    return false;
  }

  bool isValidPoint(Offset point, Offset position, double? distanceToCheck) {
    final validArea = distanceToCheck ?? 30.0;
    bool isValid = (position - point).distance < validArea;
    return isValid;
  }
}
