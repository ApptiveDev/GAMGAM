import 'package:flutter/foundation.dart';

import '../../data/models/appointment.dart';
import '../../data/models/decision_template.dart';
import '../../data/models/place.dart';
import '../../data/repositories/appointment_repository.dart';

/// 약속 만들기 플로우(템플릿 → 시간·장소)의 입력값. 라우터의 ShellRoute가 플로우 동안만 들고 있는다.
class CreateAppointmentController extends ChangeNotifier {
  DecisionTemplate _template = DecisionTemplate.hostDecides;
  String _name = '';
  final List<DateTime> _times = [];
  final List<Place> _places = [];
  bool _submitting = false;

  /// 투표 항목은 후보가 이만큼 있어야 투표가 된다.
  static const minVoteOptions = 2;

  DecisionTemplate get template => _template;
  String get name => _name;
  List<DateTime> get times => List.unmodifiable(_times);
  List<Place> get places => List.unmodifiable(_places);
  bool get submitting => _submitting;

  bool get canGoToDetails => _name.trim().isNotEmpty;
  bool get timesReady => _template.votesTime ? _times.length >= minVoteOptions : _times.length == 1;
  bool get placesReady => _template.votesPlace ? _places.length >= minVoteOptions : _places.length == 1;
  bool get canSubmit => timesReady && placesReady && !_submitting;

  void selectTemplate(DecisionTemplate template) {
    _template = template;
    // 투표 → 직접 지정으로 바꾸면 첫 번째 후보만 남긴다.
    if (!template.votesTime && _times.length > 1) _times.removeRange(1, _times.length);
    if (!template.votesPlace && _places.length > 1) _places.removeRange(1, _places.length);
    notifyListeners();
  }

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  /// 투표면 후보 추가, 직접 지정이면 교체.
  void addTime(DateTime time) {
    if (!_template.votesTime) _times.clear();
    if (!_times.contains(time)) _times.add(time);
    _times.sort();
    notifyListeners();
  }

  void removeTime(DateTime time) {
    _times.remove(time);
    notifyListeners();
  }

  void addPlace(Place place) {
    if (!_template.votesPlace) _places.clear();
    _places.add(place);
    notifyListeners();
  }

  void removePlace(Place place) {
    _places.remove(place);
    notifyListeners();
  }

  Future<Appointment> submit(AppointmentRepository repository) async {
    _submitting = true;
    notifyListeners();
    try {
      return await repository.create(name: _name.trim(), template: _template, times: _times, places: _places);
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
