import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

/// Map tiles drawn on the device (a street grid with parks and water), for
/// tests, goldens and the showcase: no network, no files, the same picture
/// every time. Not a real map. [offline]: tiles never load, as when the
/// network is down (the map shows its background).
class DkSketchTileProvider extends TileProvider {
  /// Creates the provider.
  new({this.offline = false});

  /// Tiles never arrive.
  final bool offline;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _SketchTile(
        coordinates.x,
        coordinates.y,
        coordinates.z,
        offline: offline,
      );
}

const int _tile = 256;

/// Streets every 96 px in map pixels, so they continue across tiles.
const int _block = 96;

@immutable
class _SketchTile extends ImageProvider<_SketchTile> {
  const new(this.x, this.y, this.z, {required this.offline});

  final int x;
  final int y;
  final int z;
  final bool offline;

  @override
  Future<_SketchTile> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_SketchTile key, ImageDecoderCallback decode) {
    if (offline) {
      return OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
    }
    return OneFrameImageStreamCompleter(
      SynchronousFuture(ImageInfo(image: _draw())),
    );
  }

  ui.Image _draw() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(
        const Rect.fromLTWH(0, 0, 256, 256),
        Paint()..color = const Color(0xFFF2EFE9),
      );
    final left = x * _tile;
    final top = y * _tile;
    // Blocks: some are parks or water.
    for (var gx = (left ~/ _block) * _block; gx < left + _tile; gx += _block) {
      for (var gy = (top ~/ _block) * _block; gy < top + _tile; gy += _block) {
        final h = _hash(gx ~/ _block, gy ~/ _block, z);
        final fill = h % 23 == 0
            ? const Color(0xFFAAD3DF)
            : h % 7 == 0
            ? const Color(0xFFC8E6A8)
            : h % 3 == 0
            ? const Color(0xFFE4DED5)
            : null;
        if (fill == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (gx - left + 10).toDouble(),
            (gy - top + 10).toDouble(),
            _block - 20,
            _block - 20,
          ),
          Paint()..color = fill,
        );
      }
    }
    // Streets: a casing, then the road; every 4th one is a main road
    // (drawn last, so it runs over the crossings).
    for (final main in [false, true]) {
      for (var g = (left ~/ _block) * _block; g <= left + _tile; g += _block) {
        if (_isMain(g) != main) continue;
        final at = (g - left).toDouble();
        _road(canvas, Offset(at, 0), Offset(at, 256), main: main);
      }
      for (var g = (top ~/ _block) * _block; g <= top + _tile; g += _block) {
        if (_isMain(g) != main) continue;
        final at = (g - top).toDouble();
        _road(canvas, Offset(0, at), Offset(256, at), main: main);
      }
    }
    return recorder.endRecording().toImageSync(_tile, _tile);
  }

  static bool _isMain(int g) => (g ~/ _block) % 4 == 0;

  static void _road(Canvas canvas, Offset a, Offset b, {required bool main}) {
    canvas
      ..drawLine(
        a,
        b,
        Paint()
          ..color = main ? const Color(0xFFE0A96D) : const Color(0xFFD6CFC2)
          ..strokeWidth = main ? 11 : 8,
      )
      ..drawLine(
        a,
        b,
        Paint()
          ..color = main ? const Color(0xFFFCD6A4) : const Color(0xFFFFFFFF)
          ..strokeWidth = main ? 8 : 5,
      );
  }

  static int _hash(int a, int b, int c) =>
      ((a * 73856093) ^ (b * 19349663) ^ (c * 83492791)) & 0x7fffffff;

  @override
  bool operator ==(Object other) =>
      other is _SketchTile &&
      other.x == x &&
      other.y == y &&
      other.z == z &&
      other.offline == offline;

  @override
  int get hashCode => Object.hash(x, y, z, offline);
}
