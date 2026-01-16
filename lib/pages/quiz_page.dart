import 'package:flutter/material.dart';
import 'dart:math';
import '../data/days_data.dart';
import '../models/international_day.dart';

enum QuizMode { guessDate, guessTitle, trueFalse }

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  QuizMode? _selectedMode;

  @override
  Widget build(BuildContext context) {
    if (_selectedMode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modes de Quiz')),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton(QuizMode.guessDate, 'Deviner la date'),
                _buildModeButton(QuizMode.guessTitle, 'Deviner le titre'),
                _buildModeButton(QuizMode.trueFalse, 'Vrai ou Faux'),
              ],
            ),
        ),
      );
    }

    return QuizGame(
      mode: _selectedMode!,
      onExit: () => setState(() => _selectedMode = null),
    );
  }

  Widget _buildModeButton(QuizMode mode, String label) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedMode = mode),
        style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
        child: Text(label),
      ),
    );
  }
}

class QuizGame extends StatefulWidget {
  final QuizMode mode;
  final VoidCallback onExit;

  const QuizGame({super.key, required this.mode, required this.onExit});

  @override
  State<QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<QuizGame> {
  final Random _random = Random();
  late InternationalDay _currentDay;
  List<String> _options = [];
  String? _feedback;
  bool _answered = false;
  int _score = 0;
  
  // Specific for True/False
  bool _isQuestionCorrect = true;
  String _tfQuestionText = '';

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  void _nextQuestion() {
    setState(() {
      _currentDay = internationalDaysData[_random.nextInt(internationalDaysData.length)];
      _answered = false;
      _feedback = null;
      
      if (widget.mode == QuizMode.trueFalse) {
         _isQuestionCorrect = _random.nextBool();
         if (_isQuestionCorrect) {
             _tfQuestionText = "Est-ce que le ${_currentDay.day}/${_currentDay.month} est la ${_currentDay.title} ?";
         } else {
             InternationalDay randomDay = internationalDaysData[_random.nextInt(internationalDaysData.length)];
             // Ensure it's not actually the correct one by chance
             while(randomDay.id == _currentDay.id) {
               randomDay = internationalDaysData[_random.nextInt(internationalDaysData.length)];
             }
             _tfQuestionText = "Est-ce que le ${_currentDay.day}/${_currentDay.month} est la ${randomDay.title} ?";
         }
         _options = ['Vrai', 'Faux'];
      } else {
        _options = _generateOptions();
      }
    });
  }

  List<String> _generateOptions() {
    List<String> options = [];
    String correct = widget.mode == QuizMode.guessDate
        ? '${_currentDay.day}/${_currentDay.month}'
        : _currentDay.title;
    options.add(correct);

    while (options.length < 4) {
      InternationalDay randomDay = internationalDaysData[_random.nextInt(internationalDaysData.length)];
      String option = widget.mode == QuizMode.guessDate
          ? '${randomDay.day}/${randomDay.month}'
          : randomDay.title;
      
      if (!options.contains(option)) {
        options.add(option);
      }
    }
    options.shuffle();
    return options;
  }

  void _handleAnswer(String answer) {
    if (_answered) return;

    bool isCorrect = false;
    String correctInfo = "C'était : ${_currentDay.day}/${_currentDay.month} - ${_currentDay.title}";

    if (widget.mode == QuizMode.trueFalse) {
        if (_isQuestionCorrect && answer == 'Vrai') isCorrect = true;
        if (!_isQuestionCorrect && answer == 'Faux') isCorrect = true;
    } else {
      String correct = widget.mode == QuizMode.guessDate
        ? '${_currentDay.day}/${_currentDay.month}'
        : _currentDay.title;
      isCorrect = answer == correct;
    }

    setState(() {
      _answered = true;
      if (isCorrect) {
        _score++;
        _feedback = "Correct !";
      } else {
        _feedback = "Faux ! $correctInfo"; // Simplified feedback
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayQuestion = '';
    
    if (widget.mode == QuizMode.guessDate) {
      displayQuestion = "Quelle est la date de : ${_currentDay.title} ?";
    } else if (widget.mode == QuizMode.guessTitle) {
      displayQuestion = "Qu'est-ce qui est célébré le ${_currentDay.day}/${_currentDay.month} ?";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Score: $_score'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onExit),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             const Spacer(),
             Text(widget.mode == QuizMode.trueFalse ? _tfQuestionText : displayQuestion, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 20),
             if (_feedback != null) Text(_feedback!, 
                 textAlign: TextAlign.center,
                 style: TextStyle(fontSize: 18, color: _feedback!.startsWith('C') ? Colors.green : Colors.red)),
             const Spacer(),
             ..._options.map((option) => 
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8.0),
                 child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: _answered ? null : () => _handleAnswer(option),
                     child: Text(option),
                   ),
                 ),
               )
             ).toList(),
             if (_answered)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(onPressed: _nextQuestion, child: const Text('Suivant')),
                ),
             const Spacer(),
          ],
        ),
      ),
    );
  }
}
