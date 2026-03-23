import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();

    if (api.isLoading && api.tasks.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Build unified timeline from all agents and tasks
    final entries = <_TimelineEntry>[];

    for (final agent in api.agents) {
      if (agent.lastActive != null) {
        entries.add(_TimelineEntry(
          time: agent.lastActive!,
          title: '${agent.emoji} ${agent.label}',
          subtitle: agent.heartbeatLabel,
          type: 'agent',
          icon: agent.isActive ? Icons.circle : Icons.circle_outlined,
          color: agent.isActive ? Colors.green : Colors.grey,
        ));
      }
      for (final edict in agent.participatedEdicts) {
        if (edict.updatedAt != null) {
          entries.add(_TimelineEntry(
            time: edict.updatedAt!,
            title: '${edict.title}',
            subtitle: '${agent.emoji} ${agent.label} 参与 · ${edict.state}',
            type: 'task',
            icon: _stateIcon(edict.state),
            color: _stateColor(edict.state),
          ));
        }
      }
    }

    for (final task in api.tasks) {
      if (task.updatedAt != null) {
        entries.add(_TimelineEntry(
          time: task.updatedAt!,
          title: '${task.title}',
          subtitle: '${task.org ?? ''} · ${task.state}',
          type: 'task',
          icon: _stateIcon(task.state),
          color: _stateColor(task.state),
        ));
      }
    }

    entries.sort((a, b) => b.time.compareTo(a.time));

    return Scaffold(
      appBar: AppBar(title: const Text('⚡ 实时动态'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => api.fetchAll(),
        child: api.tasks.isEmpty
            ? const Center(child: Text('暂无动态'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: entries.length,
                itemBuilder: (ctx, i) {
                  final e = entries[i];
                  final showDate = i == 0 || !_sameDay(entries[i - 1].time, e.time);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDate)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _dateLabel(e.time),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: e.color.withOpacity(0.1),
                            child: Icon(e.icon, color: e.color, size: 18),
                          ),
                          title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(e.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          trailing: Text(_timeAgo(e.time), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${t.month}/${t.day}';
  }

  String _dateLabel(DateTime t) {
    final now = DateTime.now();
    if (_sameDay(now, t)) return '今天';
    final yesterday = now.subtract(const Duration(days: 1));
    if (_sameDay(yesterday, t)) return '昨天';
    return '${t.month}月${t.day}日';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
}

class _TimelineEntry {
  final DateTime time;
  final String title;
  final String subtitle;
  final String type;
  final IconData icon;
  final Color color;

  _TimelineEntry({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    required this.color,
  });
}
