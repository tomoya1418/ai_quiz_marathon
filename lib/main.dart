import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'services/ai_service.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIクイズマラソン',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const QuizTopScreen(),
    );
  }
}

// =================================================================
// 1. トップ画面（お題選択・難易度設定・計算マラソン入り口）
// =================================================================
class QuizTopScreen extends StatefulWidget {
  const QuizTopScreen({super.key});

  @override
  State<QuizTopScreen> createState() => _QuizTopScreenState();
}

class _QuizTopScreenState extends State<QuizTopScreen> {
  final _aiService = AiService();
  final _textController = TextEditingController();
  
  String _selectedTheme = '国語';
  String _selectedDifficulty = '普通';
  bool _isLoading = false;

  final List<String> _subjects = ['国語', '算数', '理科', '社会', '英語'];
  final List<String> _difficulties = ['簡単', '普通', '難しい'];

  // 🔥 【新規】APIを使わず、プログラムの乱数だけで計算クイズを10問自動生成する関数
  void _startMathMarathon() {
    final random = Random();
    List<QuizModel> mathQuizzes = [];

    for (int i = 0; i < 10; i++) {
      // 1〜50のランダムな数字を2つ生成
      int num1 = random.nextInt(50) + 1;
      int num2 = random.nextInt(50) + 1;
      
      // 足し算か引き算かをランダムで決定
      bool isAddition = random.nextBool();

      // 🔥【修正】引き算のときは、必ず num1 が大きくなるように入れ替える
      if (!isAddition && num1 < num2) {
        int temp = num1;
        num1 = num2;
        num2 = temp;
      }

      String questionText = isAddition ? '$num1 + $num2 = ?' : '$num1 - $num2 = ?';
      int correctAnswerVal = isAddition ? (num1 + num2) : (num1 - num2);

      // 誤答択（ダミー選択肢）を3つ作成（正解と被らないようにする）
      Set<int> wrongAnswers = {};
      while (wrongAnswers.length < 3) {
        // 正解の数字の周辺からランダムに散らす
        int diff = random.nextInt(20) - 10; // -10 〜 +9
        int wrongVal = correctAnswerVal + diff;
        if (wrongVal != correctAnswerVal) {
          wrongAnswers.add(wrongVal);
        }
      }

      // 選択肢のリスト（String型）を組み立てる
      List<String> choices = [
        correctAnswerVal.toString(),
        ...wrongAnswers.map((e) => e.toString())
      ];

      // クイズモデルに変換してリストに追加
      mathQuizzes.add(QuizModel(
        question: questionText,
        choices: choices,
        correctAnswer: correctAnswerVal.toString(),
        category: '計算専門',
        questionType: 'four_choices', // 🔥 ここを追加！
      ));
    }

    // 計算クイズデータを持って、直接プレイ画面へ遷移（API通信は一切発生しない）
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPlayScreen(quizList: mathQuizzes),
      ),
    );
  }

  // AIクイズの生成と遷移の処理（こちらはGemini APIを使用）
  Future<void> _startAiQuiz() async {
    final finalTheme = _textController.text.trim().isNotEmpty 
        ? _textController.text.trim() 
        : _selectedTheme;

    setState(() {
      _isLoading = true;
    });

    try {
      final quizzes = await _aiService.generateAIQuizzes(
        theme: finalTheme,
        difficulty: _selectedDifficulty,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPlayScreen(quizList: quizzes),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: const Text('クイズの生成に失敗しました。APIキーの設定や通信環境を確認してください。\n※計算専門マラソンは通信なしで遊べます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 24),
              Text('AIがオリジナルクイズを作成中...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('これには数秒かかる場合があります', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AIクイズ＆計算マラソン'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 【追加】通信もAPIも一切使わない「計算専門マラソン」の起動ボタン
            const Text('【通信なしで遊ぶ】', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startMathMarathon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.calculate),
                label: const Text('計算専門マラソン スタート！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(), // 区切り線
            ),

            const Text('【AIクイズに挑戦する】', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            const Text('1. お題を選ぼう', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              children: _subjects.map((subject) {
                final isSelected = _selectedTheme == subject && _textController.text.isEmpty;
                return ChoiceChip(
                  label: Text(subject),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTheme = subject;
                        _textController.clear();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: '自由にお題を入力（例：日本の歴史、世界遺産）',
                border: OutlineInputBorder(),
                hintText: 'ここに入力すると上の選択より優先されます',
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 32),
            const Text('2. むずかしさを選ぼう', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: _difficulties.map((diff) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(diff),
                    selected: _selectedDifficulty == diff,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDifficulty = diff;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            // AIクイズ用のスタートボタン
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startAiQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  '${_textController.text.trim().isNotEmpty ? _textController.text.trim() : _selectedTheme} AIクイズを生成！',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// 2. 4択クイズ プレイ画面（10秒タイマー・シャッフル機能付き）
// =================================================================
class QuizPlayScreen extends StatefulWidget {
  final List<QuizModel> quizList;

  const QuizPlayScreen({super.key, required this.quizList});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _currentIndex = 0;
  int _score = 0;
  bool _isGameOver = false;
  bool _isGameClear = false;
  
  Timer? _timer;
  final double _maxTime = 10.0;
  double _remainingTime = 10.0;

  List<String> _shuffledChoices = [];

  @override
  void initState() {
    super.initState();
    _setupQuestion();
  }

  void _setupQuestion() {
    if (_currentIndex >= widget.quizList.length) {
      setState(() {
        _isGameClear = true;
      });
      _timer?.cancel();
      return;
    }

    final currentQuiz = widget.quizList[_currentIndex];
    
    setState(() {
      _shuffledChoices = List<String>.from(currentQuiz.choices)..shuffle();
      _remainingTime = _maxTime;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_remainingTime <= 0.1) {
          _timer?.cancel();
          _isGameOver = true;
        } else {
          _remainingTime -= 0.1;
        }
      });
    });
  }

  void _answerQuestion(String selectedChoice) {
    _timer?.cancel();
    final currentQuiz = widget.quizList[_currentIndex];

    if (selectedChoice == currentQuiz.correctAnswer) {
      _score++;
      _currentIndex++;
      _setupQuestion();
    } else {
      setState(() {
        _isGameOver = true;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isGameOver) return _buildGameOverScreen();
    if (_isGameClear) return _buildGameClearScreen();

    final currentQuiz = widget.quizList[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('第 ${_currentIndex + 1} 問 / 全 ${widget.quizList.length} 問'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('スコア: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('ジャンル: ${currentQuiz.category}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: _remainingTime / _maxTime,
            backgroundColor: Colors.grey[300],
            color: _remainingTime < 3.0 ? Colors.red : Colors.teal,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              currentQuiz.question,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              children: _shuffledChoices.map((choice) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _answerQuestion(choice),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[50],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.teal.shade200),
                      ),
                      child: Text(choice, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_very_dissatisfied, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text('ゲームオーバー！', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            Text('記録: $_score 問正解', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
              child: const Text('トップに戻る', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameClearScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('完全制覇！おめでとう！', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 8),
            const Text('10問のマラソンクイズをすべてクリアしました！', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('トップに戻る', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}