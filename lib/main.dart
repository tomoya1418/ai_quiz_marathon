import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
// 1. トップ画面
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

  // 🔥 難易度ごとの最高記録を保持する変数
  int _highScoreEasy = 0;
  int _highScoreNormal = 0;
  int _highScoreHard = 0;

  final List<String> _subjects = ['国語', '算数', '理科', '社会', '英語'];
  final List<String> _difficulties = ['簡単', '普通', '難しい'];

  @override
  void initState() {
    super.initState();
    _loadHighScores(); 
  }

  // 🔥 各難易度のハイスコアを個別にロードする
  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScoreEasy = prefs.getInt('math_high_score_簡単') ?? 0;
      _highScoreNormal = prefs.getInt('math_high_score_普通') ?? 0;
      _highScoreHard = prefs.getInt('math_high_score_難しい') ?? 0;
    });
  }

  // 現在選択されている難易度のハイスコアを返すヘルパー
  int _getCurrentDifficultyScore() {
    if (_selectedDifficulty == '簡単') return _highScoreEasy;
    if (_selectedDifficulty == '難しい') return _highScoreHard;
    return _highScoreNormal; // デフォルトは「普通」
  }

  void _startMathMarathon() {
    List<QuizModel> initialQuizzes = [];
    for (int i = 0; i < 3; i++) {
      initialQuizzes.add(_generateSingleMathQuiz(_selectedDifficulty));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPlayScreen(
          quizList: initialQuizzes,
          isMathMarathon: true, 
          marathonDifficulty: _selectedDifficulty,
        ),
      ),
    ).then((_) => _loadHighScores()); // 画面から戻ってきたらスコアを再読み込み
  }

  static QuizModel _generateSingleMathQuiz(String difficulty) {
    final random = Random();
    int minVal = 1;
    int maxVal = 9;

    if (difficulty == '普通') {
      minVal = 10;
      maxVal = 99;
    } else if (difficulty == '難しい') {
      minVal = 100;
      maxVal = 999;
    }

    int num1 = random.nextInt(maxVal - minVal + 1) + minVal;
    int num2 = random.nextInt(maxVal - minVal + 1) + minVal;
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
      if (wrongVal != correctAnswerVal && wrongVal >= 0) {
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
      category: '計算専門 ($difficulty)',
      questionType: 'four_choices',
    );
  }

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
            marathonDifficulty: _selectedDifficulty,
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
          //content: const Text('クイズの生成に失敗しました。APIキーの設定や通信環境を確認してください。\n※計算専門マラソンは通信なしで遊べます。'),
          content: const Text('{e.toString()}'),
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
            const Text('【通信なしで遊ぶ・難易度連動】', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            
            // 🏆 選択中難易度のハイスコア表示パネル
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'マラソン [$_selectedDifficulty] 最高記録: ${_getCurrentDifficultyScore()} 問連続正解！',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
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
                label: Text('計算マラソン ($_selectedDifficulty) スタート！', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(),
            ),

            const Text('【設定 ＆ AIクイズ】', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 12),
            
            const Text('⚡ 計算の桁数 / クイズの難易度を選択', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // 難易度チップ切り替え（切り替えると上のスコア表示も自動で変わります）
            Row(
              children: _difficulties.map((diff) {
                String sub = diff == '簡単' ? ' (1桁)' : diff == '普通' ? ' (2桁)' : ' (3桁)';
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(diff + sub),
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
            
            // 📊 寄り道要素：全難易度のスコア一覧（スコアボード）
            const SizedBox(height: 12),
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('簡単: $_highScoreEasy問', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                    Text('普通: $_highScoreNormal問', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                    Text('難しい: $_highScoreHard問', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('1. AIクイズのお題を選ぼう', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                labelText: '自由にお題を入力（例：世界の歴史、サッカーのルール）',
                border: OutlineInputBorder(),
                hintText: 'ここに入力すると上の選択より優先されます',
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 32),
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
// 2. クイズプレイ画面
// =================================================================
class QuizPlayScreen extends StatefulWidget {
  final List<QuizModel> quizList;
  final bool isMathMarathon; 
  final String marathonDifficulty; 

  const QuizPlayScreen({
    super.key, 
    required this.quizList, 
    required this.isMathMarathon,
    required this.marathonDifficulty,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  late List<QuizModel> _dynamicQuizList; 
  int _currentIndex = 0;
  int _score = 0;
  bool _isGameOver = false;
  bool _isGameClear = false;
  bool _isNewHighScore = false; 
  
  Timer? _timer;
  double _maxTime = 10.0; 
  double _remainingTime = 10.0;

  List<String> _shuffledChoices = [];

  @override
  void initState() {
    super.initState();
    _dynamicQuizList = List<QuizModel>.from(widget.quizList);
    _setupQuestion();
  }

  void _setupQuestion() {
    if (!widget.isMathMarathon && _currentIndex >= _dynamicQuizList.length) {
      setState(() {
        _isGameClear = true;
      });
      _timer?.cancel();
      return;
    }

    if (widget.isMathMarathon && _currentIndex >= _dynamicQuizList.length - 1) {
      _dynamicQuizList.add(_QuizTopScreenState._generateSingleMathQuiz(widget.marathonDifficulty));
    }

    if (widget.isMathMarathon) {
      double calculatedTime = 10.0 - (_score * 0.5); 
      _maxTime = calculatedTime < 3.0 ? 3.0 : calculatedTime; 
    } else {
      _maxTime = 10.0; 
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
          _handleGameOver(); 
        } else {
          _remainingTime -= 0.1;
        }
      });
    });
  }

  // 🔥 ゲームオーバー時に、その難易度専用のキーでハイスコア判定・保存を行う
  Future<void> _handleGameOver() async {
    setState(() {
      _isGameOver = true;
    });

    if (widget.isMathMarathon) {
      final prefs = await SharedPreferences.getInstance();
      // 難易度ごとに個別の保存キー（例: math_high_score_簡単）を作成
      String scoreKey = 'math_high_score_${widget.marathonDifficulty}';
      int currentHighScore = prefs.getInt(scoreKey) ?? 0;
      
      if (_score > currentHighScore) {
        await prefs.setInt(scoreKey, _score);
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
      _setupQuestion(); 
    } else {
      _handleGameOver(); 
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
        title: Text(widget.isMathMarathon ? '計算マラソン (${widget.marathonDifficulty})' : '第 ${_currentIndex + 1} 問 / 全 ${widget.quizList.length} 問'),
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
                Text('制限時間: ${_maxTime.toStringAsFixed(1)}秒', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold), 
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
                      child: Text(choice, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
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
            Icon(
              _isNewHighScore ? Icons.emoji_events : Icons.sentiment_very_dissatisfied, 
              size: 90, 
              color: _isNewHighScore ? Colors.amber : Colors.red
            ),
            const SizedBox(height: 16),
            Text(
              _isNewHighScore ? '✨ ${widget.marathonDifficulty}で新記録！ ✨' : 'ゲームオーバー！', 
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _isNewHighScore ? Colors.amber.shade800 : Colors.red)
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
            const Text('すべてのAIクイズをクリアしました！', style: TextStyle(fontSize: 16, color: Colors.grey)),
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