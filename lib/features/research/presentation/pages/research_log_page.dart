import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../performance/data/models/performance_summary.dart';
import '../../data/datasources/participant_local_datasource.dart';
import '../../data/datasources/research_local_datasource.dart';
import '../../data/models/participant_record.dart';
import '../../data/models/research_entry.dart';
import '../../data/repositories/participant_repository_impl.dart';
import '../../data/repositories/research_repository_impl.dart';
import '../cubit/participant_cubit.dart';
import '../cubit/participant_state.dart';
import '../cubit/research_cubit.dart';
import '../cubit/research_state.dart';

class ResearchLogPage extends StatelessWidget {
  const ResearchLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final box = Hive.box<ResearchEntry>('research_box');
            final dataSource = ResearchLocalDataSource(box: box);
            final repository = ResearchRepositoryImpl(
              localDataSource: dataSource,
            );
            return ResearchCubit(repository: repository)..loadEntries();
          },
        ),
        BlocProvider(
          create: (context) {
            final box = Hive.box<ParticipantRecord>('participant_box');
            final dataSource = ParticipantLocalDataSource(box: box);
            final repository = ParticipantRepositoryImpl(
              localDataSource: dataSource,
            );
            return ParticipantCubit(repository: repository)
              ..loadParticipants();
          },
        ),
      ],
      child: const _ResearchLogView(),
    );
  }
}

class _ResearchLogView extends StatelessWidget {
  const _ResearchLogView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Research Log'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Entries'),
              Tab(text: 'Participants'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'entries') {
                  context.read<ResearchCubit>().exportEntries();
                } else if (value == 'participants') {
                  context.read<ParticipantCubit>().exportParticipants();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'entries',
                  child: Text('Export Entries CSV'),
                ),
                PopupMenuItem(
                  value: 'participants',
                  child: Text('Export Participants CSV'),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final entry = await showModalBottomSheet<ResearchEntry>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => const _ResearchEntryForm(),
            );

            if (entry != null && context.mounted) {
              context.read<ResearchCubit>().saveEntry(entry);
            }
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<ResearchCubit, ResearchState>(
              listener: (context, state) {
                if (state is ResearchError) {
                  AppToast.showError(context, state.message);
                } else if (state is ResearchExported) {
                  AppToast.showSuccess(
                    context,
                    'CSV exported to ${state.filePath}',
                  );
                }
              },
            ),
            BlocListener<ParticipantCubit, ParticipantState>(
              listener: (context, state) {
                if (state is ParticipantError) {
                  AppToast.showError(context, state.message);
                } else if (state is ParticipantExported) {
                  AppToast.showSuccess(
                    context,
                    'CSV exported to ${state.filePath}',
                  );
                }
              },
            ),
          ],
          child: const TabBarView(
            children: [_ResearchEntriesTab(), _ParticipantsTab()],
          ),
        ),
      ),
    );
  }
}

