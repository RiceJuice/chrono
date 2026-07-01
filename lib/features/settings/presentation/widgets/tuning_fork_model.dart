import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class TuningForkModel extends StatefulWidget {
  const TuningForkModel({
    super.key,
    required this.size,
    this.isResonating = false,
  });

  final double size;
  final bool isResonating;

  @override
  State<TuningForkModel> createState() => _TuningForkModelState();
}

class _TuningForkModelState extends State<TuningForkModel> {
  static const _modelAsset = 'assets/models/tuning_fork.glb';

  /// Bounding-Box-Mitte des GLB-Modells (Y: −0.96 … 1.40).
  static const _modelCenterY = 0.22;

  /// model-viewer nutzt den Radius als Prozentwert (105 % = Standard-Framing).
  static const _cameraOrbitTheta = 28.0;
  static const _cameraOrbitPhi = 78.0;
  static const _cameraOrbitRadiusPercent = 115.0;

  final Flutter3DController _controller = Flutter3DController();
  bool _isModelReady = false;

  @override
  void initState() {
    super.initState();
    _controller.onModelLoaded.addListener(_handleModelLoaded);
  }

  @override
  void didUpdateWidget(covariant TuningForkModel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isResonating != widget.isResonating) {
      _syncResonance();
    }
  }

  void _handleModelLoaded() {
    if (!_controller.onModelLoaded.value || !mounted) return;

    setState(() => _isModelReady = true);
    _controller
      ..setCameraTarget(0, _modelCenterY, 0)
      ..setCameraOrbit(
        _cameraOrbitTheta,
        _cameraOrbitPhi,
        _cameraOrbitRadiusPercent,
      );
    _syncResonance();
  }

  void _syncResonance() {
    if (!_isModelReady) return;

    if (widget.isResonating) {
      _controller.startRotation(rotationSpeed: 14);
    } else {
      _controller.stopRotation();
    }
  }

  @override
  void dispose() {
    _controller.onModelLoaded.removeListener(_handleModelLoaded);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Flutter3DViewer(
        controller: _controller,
        src: _modelAsset,
        enableTouch: false,
        activeGestureInterceptor: false,
        progressBarColor: Colors.transparent,
      ),
    );
  }
}
