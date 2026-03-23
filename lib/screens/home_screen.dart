import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤴 三省六部'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: api.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: api.isLoading ? null : () => api.fetchAll(),
          ),
        ],
      ),
      body: api.isLoading && api.agents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : api.error != null && api.agents.isEmpty
              ? _buildError(api)
              : RefreshIndicator(
                  onRefresh: () => api.fetchAll(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatsRow(api),
                      const SizedBox(height: 16),
                      _buildMetricsCard(api),
                      const SizedBox(height: 16),
                      _buildActiveTasks(api),
                      const SizedBox(height: 16),
                      _buildAgentsList(api),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(ApiService api) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(api.error ?? '连接失败', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => api.fetchAll(),
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ApiService api) {
    return Row(
      children: [
        _statCard('活跃', '${api.activeAgents.length}', Icons.circle, Colors.green, api.activeAgents.isNotEmpty),
        _statCard('空闲', '${api.idleAgents.length}', Icons.circle_outlined, Colors.grey, true),
        _statCard('任务进行中', '${api.activeTasks.length}', Icons.pending, Colors.orange, true),
        _statCard('已完成', '${api.doneTasks.length}', Icons.check_circle, Colors.blue, true),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool enabled) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: enabled ? color : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: enabled ? color : Colors.grey)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsCard(ApiService api) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.insights, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('今日概况', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const Divider(),
            _metricRow('Agent总数', '${api.metrics?.officialCount ?? 0}', Icons.groups),
            _metricRow('今日完成任务', '${api.metrics?.todayDone ?? 0}', Icons.check_circle_outline),
            _metricRow('总完成任务', '${api.metrics?.totalDone ?? 0}', Icons.done_all),
            _metricRow('总消息数', '${api.totalMessages}', Icons.chat_bubble_outline),
            _metricRow('总Token消耗', '${_fmtTokens(api.totalTokens)}', Icons.memory),
            _metricRow('总费用', '¥${api.totalCostCny.toStringAsFixed(2)}', Icons.attach_money, valueColor: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
      ]),
    );
  }

  Widget _buildActiveTasks(ApiService api) {
    if (api.activeTasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🔄 进行中的任务', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...api.activeTasks.take(3).map((t) => Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _stateColor(t.state).withValues(alpha: 0.15),
              child: Icon(_stateIcon(t.state), color: _stateColor(t.state), size: 20),
            ),
            title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
            subtitle: Text('${t.org ?? ''} · ${t.now ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _stateColor(t.state).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(_stateLabel(t.state), style: TextStyle(fontSize: 11, color: _stateColor(t.state))),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildAgentsList(ApiService api) {
    final sorted = List<Agent>.from(api.agents)..sort((a, b) => b.meritScore.compareTo(a.meritScore));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('👥 Agent列表', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...sorted.map((a) => _buildAgentCard(a)),
      ],
    );
  }

  Widget _buildAgentCard(Agent a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: a.isActive ? Colors.green.shade50 : Colors.grey.shade100,
          child: Text(a.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(a.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${a.role} · ${a.rank}', style: const TextStyle(fontSize: 12)),
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: a.isActive ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(a.heartbeatLabel, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ]),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('功 ${a.meritScore}', style: TextStyle(fontSize: 12, color: Colors.amber[700], fontWeight: FontWeight.bold)),
            Text('排名 #${a.meritRank}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _agentStatRow('会话', '${a.sessions}', Icons.chat),
                _agentStatRow('消息', '${a.messages}', Icons.message),
                _agentStatRow('Token', _fmtTokens(a.tokensTotal), Icons.memory),
                _agentStatRow('费用', '¥${a.costCny.toStringAsFixed(2)}', Icons.paid, valueColor: Colors.orange),
                _agentStatRow('模型', a.modelShort, Icons.smart_toy),
                _agentStatRow('完成任务', '${a.tasksDone}', Icons.done),
                _agentStatRow('参与任务', '${a.flowParticipations}', Icons.handshake),
                _agentStatRow('最近活跃', a.formatTime(a.lastActive), Icons.access_time),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _agentStatRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: valueColor)),
      ]),
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

  String _stateLabel(String state) {
    switch (state) {
      case 'Done': return '已完成';
      case 'Doing': return '进行中';
      case 'Blocked': return '已阻塞';
      default: return state;
    }
  }

  String _fmtTokens(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
