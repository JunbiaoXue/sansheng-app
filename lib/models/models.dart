// ============ Agent Model ============
class Agent {
  final String id;
  final String label;
  final String role;
  final String emoji;
  final String rank;
  final String model;
  final String modelShort;
  final int sessions;
  final int tokensIn;
  final int tokensOut;
  final int cacheRead;
  final int cacheWrite;
  final int tokensTotal;
  final int messages;
  final double costUsd;
  final double costCny;
  final DateTime? lastActive;
  final String heartbeatStatus;
  final String heartbeatLabel;
  final int? heartbeatAgeSec;
  final int tasksDone;
  final int tasksActive;
  final int flowParticipations;
  final int meritScore;
  final int meritRank;
  final List<Edict> participatedEdicts;

  Agent({
    required this.id, required this.label, required this.role,
    required this.emoji, required this.rank, required this.model,
    required this.modelShort, required this.sessions,
    required this.tokensIn, required this.tokensOut,
    required this.cacheRead, required this.cacheWrite,
    required this.tokensTotal, required this.messages,
    required this.costUsd, required this.costCny,
    this.lastActive, required this.heartbeatStatus,
    required this.heartbeatLabel, this.heartbeatAgeSec,
    required this.tasksDone, required this.tasksActive,
    required this.flowParticipations, required this.meritScore,
    required this.meritRank, required this.participatedEdicts,
  });

  factory Agent.fromJson(Map<String, dynamic> json) => Agent(
    id: json['id'] ?? '',
    label: json['label'] ?? '',
    role: json['role'] ?? '',
    emoji: json['emoji'] ?? '🤖',
    rank: json['rank'] ?? '',
    model: json['model'] ?? '',
    modelShort: json['model_short'] ?? '',
    sessions: json['sessions'] ?? 0,
    tokensIn: json['tokens_in'] ?? 0,
    tokensOut: json['tokens_out'] ?? 0,
    cacheRead: json['cache_read'] ?? 0,
    cacheWrite: json['cache_write'] ?? 0,
    tokensTotal: json['tokens_total'] ?? 0,
    messages: json['messages'] ?? 0,
    costUsd: (json['cost_usd'] ?? 0).toDouble(),
    costCny: (json['cost_cny'] ?? 0).toDouble(),
    lastActive: json['last_active'] != null ? DateTime.tryParse(json['last_active']) : null,
    heartbeatStatus: (json['heartbeat']?['status'] ?? 'idle'),
    heartbeatLabel: (json['heartbeat']?['label'] ?? '⚪ 待命'),
    heartbeatAgeSec: json['heartbeat']?['ageSec'],
    tasksDone: json['tasks_done'] ?? 0,
    tasksActive: json['tasks_active'] ?? 0,
    flowParticipations: json['flow_participations'] ?? 0,
    meritScore: json['merit_score'] ?? 0,
    meritRank: json['merit_rank'] ?? 99,
    participatedEdicts: (json['participated_edicts'] as List? ?? [])
        .map((e) => Edict.fromJson(e)).toList(),
  );

  bool get isActive => heartbeatStatus == 'active';
  bool get isIdle => heartbeatStatus == 'idle';
}

// ============ Edict / Task Model ============
class Edict {
  final String id;
  final String title;
  final String? official;
  final String? org;
  final String state;
  final String? now;
  final String? eta;
  final String? block;
  final String? output;
  final List<FlowEntry>? flowLog;
  final List<TodoItem>? todos;
  final DateTime? updatedAt;
  final List<ProgressEntry>? progressLog;

  Edict({
    required this.id, required this.title, this.official,
    this.org, required this.state, this.now, this.eta,
    this.block, this.output, this.flowLog, this.todos,
    this.updatedAt, this.progressLog,
  });

  factory Edict.fromJson(Map<String, dynamic> json) => Edict(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    official: json['official'],
    org: json['org'],
    state: json['state'] ?? '',
    now: json['now'],
    eta: json['eta'],
    block: json['block'],
    output: json['output'],
    flowLog: (json['flow_log'] as List?)
        ?.map((e) => FlowEntry.fromJson(e)).toList(),
    todos: (json['todos'] as List?)
        ?.map((e) => TodoItem.fromJson(e)).toList(),
    updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    progressLog: (json['progress_log'] as List?)
        ?.map((e) => ProgressEntry.fromJson(e)).toList(),
  );

  bool get isDone => state == 'Done';
  bool get isDoing => state == 'Doing';
  bool get isBlocked => state == 'Blocked';
}

class FlowEntry {
  final DateTime at;
  final String from;
  final String to;
  final String remark;

  FlowEntry({required this.at, required this.from, required this.to, required this.remark});
  factory FlowEntry.fromJson(Map<String, dynamic> json) => FlowEntry(
    at: DateTime.parse(json['at']),
    from: json['from'] ?? '',
    to: json['to'] ?? '',
    remark: json['remark'] ?? '',
  );
}

class TodoItem {
  final String id;
  final String title;
  final String status;

  TodoItem({required this.id, required this.title, required this.status});
  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    status: json['status'] ?? '',
  );

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in-progress';
}

class ProgressEntry {
  final DateTime at;
  final String agent;
  final String agentLabel;
  final String text;
  final List<TodoItem> todos;
  final String state;
  final String org;

  ProgressEntry({
    required this.at, required this.agent, required this.agentLabel,
    required this.text, required this.todos, required this.state, required this.org,
  });
  factory ProgressEntry.fromJson(Map<String, dynamic> json) => ProgressEntry(
    at: DateTime.parse(json['at']),
    agent: json['agent'] ?? '',
    agentLabel: json['agentLabel'] ?? '',
    text: json['text'] ?? '',
    todos: (json['todos'] as List?)?.map((e) => TodoItem.fromJson(e)).toList() ?? [],
    state: json['state'] ?? '',
    org: json['org'] ?? '',
  );
}

// ============ Metrics ============
class Metrics {
  final int officialCount;
  final int todayDone;
  final int totalDone;
  final int inProgress;
  final int blocked;

  Metrics({required this.officialCount, required this.todayDone,
    required this.totalDone, required this.inProgress, required this.blocked});

  factory Metrics.fromJson(Map<String, dynamic> json) => Metrics(
    officialCount: json['officialCount'] ?? 0,
    todayDone: json['todayDone'] ?? 0,
    totalDone: json['totalDone'] ?? 0,
    inProgress: json['inProgress'] ?? 0,
    blocked: json['blocked'] ?? 0,
  );
}
