import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '最強！数字の脳トレランド',
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
// 1. 総合トップ画面（4つのゲーム選択メニュー）
// =================================================================
class QuizTopScreen extends StatefulWidget {
  const QuizTopScreen({super.key});

  @override
  State<QuizTopScreen> createState() => _QuizTopScreenState();
}

class _QuizTopScreenState extends State<QuizTopScreen> {
  // --- モード1（計算マラソン）用の設定 ---
  final Map<String, bool> _selectedOperations = {
    'たし算': true,
    'ひき算': false,
    'かけ算': false,
    'わり算': false,
    'わり算のあまり': false,
    '穴あきクイズ': false,
  };
  String _marathonDifficulty = '普通';

  // --- 各モードのハイスコア ---
  int _scoreMarathon = 0;
  int _scoreCompare = 0;
  int _scoreMakeTen = 0;
  int _scoreTouch = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScores();
  }

  Future<void> _loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _scoreMarathon = prefs.getInt('high_score_marathon') ?? 0;
      _scoreCompare = prefs.getInt('high_score_compare') ?? 0;
      _scoreMakeTen = prefs.getInt('high_score_maketen') ?? 0;
      _scoreTouch = prefs.getInt('high_score_touch') ?? 0;
    });
  }

  // 計算マラソン起動
  void _startMathMarathon() {
    List<String> activeOps = [];
    _selectedOperations.forEach((key, val) { if (val) activeOps.add(key); });

    if (activeOps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('計算の種類をどれか1つ選んでね！')));
      return;
    }

    List<QuizModel> initialQuizzes = [];
    for (int i = 0; i < 3; i++) {
      initialQuizzes.add(_generateMarathonQuiz(activeOps, _marathonDifficulty));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPlayScreen(
          gameMode: 'marathon',
          title: '無限計算マラソン',
          quizList: initialQuizzes,
          activeOperations: activeOps,
          difficulty: _marathonDifficulty,
          scoreKey: 'high_score_marathon',
        ),
      ),
    ).then((_) => _loadHighScores());
  }

  // 大きいのどっち起動
  void _startCompareGame() {
    List<QuizModel> initialQuizzes = [];
    for (int i = 0; i < 3; i++) { initialQuizzes.add(_generateCompareQuiz()); }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPlayScreen(
          gameMode: 'compare',
          title: 'どっちが大きい？',
          quizList: initialQuizzes,
          scoreKey: 'high_score_compare',
        ),
      ),
    ).then((_) => _loadHighScores());
  }

  // ピッタリ10起動
  void _startMakeTenGame() {
    List<QuizModel> initialQuizzes = [];
    for (int i = 0; i < 3; i++) { initialQuizzes.add(_generateMakeTenQuiz()); }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPlayScreen(
          gameMode: 'maketen',
          title: 'ぴったり１０！',
          quizList: initialQuizzes,
          scoreKey: 'high_score_maketen',
        ),
      ),
    ).then((_) => _loadHighScores());
  }

  // 数値タッチゲーム起動
  void _startNumberTouchGame() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NumberTouchScreen()),
    ).then((_) => _loadHighScores());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 最強！数字の脳トレランド'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🟥 1. 計算マラソンカード
            _buildGameCard(
              title: '1. 無限計算マラソン',
              description: 'えらんだ計算がまぜこぜで出題されるぞ！',
              highScore: _scoreMarathon,
              icon: Icons.calculate,
              color: Colors.orange.shade50,
              accentColor: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('▼ 計算の種類（いくつでも選べるよ）', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _selectedOperations.keys.map((key) {
                      bool isSelected = _selectedOperations[key]!;
                      return FilterChip(
                        label: Text(key, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        selectedColor: Colors.orange.shade200,
                        onSelected: (val) => setState(() => _selectedOperations[key] = val),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text('▼ むずかしさ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Row(
                    children: ['簡単', '普通', '難しい'].map((diff) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(diff, style: const TextStyle(fontSize: 12)),
                          selected: _marathonDifficulty == diff,
                          selectedColor: Colors.orange.shade300,
                          onSelected: (val) { if (val) setState(() => _marathonDifficulty = diff); },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startMathMarathon,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                      child: const Text('スタート！', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 🟦 2. 大小比較カード
            _buildGameCard(
              title: '2. どっちが大きい？',
              description: '左右の計算を見て、答えが大きい方をすばやくタップ！おなじ（＝）の時もあるぞ！',
              highScore: _scoreCompare,
              icon: Icons.compare_arrows,
              color: Colors.blue.shade50,
              accentColor: Colors.blue,
              child: ElevatedButton(
                onPressed: _startCompareGame,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                child: const Text('スピード勝負スタート！', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            // 🟩 3. メイクテンカード
            _buildGameCard(
              title: '3. ぴったり１０（テンパズル）',
              description: '4つの数字を組み合わせて、答えが「10」になる式をみつけよう！',
              highScore: _scoreMakeTen,
              icon: Icons.extension,
              color: Colors.green.shade50,
              accentColor: Colors.green,
              child: ElevatedButton(
                onPressed: _startMakeTenGame,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                child: const Text('パズルスタート！', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            // 🟪 4. 数字順タッチカード
            _buildGameCard(
              title: '4. 数字の順番タッチ',
              description: '1から16までの数字を順番にすばやくタッチ！タイムアタックだ！',
              highScore: _scoreTouch == 0 ? 0 : _scoreTouch, 
              isTimeScore: true,
              icon: Icons.touch_app,
              color: Colors.purple.shade50,
              accentColor: Colors.purple,
              child: ElevatedButton(
                onPressed: _startNumberTouchGame,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
                child: const Text('タイムアタックスタート！', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String description,
    required int highScore,
    required IconData icon,
    required Color color,
    required Color accentColor,
    required Widget child,
    bool isTimeScore = false,
  }) {
    String scoreText = isTimeScore 
        ? (highScore == 0 ? 'まだ記録がありません' : '${(highScore / 10).toStringAsFixed(1)} 秒')
        : '$highScore 問連続正解';

    return Card(
      color: color,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 28),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('ベスト記録: $scoreText', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  // --- クイズ自動生成ロジック（マラソン用） ---
  static QuizModel _generateMarathonQuiz(List<String> activeOps, String difficulty) {
    final random = Random();
    String currentOp = activeOps[random.nextInt(activeOps.length)];
    int num1 = 0, num2 = 0;
    String question = '';
    String correct = '';
    Set<int> wrong = {};

    int minVal = 1, maxVal = 9;
    if (difficulty == '普通') { minVal = 10; maxVal = 99; }
    if (difficulty == '難しい') { minVal = 100; maxVal = 999; }

    if (currentOp == 'たし算') {
      num1 = random.nextInt(maxVal - minVal + 1) + minVal; num2 = random.nextInt(maxVal - minVal + 1) + minVal;
      question = '$num1 + $num2 = ?'; correct = (num1 + num2).toString();
      _dummies(num1 + num2, wrong, random, 20);
    } else if (currentOp == 'ひき算') {
      num1 = random.nextInt(maxVal - minVal + 1) + minVal; num2 = random.nextInt(maxVal - minVal + 1) + minVal;
      if (num1 < num2) { int t = num1; num1 = num2; num2 = t; }
      question = '$num1 - $num2 = ?'; correct = (num1 - num2).toString();
      _dummies(num1 - num2, wrong, random, 20);
    } else if (currentOp == 'かけ算') {
      if (difficulty == '簡単') { num1 = random.nextInt(9) + 1; num2 = random.nextInt(9) + 1; }
      else if (difficulty == '普通') { num1 = random.nextInt(90) + 10; num2 = random.nextInt(9) + 1; }
      else { num1 = random.nextInt(90) + 10; num2 = random.nextInt(90) + 10; }
      question = '$num1 × $num2 = ?'; correct = (num1 * num2).toString();
      _dummies(num1 * num2, wrong, random, 40);
    } else if (currentOp == 'わり算') {
      if (difficulty == '簡単') { num2 = random.nextInt(9) + 1; int a = random.nextInt(9) + 1; num1 = num2 * a; }
      else if (difficulty == '普通') { num2 = random.nextInt(9) + 1; int a = random.nextInt(90) + 10; num1 = num2 * a; }
      else { num2 = random.nextInt(90) + 10; int a = random.nextInt(90) + 10; num1 = num2 * a; }
      question = '$num1 ÷ $num2 = ?'; correct = (num1 ~/ num2).toString();
      _dummies(num1 ~/ num2, wrong, random, 15);
    } else if (currentOp == 'わり算のあまり') {
      if (difficulty == '簡単') { num1 = random.nextInt(20) + 5; num2 = random.nextInt(4) + 2; }
      else if (difficulty == '普通') { num1 = random.nextInt(90) + 10; num2 = random.nextInt(7) + 3; }
      else { num1 = random.nextInt(500) + 100; num2 = random.nextInt(15) + 5; }
      if (num1 < num2) num1 += num2;
      question = '$num1 ÷ $num2 のあまりは？'; correct = 'あまり ${num1 % num2}';
      while (wrong.length < 3) { int d = random.nextInt(num2); if (d != (num1 % num2)) wrong.add(d); }
      return QuizModel(question: question, choices: [correct, ...wrong.map((e) => 'あまり $e')], correctAnswer: correct);
    } else if (currentOp == '穴あきクイズ') {
      num1 = random.nextInt(maxVal - minVal + 1) + minVal; num2 = random.nextInt(maxVal - minVal + 1) + minVal;
      if (random.nextBool()) {
        question = '$num1 + □ = ${num1 + num2}'; correct = num2.toString(); _dummies(num2, wrong, random, 15);
      } else {
        if (num1 < num2) { int t = num1; num1 = num2; num2 = t; }
        question = '$num1 - □ = ${num1 - num2}'; correct = num2.toString(); _dummies(num2, wrong, random, 15);
      }
    }
    return QuizModel(question: question, choices: [correct, ...wrong.map((e) => e.toString())], correctAnswer: correct);
  }

  // --- クイズ自動生成（大小比較用） ---
  static QuizModel _generateCompareQuiz() {
    final random = Random();
    // 簡単な2つの計算式を作って比べる
    int leftVal = random.nextInt(30) + 2;
    int rightVal = random.nextInt(30) + 2;
    if (random.nextInt(4) == 0) rightVal = leftVal; // 25%の確率で同じにする

    String leftStr = _makeFormula(leftVal, random);
    String rightStr = _makeFormula(rightVal, random);

    String question = '左： $leftStr\n右： $rightStr';
    String correct = 'おなじ（＝）';
    if (leftVal > rightVal) correct = 'ひだり（左）';
    if (leftVal < rightVal) correct = 'みぎ（右）';

    return QuizModel(question: question, choices: ['ひだり（左）', 'おなじ（＝）', 'みぎ（右）'], correctAnswer: correct);
  }

  static String _makeFormula(int target, Random rand) {
    if (rand.nextBool()) {
      int part = rand.nextInt(target.clamp(1, 20));
      return '$part + ${target - part}';
    } else {
      int plus = rand.nextInt(15);
      return '${target + plus} - $plus';
    }
  }

  // --- クイズ自動生成（メイクテン用） ---
  static QuizModel _generateMakeTenQuiz() {
    final random = Random();
    // 答えが10になる有名なパズルプールからランダム抽選
    List<Map<String, dynamic>> pool = [
      {'nums': '1, 2, 3, 4', 'ans': '(1 + 2 + 3) + 4', 'wrong': ['1×2×3×4', '(4-1)×2+3', '4×3-2-1']},
      {'nums': '2, 3, 5, 8', 'ans': '8 + 5 - 3.0', 'disp_ans': '8 + 5 - 3', 'wrong': ['2×3+5-8', '8×2-3-5', '8÷2+3+5']},
      {'nums': '2, 4, 7, 9', 'ans': '9 + 7 - 4 - 2', 'wrong': ['9×2-7-4', '7+4+2-9', '9+4+7÷2']},
      {'nums': '1, 5, 5, 5', 'ans': '(5 - 1 / 5) * 5', 'disp_ans': '(5 - 1 ÷ 5) × 5', 'wrong': ['5+5+5-1', '5×5÷5+1', '5+5×1-5']},
      {'nums': '3, 4, 7, 8', 'ans': '3 * (8 - 7) + 7', 'disp_ans': '3 × (8 - 7) + 7', 'wrong': ['8+7-4-3', '8×4-7×3', '7+8+3-4']},
      {'nums': '2, 2, 2, 9', 'ans': '9 + 2 - 2 / 2', 'disp_ans': '9 + 2 - (2 ÷ 2)', 'wrong': ['9+2+2+2', '9×2-2-2', '2×2×2+9']}
    ];
    var selected = pool[random.nextInt(pool.length)];
    String question = '「 ${selected['nums']} 」\nを使って 10 をつくろう！';
    String correct = selected['disp_ans'] ?? selected['ans'];
    List<String> wrongs = List<String>.from(selected['wrong']);

    return QuizModel(question: question, choices: [correct, ...wrongs], correctAnswer: correct);
  }

  static void _dummies(int c, Set<int> w, Random r, int rng) {
    while (w.length < 3) {
      int diff = r.nextInt(rng * 2) - rng; int val = c + diff;
      if (val != c && val >= 0) w.add(val);
    }
  }
}

// =================================================================
// 2. 共通クイズプレイ画面（マラソン・大小比較・メイクテン兼用）
// =================================================================
class QuizPlayScreen extends StatefulWidget {
  final String gameMode;
  final String title;
  final List<QuizModel> quizList;
  final List<String>? activeOperations;
  final String? difficulty;
  final String scoreKey;

  const QuizPlayScreen({
    super.key,
    required this.gameMode,
    required this.title,
    required this.quizList,
    this.activeOperations,
    this.difficulty,
    required this.scoreKey,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  late List<QuizModel> _dynamicQuizList;
  int _currentIndex = 0;
  int _score = 0;
  bool _isGameOver = false;
  bool _isNewHighScore = false;

  Timer? _timer;
  double _maxTime = 12.0;
  double _remainingTime = 12.0;
  List<String> _shuffledChoices = [];

  @override
  void initState() {
    super.initState();
    _dynamicQuizList = List<QuizModel>.from(widget.quizList);
    _setupQuestion();
  }

  void _setupQuestion() {
    // ストック補充
    if (_currentIndex >= _dynamicQuizList.length - 1) {
      if (widget.gameMode == 'marathon') {
        _dynamicQuizList.add(_QuizTopScreenState._generateMarathonQuiz(widget.activeOperations!, widget.difficulty!));
      } else if (widget.gameMode == 'compare') {
        _dynamicQuizList.add(_QuizTopScreenState._generateCompareQuiz());
      } else {
        _dynamicQuizList.add(_QuizTopScreenState._generateMakeTenQuiz());
      }
    }

    // 制限時間の調整（メイクテンはパズルなので一律30秒、それ以外は加速システム）
    if (widget.gameMode == 'maketen') {
      _maxTime = 30.0;
    } else {
      double calculatedTime = 12.0 - (_score * 0.5);
      _maxTime = calculatedTime < 4.0 ? 4.0 : calculatedTime;
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

  Future<void> _handleGameOver() async {
    setState(() { _isGameOver = true; });
    final prefs = await SharedPreferences.getInstance();
    int currentHighScore = prefs.getInt(widget.scoreKey) ?? 0;
    if (_score > currentHighScore) {
      await prefs.setInt(widget.scoreKey, _score);
      setState(() { _isNewHighScore = true; });
    }
  }

  void _answerQuestion(String selectedChoice) {
    _timer?.cancel();
    if (selectedChoice == _dynamicQuizList[_currentIndex].correctAnswer) {
      _score++; _currentIndex++; _setupQuestion();
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
    final currentQuiz = _dynamicQuizList[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('${widget.title} (スコア: $_score)')),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _remainingTime / _maxTime,
            backgroundColor: Colors.grey[300],
            color: _remainingTime < 4.0 ? Colors.red : Colors.teal,
            minHeight: 8,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              currentQuiz.question,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: Column(
              children: _shuffledChoices.map((choice) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _answerQuestion(choice),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.teal.shade200),
                      ),
                      child: Text(choice, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            Icon(_isNewHighScore ? Icons.emoji_events : Icons.sentiment_very_dissatisfied, size: 90, color: _isNewHighScore ? Colors.amber : Colors.red),
            Text(_isNewHighScore ? '✨ 新記録！おめでとう！ ✨' : 'ゲームオーバー！', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('スコア: $_score 問正解', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('トップに戻る')),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// 3. 数字の順番タッチ画面（タイムアタックモード）
// =================================================================
class NumberTouchScreen extends StatefulWidget {
  const NumberTouchScreen({super.key});

  @override
  State<NumberTouchScreen> createState() => _NumberTouchScreenState();
}

class _NumberTouchScreenState extends State<NumberTouchScreen> {
  List<int> _numbers = [];
  int _currentGoal = 1;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int _elapsedTenths = 0; // 0.1秒単位
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    // 1〜16の数字をシャッフル
    _numbers = List.generate(16, (i) => i + 1)..shuffle();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _elapsedTenths = _stopwatch.elapsedMilliseconds ~/ 100;
      });
    });
  }

  void _handleTouch(int num) {
    if (num == _currentGoal) {
      if (_currentGoal == 16) {
        // クリア！
        _stopwatch.stop();
        _timer?.cancel();
        setState(() { _isFinished = true; });
        _saveTouchScore(_elapsedTenths);
      } else {
        setState(() { _currentGoal++; });
      }
    }
  }

  Future<void> _saveTouchScore(int finalTime) async {
    final prefs = await SharedPreferences.getInstance();
    int currentBest = prefs.getInt('high_score_touch') ?? 99999;
    if (finalTime < currentBest) {
      await prefs.setInt('high_score_touch', finalTime);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flash_on, color: Colors.amber, size: 80),
              const Text('ゴール！！', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('タイム: ${(_elapsedTenths / 10).toStringAsFixed(1)} 秒', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 40),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('トップに戻る')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('次は 「 $_currentGoal 」 をタッチ！')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'タイム: ${(_elapsedTenths / 10).toStringAsFixed(1)} 秒',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: 16,
                itemBuilder: (context, index) {
                  int n = _numbers[index];
                  bool isCleared = n < _currentGoal;
                  return ElevatedButton(
                    onPressed: isCleared ? null : () => _handleTouch(n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCleared ? Colors.grey.shade300 : Colors.purple.shade50,
                      foregroundColor: Colors.purple.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: isCleared ? 0 : 2,
                    ),
                    child: Text(isCleared ? '' : '$n', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// 4. データモデル
// =================================================================
class QuizModel {
  final String question;
  final List<String> choices;
  final String correctAnswer;

  QuizModel({required this.question, required this.choices, required this.correctAnswer});
}