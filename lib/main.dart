import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '加速！計算マラソン',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const QuizHomeScreen(),
    );
  }
}

class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  // ゲームの状態管理
  int _score = 0;
  bool _isGameOver = false;
  String _currentQuestion = '';
  int _correctAnswer = 0;
  String _userInput = '';
  
  // タイマー関連
  Timer? _timer;
  double _maxTime = 10.0; // 初期は10秒
  double _remainingTime = 10.0;

  @override
  void initState() {
    super.initState();
    _generateNewQuestion();
    _startTimer();
  }

  // 1. 難易度とスコアに応じた計算問題の自動生成（乱数）
  void _generateNewQuestion() {
    final rand = Random();
    int num1, num2;

    // スコア（コンボ）に応じて制限時間を徐々に短くする（最速5秒）
    if (_score < 3) {
      _maxTime = 10.0;
      // 簡単：1桁の足し算
      num1 = rand.nextInt(9) + 1;
      num2 = rand.nextInt(9) + 1;
    } else if (_score < 6) {
      _maxTime = 7.0;
      // 普通：2桁の足し算
      num1 = rand.nextInt(40) + 10;
      num2 = rand.nextInt(40) + 10;
    } else {
      _maxTime = 5.0; // ここが限界の最速
      // 難しい：3桁の足し算（あるいは桁の大きい2桁）
      num1 = rand.nextInt(90) + 10;
      num2 = rand.nextInt(90) + 10;
    }

    setState(() {
      _currentQuestion = '$num1 + $num2 = ?';
      _correctAnswer = num1 + num2;
      _userInput = '';
      _remainingTime = _maxTime;
    });
  }

  // 2. タイムアタックタイマーの制御
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

  // 3. テンキーが押された時の処理（オート判定）
  void _onNumpadPressed(String value) {
    if (_isGameOver) return;

    setState(() {
      if (value == 'C') {
        _userInput = '';
      } else {
        _userInput += value;
        
        // 入力された数値が正解と一致した瞬間に自動でクリア判定（確定ボタン不要）
        if (int.tryParse(_userInput) == _correctAnswer) {
          _score++;
          _generateNewQuestion();
          _startTimer(); // タイマーをリセットして次の問題へ
        }
      }
    });
  }

  // ゲームリスタート
  void _resetGame() {
    setState(() {
      _score = 0;
      _isGameOver = false;
    });
    _generateNewQuestion();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('加速！計算マラソン')),
      body: _isGameOver ? _buildGameOverScreen() : _buildQuizScreen(),
    );
  }

  // クイズ画面のレイアウト
  Widget _buildQuizScreen() {
    return Column(
      children: [
        // スコアとタイマーゲージ
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('スコア: $_score 問連続正解', style: const TextStyle(fontSize: 20, fontWeight:高体)),
              Text('制限時間: ${_maxTime.toInt()}秒', style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        // タイマーの視覚的なプログレスバー
        LinearProgressIndicator(
          value: _remainingTime / _maxTime,
          backgroundColor: Colors.grey[300],
          color: _remainingTime < 3.0 ? Colors.red : Colors.blue,
        ),
        const Spacer(),
        // 問題文の表示
        Text(_currentQuestion, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        // ユーザーの入力値表示
        Container(
          minWidth: 150,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(8)),
          child: Text(_userInput.isEmpty ? '?' : _userInput, style: const TextStyle(fontSize: 32), textAlign: TextAlign.center),
        ),
        const Spacer(),
        // 電卓風テンキーの配置
        _buildNumpad(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ゲームオーバー画面（ここに後にリワード広告の導線が入ります）
  Widget _buildGameOverScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('ゲームオーバー！', style: TextStyle(fontSize: 36, color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('記録: $_score 問正解', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh),
            label: const Text('最初から挑戦する', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
        ],
      ),
    );
  }

  // テンキーWidgetの生成
  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', ''],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 80, height: 60);
              return Container(
                margin: const EdgeInsets.all(4),
                width: 80,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _onNumpadPressed(key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: key == 'C' ? Colors.orange[100] : Colors.blue[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}