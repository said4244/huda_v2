// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InputState _$InputStateFromJson(Map<String, dynamic> json) => InputState(
      expectedInput: json['expectedInput'] as String,
      currentInput: json['currentInput'] as String,
      characterStates: (json['characterStates'] as List<dynamic>)
          .map((e) => CharacterState.fromJson(e as Map<String, dynamic>))
          .toList(),
      isComplete: json['isComplete'] as bool,
      cursorPosition: (json['cursorPosition'] as num).toInt(),
    );

Map<String, dynamic> _$InputStateToJson(InputState instance) =>
    <String, dynamic>{
      'expectedInput': instance.expectedInput,
      'currentInput': instance.currentInput,
      'characterStates': instance.characterStates,
      'isComplete': instance.isComplete,
      'cursorPosition': instance.cursorPosition,
    };

CharacterState _$CharacterStateFromJson(Map<String, dynamic> json) =>
    CharacterState(
      index: (json['index'] as num).toInt(),
      character: json['character'] as String,
      status: $enumDecode(_$CharacterStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$CharacterStateToJson(CharacterState instance) =>
    <String, dynamic>{
      'index': instance.index,
      'character': instance.character,
      'status': _$CharacterStatusEnumMap[instance.status]!,
    };

const _$CharacterStatusEnumMap = {
  CharacterStatus.pending: 'pending',
  CharacterStatus.correct: 'correct',
  CharacterStatus.incorrect: 'incorrect',
};
