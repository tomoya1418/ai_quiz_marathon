import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🔥 追加
import 'services/ai_service.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIクイズ＆計算マラソン',
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
// 1. トップ画面（最高記録の表示機能を追加）
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
  int _highScore = 0; // 🔥 最高記録を保持する変数

  final List<String> _subjects = ['国語', '算数', '理科', '社会', '英語'];
  final List<String> _difficulties = ['簡単', '普通', '難しい'];

  @override
  void initState() {
    super.initState();
    _loadHighScore(); // 🔥 画面が開いたときに最高記録を読み込む
  }

  // 🔥 デバイスから最高記録を読み込む関数
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('math_high_score') ?? 0;
    });
  }

  // 🔥 計算専門マラソン起動関数（無限対応版）
  // プレイ画面側で次々に生成するため、ここでは最初の数問だけ作って渡します
  void _startMathMarathon() {
    List<QuizModel> initialQuizzes = [];
    for (int i = 0; i < 3; i++) {
      initialQuizzes.add(_generateSingleMathQuiz());
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPlayScreen(
          quizList: initialQuizzes,
          isMathMarathon: true, // 🔥 計算マラソンフラグをON
        ),
      ),
    ).then((_) => _loadHighScore()); // 🔥 ゲームから戻ってきたら最高記録を再読み込みして更新
  }

  // 🔥 単発の計算問題をランダム生成する共通ロジック（マイナス値回避）
  static QuizModel _generateSingleMathQuiz() {
    final random = Random();
    int num1 = random.nextInt(50) + 1;
    int num2 = random.nextInt(50) + 1;
    bool isAddition = random.nextBool();
    
    if (!isAddition && num1 < num2) {
      int temp = num1;
      num1 = num2;
      num2 = temp;
    }

    String questionText = isAddition ? '$num1 + $num2 = ?' : '$num1 - $num2 = ?';
    int correctAnswerVal = isAddition ? (num1 + num2) : (num1 - num2);

    Set<int> wrongAnswers = {};
    while (wrongAnswers.length < 3) {
      int diff = random.nextInt(20) - 10;
      int wrongVal = correctAnswerVal + diff;
      if (wrongVal != correctAnswerVal) {
        wrongAnswers.add(wrongVal);
      }
    }

    List<String> choices = [
      correctAnswerVal.toString(),
      ...wrongAnswers.map((e) => e.toString())
    ];

    return QuizModel(
      question: questionText,
      choices: choices,
      correctAnswer: correctAnswerVal.toString(),
      category: '計算専門',
      questionType: 'four_choices',
    );
  }

  // AIクイズの生成と遷移の処理（こちらは10問限定のまま）
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
          builder: (context) => QuizPlayScreen(
            quizList: quizzes,
            isMathMarathon: false,
          ),
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
            const Text('【通信なしで遊ぶ】', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            
            // 🔥 【追加】現在の最高記録メーター
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color:Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '計算マラソン最高記録: $_highScore 問連続正解！',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
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
                label: const Text('計算マラソン スタート！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(),
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
// 2. クイズプレイ画面（無限生成＆ハイスコア保存ロジック内蔵）
// =================================================================
class QuizPlayScreen extends StatefulWidget {
  final List<QuizModel> quizList;
  final bool isMathMarathon; // 🔥 計算マラソンかどうかの判定フラグ

  const QuizPlayScreen({super.key, required this.quizList, required this.isMathMarathon});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  late List<QuizModel> _dynamicQuizList; // 動的に問題を追加していくためのリスト
  int _currentIndex = 0;
  int _score = 0;
  bool _isGameOver = false;
  bool _isGameClear = false;
  bool _isNewHighScore = false; // 🔥 新記録達成フラグ
  
  Timer? _timer;
  final double _maxTime = 10.0;
  double _remainingTime = 10.0;

  List<String> _shuffledChoices = [];

  @override
  void initState() {
    super.initState();
    _dynamicQuizList = List<QuizModel>.from(widget.quizList);
    _setupQuestion();
  }

  void _setupQuestion() {
    // 🔥 【重要】計算マラソンでなければ（AIクイズなら）、10問でゲームクリア判定
    if (!widget.isMathMarathon && _currentIndex >= _dynamicQuizList.length) {
      setState(() {
        _isGameClear = true;
      });
      _timer?.cancel();
      return;
    }

    // 🔥 計算マラソンの場合、手前の問題に差し掛かったら次の問題を自動で無限ケツに追加
    if (widget.isMathMarathon && _currentIndex >= _dynamicQuizList.length - 1) {
      _dynamicQuizList.add(_QuizTopScreenState._generateSingleMathQuiz());
    }

    final currentQuiz = _dynamicQuizList[_currentIndex];
    
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
          _handleGameOver(); // 🔥 時間切れもゲームオーバー処理へ
        } else {
          _remainingTime -= 0.1;
        }
      });
    });
  }

  // 🔥 ゲームオーバー時のスコア保存処理
  Future<void> _handleGameOver() async {
    setState(() {
      _isGameOver = true;
    });

    if (widget.isMathMarathon) {
      final prefs = await SharedPreferences.getInstance();
      int currentHighScore = prefs.getInt('math_high_score') ?? 0;
      
      // 今のスコアがハイスコアを上回っていたら保存
      if (_score > currentHighScore) {
        await prefs.setInt('math_high_score', _score);
        setState(() {
          _isNewHighScore = true;
        });
      }
    }
  }

  void _answerQuestion(String selectedChoice) {
    _timer?.cancel();
    final currentQuiz = _dynamicQuizList[_currentIndex];

    if (selectedChoice == currentQuiz.correctAnswer) {
      _score++;
      _currentIndex++;
      _setupQuestion(); // 正解なら無限に次へ
    } else {
      _handleGameOver(); // 🔥 間違えたら即ゲームオーバー＆記録判定
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

    final currentQuiz = _dynamicQuizList[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMathMarathon ? '計算マラソン 挑戦中' : '第 ${_currentIndex + 1} 問 / 全 ${widget.quizList.length} 問'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('現在のスコア: $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold), // 計算を見やすく大きく
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
                      child: Text(choice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
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
            // 🔥 新記録なら金メダル、通常なら残念顔アイコン
            Icon(
              _isNewHighScore ? Icons.emoji_events : Icons.sentiment_very_dissatisfied, 
              size: 90, 
              color: _isNewHighScore ? Colors.amber : Colors.red
            ),
            const SizedBox(height: 16),
            Text(
              _isNewHighScore ? '✨ 新記録達成！ ✨' : 'ゲームオーバー！', 
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _isNewHighScore ? Colors.amber.shade800 : Colors.red)
            ),
            const SizedBox(height: 12),
            Text('今回の記録: $_score 問連続正解', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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