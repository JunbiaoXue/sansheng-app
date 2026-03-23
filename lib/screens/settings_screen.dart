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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ModelPickerSheet(
        agentId: agentId,
        agentName: agentName,
        currentModel: currentModel,
        onChanged: () {
          // Refresh the parent state
          context.read<ApiService>().fetchAll();
        },
      ),
    );
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}

/// 模型选择器弹窗（支持滚动 + 自由输入）
class ModelPickerSheet extends StatefulWidget {
  final String agentId;
  final String agentName;
  final String currentModel;
  final VoidCallback onChanged;

  const ModelPickerSheet({
    super.key,
    required this.agentId,
    required this.agentName,
    required this.currentModel,
    required this.onChanged,
  });

  @override
  State<ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<ModelPickerSheet> {
  late TextEditingController _controller;
  bool _isCustomMode = false;
  bool _isLoading = false;
  String? _error;

  // 示例模型列表
  static const _exampleModels = [
    'infini-coding/glm-5',
    'infini-coding/glm-4.7',
    'infini-coding/deepseek-v3.2',
    'infini-coding/deepseek-v3.2-thinking',
    'infini-coding/minimax-m2.5',
    'infini-coding/minimax-m2.7',
    'infini-coding/kimi-k2.5',
    'infini-coding/minimax-m2.1',
    'minimax-portal/MiniMax-M2.5',
    'minimax-portal/MiniMax-M2.5-highspeed',
    'minimax-portal/MiniMax-M2.5-Lightning',
    'minimax/MiniMax-M2.5',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentModel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _applyModel(String model) async {
    if (model.trim().isEmpty) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final api = context.read<ApiService>();
      await api.setModel(widget.agentId, model.trim());
      widget.onChanged();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _isLoading = false; _error = '切换失败: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Expanded(
                child: Text(
                  '切换 ${widget.agentName} 模型',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _isCustomMode = !_isCustomMode),
                icon: Icon(_isCustomMode ? Icons.list : Icons.edit, size: 16),
                label: Text(_isCustomMode ? '快捷选择' : '自由输入'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isCustomMode) ...[
            // 自由输入模式
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '模型名称',
                hintText: '例如: infini-coding/glm-5',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              onSubmitted: _applyModel,
            ),
            const SizedBox(height: 12),

            // 示例模型（可点击填入）
            const Text('示例模型（点击填入）:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _exampleModels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final m = _exampleModels[i];
                  final short = m.split('/').last;
                  return ActionChip(
                    label: Text(short, style: const TextStyle(fontSize: 12)),
                    backgroundColor: m == widget.currentModel
                        ? Colors.amber.shade100
                        : Colors.grey.shade100,
                    onPressed: () {
                      _controller.text = m;
                      _applyModel(m);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 完整列表（竖向滚动）
            const Text('完整列表（竖向滚动）:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListView.separated(
                itemCount: _exampleModels.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final m = _exampleModels[i];
                  final isSelected = m == widget.currentModel;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(m, style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.amber.shade700 : null,
                    )),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.amber, size: 18)
                        : const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _applyModel(m),
                  );
                },
              ),
            ),
          ] else ...[
            // 快捷选择模式（竖向滚动列表）
            const Text('点击选择一个模型:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: ListView.separated(
                itemCount: _exampleModels.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final m = _exampleModels[i];
                  final isSelected = m == widget.currentModel;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                    title: Text(
                      m.split('/').last,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.amber.shade700 : null,
                      ),
                    ),
                    subtitle: Text(m, style: const TextStyle(fontSize: 11)),
                    onTap: () => _applyModel(m),
                  );
                },
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
            ),
          ],

          if (_isLoading) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _applyModel(_controller.text),
              child: const Text('确认切换'),
            ),
          ),
        ],
      ),
    );
  }
}
