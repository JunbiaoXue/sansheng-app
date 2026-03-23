import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _serverUrl = 'http://118.145.117.25:7891';
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = _serverUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ 设置'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 服务器配置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.cloud_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('服务器配置', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Dashboard 服务器地址',
                      border: OutlineInputBorder(),
                      hintText: 'http://118.145.117.25:7891',
                      prefixIcon: Icon(Icons.link),
                    ),
                    onSubmitted: (v) => setState(() => _serverUrl = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (api.lastFetch != null) ...[
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('最后同步: ${_fmtTime(api.lastFetch!)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ] else
                        const Text('未连接', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: api.isLoading ? null : () => api.fetchAll(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('刷新'),
                      ),
                    ],
                  ),
                  if (api.error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(api.error!, style: TextStyle(fontSize: 12, color: Colors.red[700])),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 自动刷新
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.auto_awesome),
              title: const Text('自动刷新'),
              subtitle: const Text('每5分钟自动更新数据'),
              value: true,
              onChanged: (v) {
                // TODO: implement auto-refresh
              },
            ),
          ),
          const SizedBox(height: 12),

          // Agent 管理
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(Icons.smart_toy, size: 20),
                    SizedBox(width: 8),
                    Text('Agent 模型管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                ),
                ...api.agents.map((a) => ListTile(
                  leading: Text(a.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(a.label),
                  subtitle: Text('当前: ${a.modelShort}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showModelPicker(a.id, a.label, a.model),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 关于
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('版本'),
                  trailing: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('三省六部管理系统'),
                  subtitle: const Text('多Agent协作管理平台'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Dashboard API'),
                  subtitle: Text(_serverUrl, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('三省六部 App v1.0.0', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showModelPicker(String agentId, String agentName, String currentModel) {
    final models = [
      'infini-coding/glm-5',
      'infini-coding/glm-4.7',
      'infini-coding/deepseek-v3.2',
      'infini-coding/deepseek-v3.2-thinking',
      'infini-coding/minimax-m2.7',
      'infini-coding/minimax-m2.5',
      'infini-coding/kimi-k2.5',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('切换 ${agentName} 模型', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...models.map((m) => ListTile(
              leading: Radio<String>(
                value: m,
                groupValue: currentModel,
                onChanged: (v) {
                  Navigator.pop(ctx);
                  if (v != null) {
                    context.read<ApiService>().setModel(agentId, v);
                  }
                },
              ),
              title: Text(m.split('/').last),
              subtitle: Text(m),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ApiService>().setModel(agentId, m);
              },
            )),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}
