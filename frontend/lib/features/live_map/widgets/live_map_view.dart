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

/// 지도 밖 버튼(내 위치·목적지)에서 카메라를 움직일 때 쓴다. 지도 SDK 타입은 노출하지 않는다.
class LiveMapCamera {
  _LiveMapViewState? _state;

  void focus(GeoPoint point) => _state?._focus(point);
}

/// 당일 지도의 지도 부분. 지도 SDK는 이 파일에서만 쓴다.
/// 카카오맵 등으로 바꿀 때는 이 위젯의 속만 갈아끼우면 된다.
/// 탭도 여기서 받아 [onPinTap]·[onMapTap]으로 넘긴다. 마커 위젯은 탭을 직접 처리하지 않는다.
///
/// 지금은 flutter_map + OpenStreetMap 타일 (API 키 불필요, 웹·앱 공통).
class LiveMapView extends StatefulWidget {
  const LiveMapView({
    super.key,
    required this.destination,
    required this.destinationPin,
    required this.pins,
    this.camera,
    this.onPinTap,
    this.onMapTap,
    this.bottomInset = 0,
  });

  final GeoPoint destination;

  /// 44×46 상자 안에 그린 목적지 핀. 상자 아래 가운데가 목적지 좌표에 놓인다.
  final Widget destinationPin;
  final List<MapPin> pins;
  final LiveMapCamera? camera;
  final ValueChanged<String>? onPinTap;
  final VoidCallback? onMapTap;

  /// 하단 시트에 가려지는 높이. 카메라를 맞출 때 이만큼 비워둔다.
  final double bottomInset;

  /// 사람 마커 상자 크기. 상자 가운데가 그 사람 좌표다.
  static const pinSize = Size(76, 76);

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  final _controller = MapController();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    widget.camera?._state = this;
  }

  @override
  void didUpdateWidget(covariant LiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.camera != widget.camera) {
      oldWidget.camera?._state = null;
      widget.camera?._state = this;
    }
    // 지도에 보이는 사람이 바뀌었을 때만 카메라를 다시 맞춘다. (움직일 때마다 맞추면 어지럽다)
    final before = {for (final p in oldWidget.pins) p.id};
    final after = {for (final p in widget.pins) p.id};
    if (_ready && (before.length != after.length || !before.containsAll(after))) _controller.fitCamera(_fit);
  }

  @override
  void dispose() {
    if (widget.camera?._state == this) widget.camera?._state = null;
    _controller.dispose();
    super.dispose();
  }

  void _focus(GeoPoint point) {
    if (!_ready) return;
    // 시트에 가려지지 않게 보이는 영역 가운데로.
    _controller.move(_latLng(point), _controller.camera.zoom < 15 ? 15 : _controller.camera.zoom, offset: Offset(0, -widget.bottomInset / 2));
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
          onTap: (_, __) => widget.onMapTap?.call(),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'app.gamgam',
          ),
          PolylineLayer(polylines: [
            for (final p in widget.pins)
              Polyline(
                points: [_latLng(p.position), _latLng(widget.destination)],
                color: AppPalette.gray500,
                strokeWidth: 2,
                pattern: StrokePattern.dashed(segments: const [6, 6]),
              ),
          ]),
          MarkerLayer(markers: [
            Marker(point: _latLng(widget.destination), width: 44, height: 46, alignment: Alignment.topCenter, child: widget.destinationPin),
            for (final p in widget.pins)
              Marker(
                point: _latLng(p.position),
                width: LiveMapView.pinSize.width,
                height: LiveMapView.pinSize.height,
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => widget.onPinTap?.call(p.id), child: p.child),
              ),
          ]),
          // 타일 출처 표시(OSM 이용 조건). 하단 시트에 가리지 않게 시트 위로 올린다.
          Padding(
            padding: EdgeInsets.only(bottom: widget.bottomInset),
            child: const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
          ),
        ],
      );

  static LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);
}
