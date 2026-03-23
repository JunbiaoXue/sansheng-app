import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();

    return Scaffold(
      appBar: AppBar(title: const Text('📊 数据统计'), centerTitle: true),
      body: api.agents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              _buildCostChart(api),
              const SizedBox(height: 16),
              _buildTokenChart(api),
              const SizedBox(height: 16),
              _buildMeritChart(api),
              const SizedBox(height: 16),
              _buildRankingTable(api),
            ]),
    );
  }

  Widget _buildCostChart(ApiService api) {
    final sorted = List<Agent>.from(api.agents)
      ..sort((a, b) => b.costCny.compareTo(a.costCny));
    final top5 = sorted.take(5).toList();
    if (top5.isEmpty || top5.every((a) => a.costCny == 0)) {
      return Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(
        child: Text('暂无费用数据', style: TextStyle(color: Colors.grey[400])))));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💰 费用排行 (¥)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (top5.map((a) => a.costCny).reduce((a, b) => a > b ? a : b) * 1.3).clamp(1, double.infinity),
                  barGroups: top5.asMap().entries.map((e) =>
                    BarChartGroupData(
                      x: e.key,
                      barRods: [BarChartRodData(
                        toY: e.value.costCny,
                        color: _costColor(e.value.costCny),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      )],
                    )).toList(),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text('¥${v.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                          top5[v.toInt()].emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenChart(ApiService api) {
    final sorted = List<Agent>.from(api.agents)
      ..sort((a, b) => b.tokensTotal.compareTo(a.tokensTotal));
    final data = sorted.where((a) => a.tokensTotal > 0).take(5).toList();
    if (data.isEmpty) {
      return Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(
        child: Text('暂无Token数据', style: TextStyle(color: Colors.grey[400])))));
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🧠 Token消耗分布', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: data.asMap().entries.map((e) =>
                          PieChartSectionData(
                            value: e.value.tokensTotal.toDouble(),
                            title: _fmtTokens(e.value.tokensTotal),
                            color: colors[e.key % colors.length],
                            radius: 60,
                            titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          )).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.asMap().entries.map((e) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(
                            color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 6),
                          Text('${e.value.emoji} ${e.value.label}', style: const TextStyle(fontSize: 12)),
                        ]),
                      )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeritChart(ApiService api) {
    final sorted = List<Agent>.from(api.agents)
      ..sort((a, b) => b.meritScore.compareTo(a.meritScore));
    final top5 = sorted.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏆 功德值排行', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...top5.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Text(a.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    LinearProgressIndicator(
                      value: top5.first.meritScore > 0 ? a.meritScore / top5.first.meritScore : 0,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(_meritColor(a.meritRank)),
                    ),
                  ],
                )),
                const SizedBox(width: 10),
                Text('${a.meritScore}分', style: TextStyle(fontWeight: FontWeight.bold, color: _meritColor(a.meritRank))),
                Text(' #${a.meritRank}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingTable(ApiService api) {
    final sorted = List<Agent>.from(api.agents)
      ..sort((a, b) => b.meritScore.compareTo(a.meritScore));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📋 Agent总览表', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                  children: const [
                    Padding(padding: EdgeInsets.all(8), child: Text('排名', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8), child: Text('消息', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8), child: Text('费用', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8), child: Text('状态', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                ...sorted.map((a) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text('#${a.meritRank}', style: TextStyle(color: _meritColor(a.meritRank), fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${a.emoji} ${a.label}', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('${a.messages}', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Text('¥${a.costCny.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12))),
                    Padding(padding: const EdgeInsets.all(8), child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: a.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(a.isActive ? '活跃' : '空闲', style: TextStyle(fontSize: 10, color: a.isActive ? Colors.green : Colors.grey)),
                    )),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _costColor(double cost) {
    if (cost > 10) return Colors.red;
    if (cost > 5) return Colors.orange;
    if (cost > 1) return Colors.amber;
    return Colors.green;
  }

  Color _meritColor(int rank) {
    if (rank == 1) return Colors.amber[700]!;
    if (rank == 2) return Colors.grey[600]!;
    if (rank == 3) return Colors.brown[400]!;
    return Colors.blue;
  }

  String _fmtTokens(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}
