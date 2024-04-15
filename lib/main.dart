// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart' as record;
import 'package:audioplayers/audioplayers.dart' as audioPlayer;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: SpeechRecognizerScreen(),
    );
  }
}

class SpeechRecognizerScreen extends StatefulWidget {
  const SpeechRecognizerScreen({super.key});

  @override
  State<SpeechRecognizerScreen> createState() => _SpeechRecognizerScreenState();
}

class _SpeechRecognizerScreenState extends State<SpeechRecognizerScreen> {
  final Map<String, HighlightedWord> _highlights = {
    'stop': HighlightedWord(
      onTap: () => print('stop'),
      textStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
    ),
  };

  late record.Record _audioRecord;
  late audioPlayer.AudioPlayer _audioPlayer;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isRecording = false;
  String _audioPath = '';
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;

  @override
  void initState() {
    _speech = stt.SpeechToText();
    _audioPlayer = audioPlayer.AudioPlayer();
    _audioRecord = record.Record();
    super.initState();
  }

  @override
  void dispose() {
    _audioRecord.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Speech Recognizer\nConfidence: ${(_confidence * 100.0).toStringAsFixed(1)}%'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SingleChildScrollView(
              reverse: true,
              child: Container(
                padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
                child: TextHighlight(
                  text: _text,
                  words: _highlights,
                  textStyle: const TextStyle(
                    fontSize: 15.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 55,
            ),
            ElevatedButton(
                onPressed: _listen, child: const Text('Start Recording')),
            ElevatedButton(
                onPressed: stopRecording, child: const Text('Stop Recording')),
            if (_audioPath != '')
              ElevatedButton(
                  onPressed: playRecording,
                  child: const Text('Play Recording and Show Text')),
            // ElevatedButton(
            //     onPressed: pausePlaying, child: const Text('Pause Playing')),
            // ElevatedButton(
            //     onPressed: resumePlaying, child: const Text('Resume Playing')),
            ElevatedButton(
                onPressed: disposePlaying, child: const Text('Clear Playing'))
          ],
        ),
      ),
    );
  }

  Future<void> disposePlaying() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      print('Error disposing the playing : $e');
    }
  }

  Future<void> pausePlaying() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing the playing : $e');
    }
  }

  Future<void> resumePlaying() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      print('Error resuming the playing : $e');
    }
  }

  Future<void> playRecording() async {
    try {
      audioPlayer.Source urlSource = audioPlayer.UrlSource(_audioPath);
      await _audioPlayer.play(urlSource);
    } catch (e) {
      print('Error playing recording : $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecord.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path!;
        if (_audioPath?.isNotEmpty ?? false) {
          print(path ?? 'Error');
        }
      });
    } catch (e) {
      print('Error Stopping record : $e');
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      _audioRecord.start();
      setState(() => _isRecording = true);
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
            if (_text.contains('stop')) {
              _isListening = false;
              stopRecording();
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}
