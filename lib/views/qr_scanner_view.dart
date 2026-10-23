import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen camera QR scanner for student bus tickets.
class QrScannerView extends StatefulWidget {
  const QrScannerView({
    super.key,
    required this.onScanned,
    this.continuous = true,
  });

  /// Callback when a QR code is detected. Returns true if valid, false otherwise.
  final Future<bool> Function(String code) onScanned;

  /// Whether to keep scanning next passengers after a successful scan.
  final bool continuous;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _animController;
  late final Animation<double> _scanLineAnim;

  bool _isProcessing = false;
  bool _isTorchOn = false;
  String? _lastScannedCode;
  String? _feedbackMessage;
  bool? _lastScanSuccess;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null || rawValue.isEmpty) continue;

      // Prevent immediate duplicate scans of the exact same code
      if (_lastScannedCode == rawValue) continue;

      setState(() {
        _isProcessing = true;
        _lastScannedCode = rawValue;
      });

      final success = await widget.onScanned(rawValue);

      if (!mounted) return;

      setState(() {
        _lastScanSuccess = success;
        _feedbackMessage = success
            ? '✓ Ticket verified: $rawValue'
            : '✕ Scan issue with $rawValue';
      });

      if (!widget.continuous && success) {
        // Return back to dashboard after brief success confirmation
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          Navigator.of(context).pop(rawValue);
        }
        return;
      }

      // Reset cooldown so next passenger can scan
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _lastScannedCode = null;
          });
        }
      });

      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF059669);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera viewfinder stream
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetected,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_outlined,
                        color: Colors.white70,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Camera unavailable: ${error.errorCode}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Back to Dashboard'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Translucent dark mask with scanning aperture
          _buildScannerOverlay(context),

          // Top Header Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close Scanner',
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Bus Ticket Scanner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Flashlight toggle
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: Icon(
                            _isTorchOn ? Icons.flash_on : Icons.flash_off,
                            color: _isTorchOn ? Colors.amber : Colors.white,
                          ),
                          onPressed: () async {
                            try {
                              await _scannerController.toggleTorch();
                              if (mounted) {
                                setState(() => _isTorchOn = !_isTorchOn);
                              }
                            } catch (_) {}
                          },
                          tooltip: 'Toggle Flashlight',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Camera flip
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.flip_camera_ios,
                              color: Colors.white),
                          onPressed: () => _scannerController.switchCamera(),
                          tooltip: 'Switch Camera',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Instruction & Feedback Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_feedbackMessage != null) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _lastScanSuccess == true
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _feedbackMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Align passenger ticket QR code within the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.continuous
                          ? 'Continuous onboarding active • Ready for next passenger'
                          : 'Scans and returns automatically upon verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a dark viewfinder mask with an animated scanning laser
  Widget _buildScannerOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = (size.width * 0.72).clamp(220.0, 320.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Center target box
            Center(
              child: SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: Stack(
                  children: [
                    // Corner accents
                    _cornerAccent(Alignment.topLeft),
                    _cornerAccent(Alignment.topRight),
                    _cornerAccent(Alignment.bottomLeft),
                    _cornerAccent(Alignment.bottomRight),

                    // Animated laser scan line
                    AnimatedBuilder(
                      animation: _scanLineAnim,
                      builder: (context, _) {
                        return Positioned(
                          top: _scanLineAnim.value * (scanAreaSize - 4),
                          left: 12,
                          right: 12,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFF34D399),
                                  Color(0xFF059669),
                                  Color(0xFF34D399),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cornerAccent(Alignment alignment) {
    const double length = 24.0;
    const double thickness = 4.0;
    const Color cornerColor = Color(0xFF10B981);

    final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: Container(
        width: length,
        height: length,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: cornerColor, width: thickness)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: cornerColor, width: thickness)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: cornerColor, width: thickness)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: cornerColor, width: thickness)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft
                ? const Radius.circular(8)
                : Radius.zero,
            topRight: alignment == Alignment.topRight
                ? const Radius.circular(8)
                : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft
                ? const Radius.circular(8)
                : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight
                ? const Radius.circular(8)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}
