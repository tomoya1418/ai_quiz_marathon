import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

/// クイズデータを管理するためのクラス（データモデル）
class QuizModel {
  final String category;
  final String questionType;
  final String question;
  final String correctAnswer;
  final List<String> choices;

  QuizModel({
    required this.category,
    required this.questionType,
    required this.question,
    required this.correctAnswer,
    required this.choices,
  });

  /// JSONからDartのオブジェクトに変換するファクトリメソッド
  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      category: json['category'] as String,
      questionType: json['question_type'] as String,
      question: json['question'] as String,
      correctAnswer: json['correct_answer'] as String,
      choices: List<String>.from(json['choices'] as List),
    );
  }
}

class AiService {
  // ※ 取得した実際のGemini APIキーをここに貼り付けてください。
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// お題と難易度を受け取り、10問のクイズを生成して返す関数
  Future<List<QuizModel>> generateAIQuizzes({
    required String theme,
    required String difficulty,
  }) async {
    // 1. 使用するモデルの指定（軽量・高速な gemini-2.5-flash を推奨）
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      // 2. バージョン互換性に基づき `generationConfig` を指定
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.array(
          description: '10個のクイズオブジェクトのリスト',
          items: Schema.object(
            properties: {
              'category': Schema.string(description: 'お題や教科の名前'),
              'question_type': Schema.string(description: '常に "multiple_choice" 固定'),
              'question': Schema.string(description: '40文字以内の簡潔な問題文'),
              'correct_answer': Schema.string(description: '正解の文字列（choicesのいずれかと完全一致させること）'),
              'choices': Schema.array(
                description: '正解1つとダミー3つを含む、重複のない合計4つの選択肢',
                items: Schema.string(),
              ),
            },
            requiredProperties: ['category', 'question_type', 'question', 'correct_answer', 'choices'],
          ),
        ),
      ),
    );

    // 3. AIへの命令文（プロンプト）の作成
    final prompt = '''
あなたはプロのクイズクリエイターです。
ユーザーから指定された「お題」と「難易度」に基づいて、楽しく学べる4択クイズを【必ずちょうど10問】作成してください。

【設定条件】
お題: $theme
難易度: $difficulty (簡単: 小学校低学年レベル / 普通: 小学校高学年レベル / 難しい: 中学生〜大人レベル)

【注意事項】
・問題文は直感的でわかりやすく記述すること。
・選択肢の文字列はすべて重複しないようにすること。
・選択肢配列(choices)の中に、必ず正解(correct_answer)と「文字が完全一致する」要素を1つだけ含めること。
''';

    try {
      // 4. API通信の実行
      final response = await model.generateContent([Content.text(prompt)]);
      final jsonText = response.text;

      if (jsonText == null) {
        throw Exception('AIからの応答が空でした。');
      }

      // 5. 届いたJSONを解析してオブジェクトのリストに変換
      final List<dynamic> decodedList = jsonDecode(jsonText);
      return decodedList.map((item) => QuizModel.fromJson(item)).toList();

    } catch (e) {
      print('Gemini APIエラー: $e');
      rethrow; // エラーを上位（画面側）に受け渡してダイアログを表示させる
    }
  }
}