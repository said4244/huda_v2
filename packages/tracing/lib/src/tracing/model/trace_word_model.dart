
import 'package:tracing_game/src/tracing/model/trace_shape_options.dart';
import 'package:tracing_game/tracing_game.dart';


class TraceWordModel {
final  String word;
 final TraceShapeOptions traceShapeOptions;
  TraceWordModel({
   required this.word,
    this.traceShapeOptions= const TraceShapeOptions(),
  });
}
