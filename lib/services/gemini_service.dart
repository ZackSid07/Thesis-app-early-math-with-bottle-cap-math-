import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
    );
  }

  /// Generates a simple math equation (e.g., '4 + 3 = ?') given a level and topic.
  Future<String> generateEquation(String difficultyLevel, String topic) async {
    final prompt = '''
You are a friendly, encouraging math teacher for 5 to 8-year-olds. The user will provide a difficulty level (e.g., 'Single-Digit') and a topic (e.g., 'Addition'). Generate exactly ONE simple math equation matching these criteria in the format 'Number Operator Number = ?' (e.g., '4 + 3 = ?'). Do not include any other text.

Difficulty Level: $difficultyLevel
Topic: $topic
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ?? "Error generating equation";
    } catch (e) {
      print("Gemini API Error (Generate Equation): $e");
      return "2 + 2 = ?";
    }
  }

  /// Explains why the child's answer is incorrect using fun, simple concepts.
  Future<String> explainMistake(
      String childsEquation, String correctEquation) async {
    final prompt = '''
You are a gentle, encouraging math tutor for young children. The child attempted a math problem but got it wrong. The child wrote: $childsEquation. The correct equation is: $correctEquation. Explain why their answer is incorrect using simple, fun concepts like counting apples, blocks, or toys. Keep the explanation under 3 short sentences. End with an encouraging remark.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ?? "Oops, let's try again! You can do it!";
    } catch (e) {
      print("Gemini API Error (Explain Mistake): $e");
      return "Let's look closely at the math puzzle and try to find the right number!";
    }
  }

  /// Generates a creative hint story explaining the math using apples, without answering.
  Future<String> generateHintStory(
      int num1, String operator, int num2) async {
    final prompt = '''
You are a kindergarten teacher giving a hint for the math problem $num1 $operator $num2. CRITICAL: DO NOT REVEAL THE FINAL ANSWER. Write a short, creative 2-sentence story using apples. If '+', talk about getting more apples. If '-', talk about taking apples away. End the story by asking the child to try counting them! Use very basic words, ellipses (...) for TTS pauses, and exclamation points (!).
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ??
          "Let's count all the apples to find the answer!";
    } catch (e) {
      debugPrint("GEMINI API FATAL ERROR: $e");
      return "Let's count all the apples to find the answer!";
    }
  }

  /// Generates a creative story explaining the math using apples and reveals the answer explicitly.
  Future<String> generateRevealedStory(
      int num1, String operator, int num2, int answer) async {
    final prompt = '''
You are a kindergarten teacher slowly demonstrating how $num1 $operator $num2 equals $answer using apples. CRITICAL INSTRUCTION: You MUST explicitly count the apples out loud in your text. Use ellipses (...) between EVERY number to force the robot voice to pause. Example format for addition: 'First we have 1... 2... apples! Then we add 1... 2... 3... more! Let's count them all together! 1... 2... 3... 4... 5! The answer is 5!' Example for subtraction: 'We start with 1... 2... 3... apples! Then we take away 1... apple! Let's see what is left... 1... 2! The answer is 2!' Keep it strictly to this pacing.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ??
          "Let's count the apples together to find the answer! It is $answer!";
    } catch (e) {
      debugPrint("GEMINI API FATAL ERROR: $e");
      return "Let's count the apples together to find the answer! It is $answer!";
    }
  }
}
