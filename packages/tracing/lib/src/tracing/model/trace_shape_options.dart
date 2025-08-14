import 'package:flutter/material.dart';
import 'package:tracing_game/src/colors/phonetics_color.dart';

class TraceShapeOptions {
  final Color outerPaintColor;
  final Color innerPaintColor;
  final Color dottedColor;
  final Color indexColor;

 const TraceShapeOptions({
           this.dottedColor= AppColorPhonetics.grey,
           this.  indexColor= Colors.black,
            this. innerPaintColor= AppColorPhonetics.lightBlueColor6,
            this. outerPaintColor= AppColorPhonetics.lightBlueColor5
  });
}
