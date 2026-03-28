import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
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

  /// Generates a creative story explaining the math using apples.
  Future<String> generateAppleExplanation(int num1, String operator, int num2) async {
    final prompt = '''
Write a 2-sentence creative story explaining how $num1 $operator $num2 equals the answer, using apples as the example. Keep it very simple for a 5-year-old.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ?? "Let's count the apples together to find the answer!";
    } catch (e) {
      print("Gemini API Error (Apple Explanation): $e");
      return "Let's count the apples together to find the answer!";
    }
  }
}