class _ResearchEntriesTab extends StatelessWidget {
  const _ResearchEntriesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResearchCubit, ResearchState>(
      builder: (context, state) {
        if (state is ResearchLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ResearchLoaded) {
          if (state.entries.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: state.entries.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTheme.spacingSmall),
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return _ResearchEntryCard(entry: entry);
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _ParticipantsTab extends StatelessWidget {
  const _ParticipantsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParticipantCubit, ParticipantState>(
      builder: (context, state) {
        if (state is ParticipantLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ParticipantLoaded) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            itemCount: state.participants.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTheme.spacingSmall),
            itemBuilder: (context, index) {
              final participant = state.participants[index];
              return _ParticipantCard(participant: participant);
            },
          );
        }

        if (state is ParticipantError) {
          return const Center(child: Text('Failed to load participants'));
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _ResearchEntryForm extends StatefulWidget {
  const _ResearchEntryForm();

  @override
  State<_ResearchEntryForm> createState() => _ResearchEntryFormState();
}

class _ResearchEntryFormState extends State<_ResearchEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  List<PerformanceSummary> _sessions = const [];
  List<ParticipantRecord> _participants = const [];
  PerformanceSummary? _selectedSession;
  ParticipantRecord? _selectedParticipant;
  String _method = 'GUI';
  int _taskOrder = 1;
  double _susScore = 68;
  double _umuxScore = 5;
  int _satisfactionScore = 5;
  int _trustScore = 5;
  ResearchPreference _preference = ResearchPreference.noPreference;

  @override
  void initState() {
    super.initState();
    _loadPickers();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _loadPickers() {
    final sessionBox = Hive.box<PerformanceSummary>('performance_box');
    final participantBox = Hive.box<ParticipantRecord>('participant_box');
    final sessions = sessionBox.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final participants = participantBox.values.toList(growable: false)
      ..sort((a, b) => a.participantId.compareTo(b.participantId));

    setState(() {
      _sessions = sessions;
      _participants = participants;
    });
  }

  void _applySessionDefaults(PerformanceSummary session) {
    final method = session.interactionMethod == InteractionMethod.gui
        ? 'GUI'
        : 'VUI';
    setState(() {
      _method = method;
      _selectedSession = session;
    });
    _updateTaskOrder();
  }

  void _updateTaskOrder() {
    if (_selectedParticipant == null) return;
    final guiFirst = _selectedParticipant!.guiFirst;
    final isGui = _method == 'GUI';
    setState(() {
      _taskOrder = (guiFirst == isGui) ? 1 : 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMedium,
        right: AppTheme.spacingMedium,
        top: AppTheme.spacingLarge,
        bottom: padding.bottom + AppTheme.spacingLarge,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'New Research Entry',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdown<ParticipantRecord>(
              label: 'Participant',
              value: _selectedParticipant,
              items: _participants,
              itemLabel: (value) => value.participantId,
              onChanged: (value) {
                setState(() => _selectedParticipant = value);
                _updateTaskOrder();
              },
              validator: (value) =>
                  value == null ? 'Please select a participant' : null,
            ),
            const SizedBox(height: 12),
            _buildDropdown<PerformanceSummary>(
              label: 'Performance Session',
              value: _selectedSession,
              items: _sessions,
              itemLabel: (value) =>
                  '${value.sessionId} - ${value.interactionMethod.name.toUpperCase()} - ${DateFormat('dd MMM HH:mm').format(value.createdAt)}',
              onChanged: (value) {
                if (value == null) return;
                _applySessionDefaults(value);
              },
              validator: (value) =>
                  value == null ? 'Please select a session' : null,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              label: 'Method',
              value: _method,
              items: const ['GUI', 'VUI'],
              onChanged: (value) {
                setState(() => _method = value ?? 'GUI');
                _updateTaskOrder();
              },
            ),
            const SizedBox(height: 12),
            _buildStepper(
              label: 'Task Order',
              value: _taskOrder,
              min: 1,
              max: 2,
              onChanged: (value) => setState(() => _taskOrder = value),
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: 'SUS Score (0-100)',
              value: _susScore,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) => setState(() => _susScore = value),
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: 'UMUX-Lite (1-7)',
              value: _umuxScore,
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (value) => setState(() => _umuxScore = value),
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: 'Satisfaction (1-7)',
              value: _satisfactionScore.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (value) =>
                  setState(() => _satisfactionScore = value.round()),
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: 'Trust in VUI (1-7)',
              value: _trustScore.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (value) => setState(() => _trustScore = value.round()),
            ),
            const SizedBox(height: 12),
            _buildDropdown<ResearchPreference>(
              label: 'Preference',
              value: _preference,
              items: const [
                ResearchPreference.gui,
                ResearchPreference.vui,
                ResearchPreference.noPreference,
              ],
              itemLabel: (value) {
                switch (value) {
                  case ResearchPreference.gui:
                    return 'GUI';
                  case ResearchPreference.vui:
                    return 'VUI';
                  case ResearchPreference.noPreference:
                    return 'No preference';
                }
              },
              onChanged: (value) =>
                  setState(() => _preference = value ?? _preference),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              label: 'Notes',
              hintText: 'Pain points, quotes, observations',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                if (_selectedParticipant == null || _selectedSession == null) {
                  return;
                }

                final now = DateTime.now();
                final entry = ResearchEntry(
                  entryId: now.microsecondsSinceEpoch.toString(),
                  participantId: _selectedParticipant!.participantId,
                  sessionId: _selectedSession!.sessionId,
                  method: _method,
                  taskOrder: _taskOrder,
                  susScore: _susScore,
                  umuxScore: _umuxScore,
                  satisfactionScore: _satisfactionScore,
                  trustScore: _trustScore,
                  preference: _preference,
                  notes: _notesController.text.trim(),
                  createdAt: now,
                );

                Navigator.of(context).pop(entry);
              },
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hintText),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required field';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabel,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel != null ? itemLabel(item) : item.toString(),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _ResearchEntryCard extends StatelessWidget {
  final ResearchEntry entry;

  const _ResearchEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.participantId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                entry.method,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Session: ${entry.sessionId}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'SUS',
                value: entry.susScore.toStringAsFixed(1),
              ),
              _MetricChip(
                label: 'UMUX',
                value: entry.umuxScore.toStringAsFixed(1),
              ),
              _MetricChip(
                label: 'Sat',
                value: entry.satisfactionScore.toString(),
              ),
              _MetricChip(label: 'Trust', value: entry.trustScore.toString()),
              _MetricChip(label: 'Pref', value: entry.preference.name),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.notes.isEmpty ? 'No notes' : entry.notes,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dateFormat.format(entry.createdAt),
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final ParticipantRecord participant;

  const _ParticipantCard({required this.participant});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final updated = await showModalBottomSheet<ParticipantRecord>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _ParticipantForm(participant: participant),
        );

        if (updated != null && context.mounted) {
          context.read<ParticipantCubit>().saveParticipant(updated);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  participant.participantId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  participant.guiFirst ? 'GUI first' : 'VUI first',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Age: ${participant.age == 0 ? 'N/A' : participant.age.toString()} • Gender: ${participant.gender}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'Tech',
                  value: participant.techFamiliarity.toString(),
                ),
                _MetricChip(
                  label: 'Voice',
                  value: participant.voiceFamiliarity.toString(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              participant.notes.isEmpty ? 'No notes' : participant.notes,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantForm extends StatefulWidget {
  final ParticipantRecord participant;

  const _ParticipantForm({required this.participant});

  @override
  State<_ParticipantForm> createState() => _ParticipantFormState();
}

class _ParticipantFormState extends State<_ParticipantForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _genderController;
  late final TextEditingController _notesController;
  int _techFamiliarity = 3;
  int _voiceFamiliarity = 3;
  bool _guiFirst = true;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(
      text: widget.participant.age == 0
          ? ''
          : widget.participant.age.toString(),
    );
    _genderController = TextEditingController(text: widget.participant.gender);
    _notesController = TextEditingController(text: widget.participant.notes);
    _techFamiliarity = widget.participant.techFamiliarity;
    _voiceFamiliarity = widget.participant.voiceFamiliarity;
    _guiFirst = widget.participant.guiFirst;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _genderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingMedium,
        right: AppTheme.spacingMedium,
        top: AppTheme.spacingLarge,
        bottom: padding.bottom + AppTheme.spacingLarge,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Edit Participant ${widget.participant.participantId}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _genderController,
              decoration: const InputDecoration(labelText: 'Gender'),
            ),
            const SizedBox(height: 12),
            _buildParticipantSlider(
              label: 'Tech Familiarity (1-5)',
              value: _techFamiliarity,
              onChanged: (value) =>
                  setState(() => _techFamiliarity = value),
            ),
            const SizedBox(height: 12),
            _buildParticipantSlider(
              label: 'Voice Familiarity (1-5)',
              value: _voiceFamiliarity,
              onChanged: (value) =>
                  setState(() => _voiceFamiliarity = value),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _guiFirst,
              onChanged: (value) => setState(() => _guiFirst = value),
              title: const Text('GUI First'),
              subtitle: const Text('Counterbalancing order'),
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final age = int.tryParse(_ageController.text.trim()) ?? 0;
                final updated = widget.participant.copyWith(
                  age: age,
                  gender: _genderController.text.trim().isEmpty
                      ? 'Unspecified'
                      : _genderController.text.trim(),
                  techFamiliarity: _techFamiliarity,
                  voiceFamiliarity: _voiceFamiliarity,
                  guiFirst: _guiFirst,
                  notes: _notesController.text.trim(),
                );

                Navigator.of(context).pop(updated);
              },
              child: const Text('Save Participant'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantSlider({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (value) => onChanged(value.round()),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No research entries yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to add participant notes, scores, and preferences.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
