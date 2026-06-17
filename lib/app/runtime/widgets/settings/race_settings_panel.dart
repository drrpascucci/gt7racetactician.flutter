import 'package:flutter/material.dart';
import 'package:gt7_design_system/gt7_design_system.dart';
import 'package:gt7_domain/gt7_domain.dart';

import '../../../config/app_config.dart';
import '../runtime_ui_utils.dart';

class RaceSettingsPanel extends StatefulWidget {
  const RaceSettingsPanel({super.key, required this.initialConfig, required this.onSave});

  final AppConfig initialConfig;
  final Future<void> Function(AppConfig config) onSave;

  @override
  State<RaceSettingsPanel> createState() => RaceSettingsPanelState();
}

class RaceSettingsPanelState extends State<RaceSettingsPanel> {
  late final TextEditingController _trackController;
  late final TextEditingController _lapsController;
  late final TextEditingController _minutesController;
  late final TextEditingController _pitLaneController;
  late double _shiftPercentage;
  late RaceType _raceType;
  late double _tyreColdMax;
  late double _tyreOptimalMax;
  late double _tyreHotMax;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    _trackController = TextEditingController(text: config.trackName);
    _lapsController = TextEditingController(text: '${config.targetLaps}');
    _minutesController = TextEditingController(
      text: '${config.targetRaceTime.inMinutes}',
    );
    _pitLaneController = TextEditingController(
      text: '${config.pitLaneTime.inSeconds}',
    );
    _shiftPercentage = config.shiftPercentage.toDouble().clamp(75.0, 100.0);
    _raceType = config.raceType;
    _tyreColdMax = config.tyreColdMax.toDouble().clamp(40.0, 150.0);
    _tyreOptimalMax = config.tyreOptimalMax.toDouble().clamp(40.0, 150.0);
    _tyreHotMax = config.tyreHotMax.toDouble().clamp(40.0, 150.0);
  }

  @override
  void didUpdateWidget(covariant RaceSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final config = widget.initialConfig;
    if (_trackController.text != config.trackName) {
      _trackController.text = config.trackName;
    }
    if (_lapsController.text != '${config.targetLaps}') {
      _lapsController.text = '${config.targetLaps}';
    }
    if (_minutesController.text != '${config.targetRaceTime.inMinutes}') {
      _minutesController.text = '${config.targetRaceTime.inMinutes}';
    }
    if (_pitLaneController.text != '${config.pitLaneTime.inSeconds}') {
      _pitLaneController.text = '${config.pitLaneTime.inSeconds}';
    }
    // Only resync slider when persisted value actually changed (not during drag)
    if (config.shiftPercentage.toDouble().clamp(75.0, 100.0) != _shiftPercentage &&
        config.shiftPercentage.toDouble() !=
            oldWidget.initialConfig.shiftPercentage) {
      _shiftPercentage = config.shiftPercentage.toDouble().clamp(75.0, 100.0);
    }
    if (_raceType != config.raceType) {
      _raceType = config.raceType;
    }
    // Only resync sliders when persisted value actually changed (not during drag)
    if (config.tyreColdMax.toDouble().clamp(40.0, 150.0) != _tyreColdMax &&
        config.tyreColdMax.toDouble() != oldWidget.initialConfig.tyreColdMax) {
      _tyreColdMax = config.tyreColdMax.toDouble().clamp(40.0, 150.0);
    }
    if (config.tyreOptimalMax.toDouble().clamp(40.0, 150.0) != _tyreOptimalMax &&
        config.tyreOptimalMax.toDouble() !=
            oldWidget.initialConfig.tyreOptimalMax) {
      _tyreOptimalMax = config.tyreOptimalMax.toDouble().clamp(40.0, 150.0);
    }
    if (config.tyreHotMax.toDouble().clamp(40.0, 150.0) != _tyreHotMax &&
        config.tyreHotMax.toDouble() != oldWidget.initialConfig.tyreHotMax) {
      _tyreHotMax = config.tyreHotMax.toDouble().clamp(40.0, 150.0);
    }
  }

  @override
  void dispose() {
    _trackController.dispose();
    _lapsController.dispose();
    _minutesController.dispose();
    _pitLaneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Gt7Panel(
      title: 'Race settings',
      subtitle: 'Tune the race target, pit assumptions and shift point.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _trackController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Track name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
          const SizedBox(height: Gt7Spacing.md),
          DropdownButtonFormField<RaceType>(
            value: _raceType,
            dropdownColor: Colors.black,
            decoration: const InputDecoration(
              labelText: 'Race type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            items: RaceType.values
                .where((value) => value != RaceType.undefined)
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(raceTypeLabel(value)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _raceType = value;
              });
            },
          ),
          const SizedBox(height: Gt7Spacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lapsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target laps',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Gt7Spacing.md),
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _raceType == RaceType.timeRace
                        ? 'Total minutes'
                        : 'Target minutes',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gt7Spacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pitLaneController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pit lane seconds',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Gt7Spacing.md),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        'Shift\n${_shiftPercentage.round()}%',
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _shiftPercentage.clamp(75.0, 100.0),
                        min: 75,
                        max: 100,
                        divisions: 25,
                        onChanged: (v) => setState(() => _shiftPercentage = v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gt7Spacing.lg),
          Text('Tyre temperature thresholds', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: Gt7Spacing.xs),
          Text(
            'Cold < ${_tyreColdMax.round()}° ≤ Optimal < ${_tyreOptimalMax.round()}° ≤ Hot < ${_tyreHotMax.round()}° ≤ Overheated',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.gt7Theme.description,
            ),
          ),
          const SizedBox(height: Gt7Spacing.sm),
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  'Cold\n${_tyreColdMax.round()}°',
                  style: const TextStyle(color: Color(0xFF1E88E5), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _tyreColdMax.clamp(40.0, 150.0),
                  min: 40,
                  max: 150,
                  divisions: 110,
                  onChanged: (v) => setState(() {
                    _tyreColdMax = v;
                    if (_tyreOptimalMax < _tyreColdMax + 5) {
                      _tyreOptimalMax = _tyreColdMax + 5;
                    }
                    if (_tyreHotMax < _tyreOptimalMax + 5) {
                      _tyreHotMax = _tyreOptimalMax + 5;
                    }
                  }),
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  'Optimal\n${_tyreOptimalMax.round()}°',
                  style: const TextStyle(color: Color(0xFF43A047), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _tyreOptimalMax.clamp(40.0, 150.0),
                  min: 40,
                  max: 150,
                  divisions: 110,
                  onChanged: (v) => setState(() {
                    _tyreOptimalMax = v;
                    if (_tyreColdMax > _tyreOptimalMax - 5) {
                      _tyreColdMax = _tyreOptimalMax - 5;
                    }
                    if (_tyreHotMax < _tyreOptimalMax + 5) {
                      _tyreHotMax = _tyreOptimalMax + 5;
                    }
                  }),
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  'Hot\n${_tyreHotMax.round()}°',
                  style: const TextStyle(color: Color(0xFFFDD835), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _tyreHotMax.clamp(40.0, 150.0),
                  min: 40,
                  max: 150,
                  divisions: 110,
                  onChanged: (v) => setState(() {
                    _tyreHotMax = v;
                    if (_tyreOptimalMax > _tyreHotMax - 5) {
                      _tyreOptimalMax = _tyreHotMax - 5;
                    }
                    if (_tyreColdMax > _tyreOptimalMax - 5) {
                      _tyreColdMax = _tyreOptimalMax - 5;
                    }
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> save() async {
    final original = widget.initialConfig;
    await widget.onSave(
      original.copyWith(
        trackName: _trackController.text.trim().isEmpty
            ? original.trackName
            : _trackController.text.trim(),
        raceType: _raceType,
        targetLaps: _readInt(
          _lapsController.text,
          original.targetLaps,
          minimum: 1,
        ),
        targetRaceTime: Duration(
          minutes: _readInt(
            _minutesController.text,
            original.targetRaceTime.inMinutes,
            minimum: 1,
          ),
        ),
        pitLaneTime: Duration(
          seconds: _readInt(
            _pitLaneController.text,
            original.pitLaneTime.inSeconds,
            minimum: 0,
          ),
        ),
        shiftPercentage: _shiftPercentage.round(),
        tyreColdMax: _tyreColdMax.round(),
        tyreOptimalMax: _tyreOptimalMax.round(),
        tyreHotMax: _tyreHotMax.round(),
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Race settings saved.')));
  }

  int _readInt(String value, int fallback, {required int minimum}) {
    final parsed = int.tryParse(value.trim()) ?? fallback;
    return parsed < minimum ? fallback : parsed;
  }
}
