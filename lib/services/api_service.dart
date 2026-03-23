import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService extends ChangeNotifier {
  static const String _baseUrl = 'http://localhost:7891';

  List<Agent> _agents = [];
  List<Edict> _tasks = [];
  Metrics? _metrics;
  List<Map> _history = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;

  List<Agent> get agents => _agents;
  List<Agent> get activeAgents => _agents.where((a) => a.isActive).toList();
  List<Agent> get idleAgents => _agents.where((a) => a.isIdle).toList();
  List<Edict> get tasks => _tasks;
  List<Edict> get activeTasks => _tasks.where((t) => !t.isDone).toList();
  List<Edict> get doneTasks => _tasks.where((t) => t.isDone).toList();
  Metrics? get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetch => _lastFetch;

  double get totalCostCny => _agents.fold(0, (sum, a) => sum + a.costCny);
  int get totalTokens => _agents.fold(0, (sum, a) => sum + a.tokensTotal);
  int get totalMessages => _agents.fold(0, (sum, a) => sum + a.messages);

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await http.get(Uri.parse('$_baseUrl/api/live-status')).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        _agents = (data['officials'] as List?)
            ?.map((a) => Agent.fromJson(a)).toList() ?? [];

        _tasks = (data['tasks'] as List?)
            ?.map((t) => Edict.fromJson(t)).toList() ?? [];

        _metrics = Metrics.fromJson(data['metrics'] ?? {});

        _history = (data['history'] as List?)?.cast<Map>() ?? [];

        _lastFetch = DateTime.now();
        _error = null;
      } else {
        _error = '服务器响应错误: ${resp.statusCode}';
      }
    } catch (e) {
      _error = '连接失败: $e\n\n请确保三省六部看板服务在运行';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setModel(String agentId, String model) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/set-model'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'agentId': agentId, 'model': model}),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        await fetchAll();
      }
    } catch (e) {
      _error = '切换模型失败: $e';
      notifyListeners();
    }
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String formatTime(DateTime? t) {
    if (t == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return _fmtTime(t);
  }
}
