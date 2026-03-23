import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 任务看板'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: '全部 (${api.tasks.length})'),
            Tab(text: '进行中 (${api.tasks.where((t) => t.state == 'Doing').length})'),
            Tab(text: '已完成 (${api.tasks.where((t) => t.state == 'Done').length})'),
            const Tab(text: '已阻塞'),
          ],
        ),
      ),
      body: api.isLoading && api.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(api.tasks),
                _buildTaskList(api.tasks.where((t) => t.state == 'Doing').toList()),
                _buildTaskList(api.tasks.where((t) => t.state == 'Done').toList()),
                _buildTaskList(api.tasks.where((t) => t.state == 'Blocked').toList()),
              ],
            ),
    );
  }

  Widget _buildTaskList(List<Edict> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('暂无任务', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ApiService>().fetchAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tasks.length,
        itemBuilder: (ctx, i) => _buildTaskCard(tasks[i]),
      ),
    );
  }

  Widget _buildTaskCard(Edict task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showTaskDetail(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _stateColor(task.state).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(task.id, style: TextStyle(fontSize: 11, color: _stateColor(task.state), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(task.org ?? '未知', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                ),
                const Spacer(),
                Icon(_stateIcon(task.state), size: 18, color: _stateColor(task.state)),
              ]),
              const SizedBox(height: 8),
              Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              if (task.now != null) ...[
                const SizedBox(height: 4),
                Text(task.now!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
              if (task.todos != null && task.todos!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: task.todos!.where((t) => t.isCompleted).length / task.todos!.length,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(_stateColor(task.state)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${task.todos!.where((t) => t.isCompleted).length}/${task.todos!.length}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
              if (task.flowLog != null && task.flowLog!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.route, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${task.flowLog!.length}条流程记录', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const Spacer(),
                  Text(_fmtDate(task.updatedAt), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetail(Edict task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _stateColor(task.state).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(task.state, style: TextStyle(color: _stateColor(task.state), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(task.id, style: TextStyle(color: Colors.grey[500], fontSize: 12))),
            ]),
            const SizedBox(height: 12),
            Text(task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (task.now != null) ...[
              const SizedBox(height: 8),
              Text(task.now!, style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 16),
            if (task.todos != null && task.todos!.isNotEmpty) ...[
              const Text('📋 子任务', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...task.todos!.map((t) => ListTile(
                dense: true,
                leading: Icon(
                  t.isCompleted ? Icons.check_circle : (t.isInProgress ? Icons.pending : Icons.circle_outlined),
                  color: t.isCompleted ? Colors.green : (t.isInProgress ? Colors.orange : Colors.grey),
                  size: 20,
                ),
                title: Text(t.title, style: TextStyle(
                  fontSize: 14,
                  decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                  color: t.isCompleted ? Colors.grey : null,
                )),
                contentPadding: EdgeInsets.zero,
              )),
              const SizedBox(height: 16),
            ],
            if (task.flowLog != null && task.flowLog!.isNotEmpty) ...[
              const Text('📜 流程记录', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...task.flowLog!.reversed.take(10).map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 8, height: 8, margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(text: TextSpan(children: [
                        TextSpan(text: f.from, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                        const TextSpan(text: ' → ', style: TextStyle(color: Colors.grey)),
                        TextSpan(text: f.to, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      ])),
                      Text(f.remark, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text(_fmtDateTime(f.at), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                    ],
                  )),
                ]),
              )),
            ],
            if (task.output != null && task.output!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('📦 成果输出', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Text(task.output!, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'Done': return Colors.green;
      case 'Doing': return Colors.orange;
      case 'Blocked': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _stateIcon(String state) {
    switch (state) {
      case 'Done': return Icons.check_circle;
      case 'Doing': return Icons.pending;
      case 'Blocked': return Icons.block;
      default: return Icons.help;
    }
  }

  String _fmtDate(DateTime? t) {
    if (t == null) return '';
    return '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _fmtDateTime(DateTime t) {
    return '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
