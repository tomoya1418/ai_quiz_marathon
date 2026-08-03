import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
// 先ほど作成したAIサービスのファイルをインポート
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
      debugShowCheckedModeBanner: false, // 画面右上のDebugリボンを非表示にする
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const QuizTopScreen(),
    );
  }
}

// =================================================================
// 1. トップ画面（お題選択・難易度設定）
// =================================================================
class QuizTopScreen extends StatefulWidget {
  const QuizTopScreen({super.key});

  @override
  State<QuizTopScreen> createState() => _QuizTopScreenState();
}

class _QuizTopScreenState extends State<QuizTopScreen> {
  final _aiService = AiService();
  final _textController = TextEditingController();
  
  String _selectedTheme = '国語'; // 初期選択のお題
  String _selectedDifficulty = '普通'; // 初期選択の難易度
  bool _isLoading = false;

  // 固定の5教科リスト
  final List<String> _subjects = ['国語', '算数', '理科', '社会', '英語'];
  final List<String> _difficulties = ['簡単', '普通', '難しい'];

  // AIクイズの生成と遷移の処理
  Future<void> _startAiQuiz() async {
    // テキスト入力があればそれを優先、なければ選択されている教科にする
    final finalTheme = _textController.text.trim().isNotEmpty 
        ? _textController.text.trim() 
        : _selectedTheme;

    setState(() {
      _isLoading = true;
    });

    try {
      // AIサービスを呼び出してクイズデータを取得
      final quizzes = await _aiService.generateAIQuizzes(
        theme: finalTheme,
        difficulty: _selectedDifficulty,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // 取得成功したら、クイズリストを持ってプレイ画面へ遷移
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
      // エラーが起きた場合はダイアログで通知
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: const Text('クイズの生成に失敗しました。APIキーの設定や通信環境を確認してください。'),
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
    // ローディング中の場合は専用の画面を表示
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
      appBar: AppBar(title: const Text('AIクイズマラソン'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. お題を選ぼう', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // 5教科の選択チップ
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
                        _textController.clear(); // フリー入力をクリア
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // フリー入力テキストボックス
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: '自由にお題を入力（例：日本の歴史、世界遺産、宇宙）',
                border: OutlineInputBorder(),
                hintText: 'ここに入力すると上の選択より優先されます',
              ),
              onChanged: (value) {
                setState(() {}); // 入力状態に応じて一番下のボタンの文言を変えるため画面再描画
              },
            ),
            const SizedBox(height: 32),
            const Text('2. むずかしさを選ぼう', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // 難易度の選択チップ
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
            // スタートボタン
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
                  '${_textController.text.trim().isNotEmpty ? _textController.text.trim() : _selectedTheme} クイズを生成！',
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
  int _currentIndex = 0; // 現在何問目か (0〜9)
  int _score = 0;
  bool _isGameOver = false;
  bool _isGameClear = false;
  
  // タイマー関連
  Timer? _timer;
  final double _maxTime = 10.0; // 4択は一律10秒制限
  double _remainingTime = 10.0;

  List<String> _shuffledChoices = []; // シャッフルされた選択肢の格納用

  @override
  void initState() {
    super.initState();
    _setupQuestion();
  }

  // 現在の問題を設定し、選択肢をシャッフルする
  void _setupQuestion() {
    if (_currentIndex >= widget.quizList.length) {
      // 10問すべて全問正解した場合
      setState(() {
        _isGameClear = true;
      });
      _timer?.cancel();
      return;
    }

    final currentQuiz = widget.quizList[_currentIndex];
    
    setState(() {
      // choices配列をコピーしてランダムにシャッフル (..shuffle()はカスケード演算子)
      _shuffledChoices = List<String>.from(currentQuiz.choices)..shuffle();
      _remainingTime = _maxTime;
    });

    _startTimer();
  }

  // 10秒のカウントダウンタイマー（0.1秒刻みでスムーズに減らす）
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_remainingTime <= 0.1) {
          _timer?.cancel();
          _isGameOver = true; // 時間切れでゲームオーバー
        } else {
          _remainingTime -= 0.1;
        }
      });
    });
  }

  // 選択肢がタップされた時の正誤判定処理
  void _answerQuestion(String selectedChoice) {
    _timer?.cancel();
    final currentQuiz = widget.quizList[_currentIndex];

    if (selectedChoice == currentQuiz.correctAnswer) {
      // 正解の場合
      _score++;
      _currentIndex++;
      _setupQuestion(); // 次の問題のセットアップへ
    } else {
      // 不正解の場合（マラソン形式なので即ゲームオーバー）
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
        automaticallyImplyLeading: false, // プレイ中に誤って戻るのを防ぐため戻るボタンを非表示
      ),
      body: Column(
        children: [
          // スコアとジャンル表示
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
          // カウントダウンプログレスバー
          LinearProgressIndicator(
            value: _remainingTime / _maxTime,
            backgroundColor: Colors.grey[300],
            color: _remainingTime < 3.0 ? Colors.red : Colors.teal,
          ),
          const Spacer(),
          // 問題文の表示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              currentQuiz.question,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          // 4択ボタンの配置
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

  // --- ゲームオーバー画面 ---
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

  // --- ゲームクリア画面 ---
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
            const Text('AIが作った10問のクイズをすべてクリアしました！', style: TextStyle(fontSize: 16, color: Colors.grey)),
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