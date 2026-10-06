import 'package:flutter/material.dart';

import '../../../authentication/data/auth_api.dart';
import '../../../authentication/data/auth_session.dart';
import '../../../authentication/presentation/pages/login_page.dart';

class GoalDetailPage extends StatefulWidget {
  const GoalDetailPage({
    super.key,
    required this.token,
    required this.studentId,
    required this.goal,
  });
  final String token;
  final String studentId;
  final GrowthGoalData goal;

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  late GrowthGoalData _goal = widget.goal;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final goal = await AuthApi.getTeacherStudentGoal(
        token: widget.token,
        studentId: widget.studentId,
        goalId: widget.goal.id,
      );
      if (mounted) {
        setState(() {
          _goal = goal;
          _loading = false;
        });
      }
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await _signOut();
        return;
      }
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Please check your connection and try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await AuthSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginPage(initialRole: 1)),
      (_) => false,
    );
  }

  Future<void> _updateProgress() async {
    final draft = await showModalBottomSheet<_ProgressDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProgressUpdateSheet(goal: _goal),
    );
    if (draft == null || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthApi.updateTeacherStudentGoalProgress(
        token: widget.token,
        studentId: widget.studentId,
        goalId: _goal.id,
        progress: draft.progress,
        note: draft.note,
      );
      if (mounted) await _load();
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await _signOut();
        return;
      }
      if (mounted) {
        setState(() {
          _error = error.message.isEmpty
              ? 'Could not update progress.'
              : error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not update progress. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _complete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete this goal?'),
        content: const Text(
          'Mark this goal as completed? It will move to the Completed tab.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF149B78),
            ),
            child: const Text('Complete Goal'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthApi.completeTeacherStudentGoal(
        token: widget.token,
        studentId: widget.studentId,
        goalId: _goal.id,
      );
      if (mounted) await _load();
    } on AuthApiException catch (error) {
      if (error.statusCode == 401) {
        await _signOut();
        return;
      }
      if (mounted) {
        setState(() {
          _error = error.message.isEmpty
              ? 'Could not complete this goal.'
              : error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not complete this goal. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8FC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF5F8FC),
      foregroundColor: const Color(0xFF203454),
      title: const Text(
        'Goal Details',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          onPressed: _load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_loading && _goal.history.isEmpty)
              const _GoalDetailSurface(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF149B78),
                    ),
                  ),
                ),
              )
            else if (_error != null && _goal.history.isEmpty)
              _DetailError(message: _error!, onRetry: _load)
            else ...[
              _GoalDetailSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _goal.title,
                            style: const TextStyle(
                              color: Color(0xFF203454),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _GoalStatus(
                          label: _goal.status == 'completed'
                              ? 'Completed'
                              : 'Active',
                          completed: _goal.status == 'completed',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _goal.category,
                      style: const TextStyle(
                        color: Color(0xFF78859B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_goal.description.isNotEmpty) ...[
                      const SizedBox(height: 13),
                      Text(
                        _goal.description,
                        style: const TextStyle(
                          color: Color(0xFF40516A),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text(
                          'Current progress',
                          style: TextStyle(
                            color: Color(0xFF586A82),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_goal.currentProgress}%',
                          style: const TextStyle(
                            color: Color(0xFF149B78),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: (_goal.currentProgress / 100).clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEAF0F4),
                        color: const Color(0xFF149B78),
                      ),
                    ),
                    if (_goal.currentValue != null &&
                        _goal.targetValue != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        '${_formatNumber(_goal.currentValue!)} / ${_formatNumber(_goal.targetValue!)}',
                        style: const TextStyle(
                          color: Color(0xFF78859B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 11),
              _GoalDetailSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DetailHeading('Goal details'),
                    const SizedBox(height: 11),
                    _InfoRow(label: 'Created', value: _date(_goal.createdAt)),
                    _InfoRow(
                      label: 'Start date',
                      value: _date(_goal.startDate),
                    ),
                    if (_goal.reviewDate != null)
                      _InfoRow(
                        label: 'Review date',
                        value: _date(_goal.reviewDate!),
                      ),
                    if (_goal.completedAt != null)
                      _InfoRow(
                        label: 'Completed',
                        value: _date(_goal.completedAt!),
                      ),
                    _InfoRow(
                      label: 'Last updated',
                      value: _date(_goal.updatedAt),
                    ),
                    if (_goal.teacherNote.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const _DetailHeading('Private teacher note'),
                      const SizedBox(height: 5),
                      Text(
                        _goal.teacherNote,
                        style: const TextStyle(
                          color: Color(0xFF40516A),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Progress history',
                style: TextStyle(
                  color: Color(0xFF203454),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              if (_goal.history.isEmpty)
                const _GoalDetailSurface(
                  child: Text(
                    'No progress updates yet.',
                    style: TextStyle(color: Color(0xFF78859B), fontSize: 12),
                  ),
                )
              else
                _GoalDetailSurface(
                  child: Column(
                    children: [
                      for (var index = 0; index < _goal.history.length; index++)
                        _HistoryRow(
                          entry: _goal.history[index],
                          isLast: index == _goal.history.length - 1,
                        ),
                    ],
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _DetailError(message: _error!, onRetry: _load),
              ],
            ],
          ],
        ),
      ),
    ),
    bottomNavigationBar: _goal.status == 'active'
        ? SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _complete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF168064),
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: Color(0xFFBFDCD3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Complete Goal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _updateProgress,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF149B78),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update Progress',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : null,
  );
}

class _ProgressDraft {
  const _ProgressDraft(this.progress, this.note);
  final int progress;
  final String note;
}

class _ProgressUpdateSheet extends StatefulWidget {
  const _ProgressUpdateSheet({required this.goal});
  final GrowthGoalData goal;
  @override
  State<_ProgressUpdateSheet> createState() => _ProgressUpdateSheetState();
}

class _ProgressUpdateSheetState extends State<_ProgressUpdateSheet> {
  late double _progress = widget.goal.currentProgress.toDouble();
  final _note = TextEditingController();
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update Progress',
            style: TextStyle(
              color: Color(0xFF203454),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.goal.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF78859B), fontSize: 12),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              const Text(
                'Current progress',
                style: TextStyle(
                  color: Color(0xFF586A82),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_progress.round()}%',
                style: const TextStyle(
                  color: Color(0xFF149B78),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            value: _progress,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: const Color(0xFF149B78),
            onChanged: (value) => setState(() => _progress = value),
          ),
          TextField(
            controller: _note,
            maxLength: 1000,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'What changed? (optional)',
              hintText: 'Add a short progress note',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context)
                  .pop(_ProgressDraft(_progress.round(), _note.text.trim())),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF149B78),
                minimumSize: const Size.fromHeight(46),
              ),
              child: const Text('Save Progress'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GoalDetailSurface extends StatelessWidget {
  const _GoalDetailSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE5ECF2)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x070F2D4A),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF203454),
      fontSize: 13,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF78859B), fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF40516A),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.isLast});
  final GrowthGoalProgressData entry;
  final bool isLast;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF149B78),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 46, color: const Color(0xFFD9EDE6)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.progress}% progress',
                      style: const TextStyle(
                        color: Color(0xFF203454),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    _date(entry.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF8A96A7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (entry.note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  entry.note,
                  style: const TextStyle(
                    color: Color(0xFF65748A),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _GoalStatus extends StatelessWidget {
  const _GoalStatus({required this.label, required this.completed});
  final String label;
  final bool completed;
  @override
  Widget build(BuildContext context) {
    final color = completed ? const Color(0xFF168064) : const Color(0xFF3477A9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0EB),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFAB4F3A), fontSize: 12),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

String _formatNumber(num value) =>
    value % 1 == 0 ? value.toInt().toString() : value.toString();
String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
