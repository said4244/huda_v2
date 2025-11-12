import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/data/models/page_model.dart';

void main() {
  group('Exercise Intro Data Model Tests', () {
    test('PageModel should use fixed background color', () {
      final page1 = PageModel.blank();
      final page2 = PageModel.withRandomColor();
      
      expect(page1.backgroundColor, equals(const Color(0xFFF2EFEB)));
      expect(page2.backgroundColor, equals(const Color(0xFFF2EFEB)));
      expect(page1.randomPlaceholder, equals(false));
      expect(page2.randomPlaceholder, equals(false));
    });

    test('PageModel should handle exerciseIntro data', () {
      final exerciseData = {
        'header1': 'Hello',
        'header2': 'World',
        'transliteration': 'Marhaba',
        'videoName': 'intro.mp4',
        'videoTrigger': 'onStart',
        'allowUserVideoControl': true,
        'autoPlay': false,
        'showMicrophone': true,
        'microphonePrompt': 'Say hello',
        'showContinueButton': true,
        'showRightArrow': false,
        'sendMessages': [
          {'type': 'avatarMessage', 'content': 'Hello!', 'delaySeconds': 2.0}
        ],
      };

      final page = PageModel(
        id: 'test',
        backgroundColor: const Color(0xFFF2EFEB),
        exerciseType: 'exerciseIntro',
        exerciseData: exerciseData,
      );

      expect(page.exerciseType, equals('exerciseIntro'));
      expect(page.exerciseData!['header1'], equals('Hello'));
      expect(page.exerciseData!['videoName'], equals('intro.mp4'));
      expect(page.exerciseData!['showMicrophone'], equals(true));
    });

    test('PageModel JSON serialization should work with exerciseIntro', () {
      final exerciseData = {
        'header1': 'Test Header',
        'videoName': 'test.mp4',
        'showMicrophone': false,
      };

      final page = PageModel(
        id: 'test',
        backgroundColor: const Color(0xFFF2EFEB),
        exerciseType: 'exerciseIntro',
        exerciseData: exerciseData,
      );

      final json = page.toJson();
      final reconstructed = PageModel.fromJson(json);

      expect(reconstructed.exerciseType, equals('exerciseIntro'));
      expect(reconstructed.exerciseData!['header1'], equals('Test Header'));
      expect(reconstructed.exerciseData!['videoName'], equals('test.mp4'));
      expect(reconstructed.exerciseData!['showMicrophone'], equals(false));
      expect(reconstructed.backgroundColor, equals(const Color(0xFFF2EFEB)));
    });

    test('PageModel should maintain backward compatibility', () {
      // Test legacy page creation
      final legacyPage = PageModel.blank();
      expect(legacyPage.exerciseType, isNull);
      expect(legacyPage.exerciseData, isNull);
      expect(legacyPage.backgroundColor, equals(const Color(0xFFF2EFEB)));
      
      // Test legacy page from JSON (simulating existing data)
      final legacyJson = {
        'id': 'legacy',
        'backgroundColor': 0xFF58CC02, // Old green color
        'randomPlaceholder': true,
        'exerciseType': null,
        'exerciseData': null,
        'title': null,
        'content': null,
      };
      
      final reconstructedLegacy = PageModel.fromJson(legacyJson);
      expect(reconstructedLegacy.exerciseType, isNull);
      expect(reconstructedLegacy.randomPlaceholder, equals(true));
      expect(reconstructedLegacy.backgroundColor.value, equals(0xFF58CC02));
    });

    test('Exercise data should support all required fields', () {
      final completeExerciseData = {
        'header1': 'Welcome',
        'header2': 'Get started with your lesson',
        'transliteration': 'Ahlan wa sahlan',
        'videoName': 'welcome_video.mp4',
        'videoTrigger': 'afterAvatarX',
        'allowUserVideoControl': true,
        'autoPlay': false,
        'showMicrophone': true,
        'microphonePrompt': 'Repeat after me: Welcome',
        'showContinueButton': true,
        'showRightArrow': true,
        'sendMessages': [
          {
            'type': 'avatarMessage',
            'content': 'Welcome to the lesson!',
            'delaySeconds': 3.0
          },
          {
            'type': 'video',
            'content': 'intro_animation.mp4',
            'delaySeconds': 1.0
          }
        ],
      };

      final page = PageModel(
        id: 'complete_test',
        backgroundColor: const Color(0xFFF2EFEB),
        exerciseType: 'exerciseIntro',
        exerciseData: completeExerciseData,
      );

      // Test all fields are preserved
      expect(page.exerciseData!['header1'], equals('Welcome'));
      expect(page.exerciseData!['header2'], equals('Get started with your lesson'));
      expect(page.exerciseData!['transliteration'], equals('Ahlan wa sahlan'));
      expect(page.exerciseData!['videoName'], equals('welcome_video.mp4'));
      expect(page.exerciseData!['videoTrigger'], equals('afterAvatarX'));
      expect(page.exerciseData!['allowUserVideoControl'], equals(true));
      expect(page.exerciseData!['autoPlay'], equals(false));
      expect(page.exerciseData!['showMicrophone'], equals(true));
      expect(page.exerciseData!['microphonePrompt'], equals('Repeat after me: Welcome'));
      expect(page.exerciseData!['showContinueButton'], equals(true));
      expect(page.exerciseData!['showRightArrow'], equals(true));
      
      // Test sendMessages structure
      final sendMessages = page.exerciseData!['sendMessages'] as List<dynamic>;
      expect(sendMessages.length, equals(2));
      expect(sendMessages[0]['type'], equals('avatarMessage'));
      expect(sendMessages[0]['content'], equals('Welcome to the lesson!'));
      expect(sendMessages[0]['delaySeconds'], equals(3.0));
      expect(sendMessages[1]['type'], equals('video'));
      expect(sendMessages[1]['content'], equals('intro_animation.mp4'));
      expect(sendMessages[1]['delaySeconds'], equals(1.0));
    });
  });
}
