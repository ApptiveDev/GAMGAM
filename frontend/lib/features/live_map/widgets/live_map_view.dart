import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/geo_point.dart';

/// 지도 위에 올릴 사람 한 명.
class MapPin {
  const MapPin({required this.id, required this.position, required this.child});

  final String id;
  final GeoPoint position;
  final Widget child;
}

/// 당일 지도의 지도 부분. 지도 SDK는 이 파일에서만 쓴다.
/// 카카오맵 등으로 바꿀 때는 이 위젯의 속만 갈아끼우면 된다.
///
/// 지금은 flutter_map + OpenStreetMap 타일 (API 키 불필요, 웹·앱 공통).
class LiveMapView extends StatefulWidget {
  const LiveMapView({super.key, required this.destination, required this.destinationPin, required this.pins, this.bottomInset = 0});

  final GeoPoint destination;
  final Widget destinationPin;
  final List<MapPin> pins;

  /// 하단 시트에 가려지는 높이. 카메라를 맞출 때 이만큼 비워둔다.
  final double bottomInset;

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  final _controller = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(covariant LiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 지도에 보이는 사람이 바뀌었을 때만 카메라를 다시 맞춘다. (움직일 때마다 맞추면 어지럽다)
    final before = {for (final p in oldWidget.pins) p.id};
    final after = {for (final p in widget.pins) p.id};
    if (_ready && (before.length != after.length || !before.containsAll(after))) _controller.fitCamera(_fit);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CameraFit get _fit => CameraFit.coordinates(
        coordinates: [_latLng(widget.destination), for (final p in widget.pins) _latLng(p.position)],
        padding: EdgeInsets.fromLTRB(56, 200, 56, widget.bottomInset + 48),
        maxZoom: 16,
      );

  @override
  Widget build(BuildContext context) => FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: _latLng(widget.destination),
          initialZoom: 14,
          initialCameraFit: _fit,
          backgroundColor: const Color(0xFFE9E7E3),
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          onMapReady: () => _ready = true,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'app.gamgam',
            // 와이어프레임처럼 회색조 지도 위에 포인트 컬러만 보이도록 채도를 뺀다.
            tileBuilder: (context, tile, _) => ColorFiltered(colorFilter: _grayscale, child: tile),
          ),
          PolylineLayer(polylines: [
            for (final p in widget.pins)
              Polyline(
                points: [_latLng(p.position), _latLng(widget.destination)],
                color: AppColors.textMuted,
                strokeWidth: 2,
                pattern: StrokePattern.dashed(segments: const [6, 6]),
              ),
          ]),
          MarkerLayer(markers: [
            Marker(point: _latLng(widget.destination), width: 80, height: 76, alignment: Alignment.topCenter, child: widget.destinationPin),
            for (final p in widget.pins) Marker(point: _latLng(p.position), width: 76, height: 84, child: p.child),
          ]),
          // 타일 출처 표시(OSM 이용 조건). 하단 시트에 가리지 않게 시트 위로 올린다.
          Padding(
            padding: EdgeInsets.only(bottom: widget.bottomInset),
            child: const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
          ),
        ],
      );

  static LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

  static const _grayscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 8, //
    0.2126, 0.7152, 0.0722, 0, 6,
    0.2126, 0.7152, 0.0722, 0, 2,
    0, 0, 0, 1, 0,
  ]);
}
