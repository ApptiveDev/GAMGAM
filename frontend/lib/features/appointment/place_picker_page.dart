import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/widgets/gam/gam_icon.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/place.dart';
import '../../data/repositories/appointment_repository.dart';
import 'appointment_page.dart';

/// 장소정하기. 분류를 고르거나 검색해서 장소를 투표 후보로 올린다.
/// 지금은 목업 장소 목록이고, 나중에 현재 위치 기준 주변 장소 검색이 들어온다.
class PlacePickerPage extends StatefulWidget {
  const PlacePickerPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<PlacePickerPage> createState() => _PlacePickerPageState();
}

class _PlacePickerPageState extends State<PlacePickerPage> {
  final _query = TextEditingController();
  var _category = '친구와 식사';

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Place> get _places {
    final keyword = _query.text.trim();
    if (keyword.isNotEmpty) {
      return [
        for (final (place, _) in MockData.nearbyPlaces)
          if (place.name.contains(keyword) || place.category.contains(keyword)) place,
      ];
    }
    return [
      for (final (place, tags) in MockData.nearbyPlaces)
        if (tags.contains(_category)) place,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final added = {...?repo.findById(widget.appointmentId)?.placeOptions.map((o) => o.value.name)};
    final places = _places;

    return PinkFrame(
      background: FrameBackground.white,
      child: Stack(children: [
        Column(children: [
          FrameTopBar(
            leading: GamIconButton('ic_arrow_left_dark', tooltip: '뒤로', onTap: () => context.pop()),
            middle: Padding(padding: const EdgeInsets.only(left: 2), child: Text('장소 정하기', style: GamText.body16)),
            // 현재 위치로 보기는 지도 담당 화면과 함께 붙인다.
            trailing: const Padding(padding: EdgeInsets.all(11), child: GamIcon('ic_crosshair', size: 22)),
          ),
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: MockData.placeCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final category = MockData.placeCategories[i];
                final selected = _query.text.trim().isEmpty && category == _category;
                return GestureDetector(
                  onTap: () {
                    _query.clear();
                    setState(() => _category = category);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? GamColors.pinkStrong : GamColors.surface,
                      borderRadius: BorderRadius.circular(29),
                    ),
                    child: Text(category, style: GamText.body14.copyWith(color: selected ? GamColors.text900 : GamColors.text300)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: places.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Text('찾는 장소가 없어요', style: GamText.body14.copyWith(color: GamColors.text600)),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 140),
                    children: [
                      for (final (i, place) in places.indexed)
                        PlaceListRow(
                          place: place,
                          divider: GamColors.lineSoft,
                          last: i == places.length - 1,
                          added: added.contains(place.name),
                          onAdd: () => _add(place),
                        ),
                    ],
                  ),
          ),
        ]),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 213,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.9)],
                  stops: const [0.479, 0.896],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 30,
          child: SafeArea(
            top: false,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: GamColors.surface,
                borderRadius: BorderRadius.circular(59),
                border: Border.all(color: GamColors.canvas),
              ),
              child: Row(children: [
                const GamIcon('ic_search_grey', size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    style: GamText.body13,
                    cursorColor: GamColors.text900,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '무엇을 추가하시겠어요?',
                      hintStyle: GamText.body13.copyWith(color: GamColors.text600),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _add(Place place) async {
    await context.read<AppointmentRepository>().addPlaceOption(widget.appointmentId, place);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${place.name}을(를) 후보에 올렸어요')));
  }
}
