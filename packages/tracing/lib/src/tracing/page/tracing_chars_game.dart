
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracing_game/src/tracing/phonetics_paint_widget/phonetics_painter.dart';
import 'package:tracing_game/tracing_game.dart';


class TracingCharsGame extends StatefulWidget {
  const TracingCharsGame({super.key, required this.traceShapeModel,
    this.loadingIndictor=const CircularProgressIndicator(), 
        this.showAnchor=true,
          this.onTracingUpdated,
          this.onGameFinished,
          this.onCurrentTracingScreenFinished,
   });
  final List<TraceCharsModel> traceShapeModel;
  final Widget loadingIndictor;
    final bool showAnchor;


final Future<void> Function(int index)? onTracingUpdated;
final  Future<void> Function(int index)? onGameFinished;
 final  Future<void> Function(int index)? onCurrentTracingScreenFinished;

  @override
  State<StatefulWidget> createState() => _TracingCharsGameState();
}

class _TracingCharsGameState extends State<TracingCharsGame> {
  late TracingCubit tracingCubit;

  @override
  void initState() {
    super.initState();
    tracingCubit = TracingCubit(
      stateOfTracing:StateOfTracing.chars ,
      traceShapeModel: widget.traceShapeModel,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Adjust bottom padding based on platform and navigation bar presence
    return BlocProvider(
        create: (context) => tracingCubit,
        child: BlocConsumer<TracingCubit, TracingState>(
            listener:(context, stateOfGame)async {
    if (stateOfGame.drawingStates == DrawingStates.tracing) {
          if (widget.onTracingUpdated != null) {
            await widget.onTracingUpdated!(stateOfGame.activeIndex);
          }
        } else if (stateOfGame.drawingStates ==
            DrawingStates.finishedCurrentScreen) {
          if (widget.onCurrentTracingScreenFinished != null) {
            await widget.onCurrentTracingScreenFinished!(stateOfGame.index + 1);
          }
          if (context.mounted) {
            tracingCubit.updateIndex();
          }
        } else if (stateOfGame.drawingStates == DrawingStates.gameFinished) {
          if (widget.onGameFinished != null) {
            await widget.onGameFinished!(stateOfGame.index);
          }
        }
            }, builder: (context, state) {
                  if(widget.traceShapeModel.isEmpty){
              return const SizedBox();
            }
          if (state.drawingStates == DrawingStates.loading ||
              state.drawingStates == DrawingStates.initial) {
            return widget. loadingIndictor;
          }

      
          return  Center(
              child: FittedBox(
          
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      // mainAxisAlignment: MainAxisAlignment.s,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        state.letterPathsModels.length,
                        (index) {
                          return SizedBox(
                            height:
                                state.letterPathsModels[index].viewSize.width,
                            width: state
                                .letterPathsModels[index].viewSize.height,
                        
                            // color: Colors.green,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: GestureDetector(
                                onPanStart: (details) {
                                  if (index == state.activeIndex) {
                                    tracingCubit.handlePanStart(
                                        details.localPosition);
                                  }
                                },
                                onPanUpdate: (details) {
                                  if (index == state.activeIndex) {
                                    tracingCubit.handlePanUpdate(
                                        details.localPosition);
                                  }
                                },
                                onPanEnd: (details) {},
                                child: Stack(
                                  // fit: StackFit.loose,
                                  clipBehavior: Clip.none,
                                  // alignment: Alignment.b,
                                  children: [
                                    CustomPaint(
                                      // isComplex: true,
                                      size: tracingCubit.viewSize,
              
                                      painter: PhoneticsPainter(
                                        strokeIndex: state
                                            .letterPathsModels[index]
                                            .strokeIndex,
                                        indexPath: state
                                            .letterPathsModels[index]
                                            .letterIndex,
                                        dottedPath: state
                                            .letterPathsModels[index]
                                            .dottedIndex,
                                        letterColor: state
                                            .letterPathsModels[index]
                                            .outerPaintColor,
                                        letterImage: state
                                            .letterPathsModels[index]
                                            .letterImage!,
                                        paths: state
                                            .letterPathsModels[index].paths,
                                        currentDrawingPath: state
                                            .letterPathsModels[index]
                                            .currentDrawingPath,
                                        pathPoints: state
                                            .letterPathsModels[index]
                                            .allStrokePoints
                                            .expand((p) => p)
                                            .toList(),
                                        strokeColor: state
                                            .letterPathsModels[index]
                                            .innerPaintColor,
                                        viewSize: state
                                            .letterPathsModels[index]
                                            .viewSize,
                                        strokePoints: state
                                                .letterPathsModels[index]
                                                .allStrokePoints[
                                            state.letterPathsModels[index]
                                                .currentStroke],
                                        strokeWidth: state
                                            .letterPathsModels[index]
                                            .strokeWidth,
                                        dottedColor: state
                                            .letterPathsModels[index]
                                            .dottedColor,
                                        indexColor: state
                                            .letterPathsModels[index]
                                            .indexColor,
                                        indexPathPaintStyle: state
                                            .letterPathsModels[index]
                                            .indexPathPaintStyle,
                                        dottedPathPaintStyle: state
                                            .letterPathsModels[index]
                                            .dottedPathPaintStyle,
                                      ),
                                    ),
                                    if (state.activeIndex == index && widget.showAnchor)
                                      Positioned(
                                        top: state
                                            .letterPathsModels[
                                                state.activeIndex]
                                            .anchorPos!
                                            .dy,
                                        left: state
                                            .letterPathsModels[
                                                state.activeIndex]
                                            .anchorPos!
                                            .dx,
                                        child: Image.asset(
                                          'packages/tracing_game/assets/images/position_2_finger.png',
                                          height: 50,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            
            
          );
        }));
  }
}
