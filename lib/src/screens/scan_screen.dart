import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../services/product_service.dart';
import '../providers/product_provider.dart';
import '../localization/app_localizations.dart';
import '../widgets/app_bar_with_profile.dart';
import '../screens/home_screen.dart';
import 'product_details_screen.dart';
import 'dart:async';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _hasPermission = false;
  bool _isScanning = true;
  bool _isLoading = false;
  late MobileScannerController _controller;
  Timer? _errorCooldownTimer;
  static const _errorCooldownDuration = Duration(seconds: 3);
  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    _checkPermission();
  }

  @override
  void dispose() {
    _controller.dispose();
    _errorCooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    try {
      await _controller.start();
      setState(() {
        _hasPermission = true;
      });
    } catch (e) {
      setState(() {
        _hasPermission = false;
      });
    }
  }

  void _startErrorCooldown() {
    setState(() {
      _isScanning = false;
    });

    _errorCooldownTimer?.cancel();
    _errorCooldownTimer = Timer(_errorCooldownDuration, () {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _lastErrorMessage = null; // Reset last error when cooldown ends
        });
      }
    });
  }

  void _showError(String title, String message) {
    // Only show error if it's different from the last one
    if (_lastErrorMessage != message) {
      _lastErrorMessage = message;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isLoading) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null) {
        setState(() {
          _isScanning = false;
          _isLoading = true;
        });

        try {
          final productService = context.read<ProductService>();
          final product = await productService.getProductByBarcode(code);
          
          if (!mounted) return;

          // Add to history
          context.read<ProductProvider>().addToScanned(product);

          // Navigate to product details
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );

          if (!mounted) return;

          // Switch to history tab
          HomeScreen.homeKey.currentState?.setSelectedIndex(0);

          setState(() {
            _isScanning = true;
            _isLoading = false;
            _lastErrorMessage = null; // Reset last error on success
          });
        } catch (e) {
          if (!mounted) return;
          
          setState(() {
            _isLoading = false;
          });

          // Start error cooldown
          _startErrorCooldown();

          // Show a custom error message based on the error type
          final errorTitle = e.toString().contains('non-food product')
              ? AppLocalizations.of(context).translate('non_food_product')
              : AppLocalizations.of(context).translate('scan_error');
              
          final errorMessage = e.toString().contains('non-food product')
              ? AppLocalizations.of(context).translate('non_food_product_message')
              : AppLocalizations.of(context).translate('scan_error_message');

          _showError(errorTitle, errorMessage);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.translate('camera_permission'),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermission,
                child: Text(l10n.translate('grant_permission')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBarWithProfile(
        title: l10n.translate('scan_product'),
      ),
      body: Stack(
        children: [
          // Background pattern
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Background.png'),
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          // Very subtle overlay to ensure scanner visibility
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.translate('scan_barcode'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const scanAreaSize = 250.0;
    const cornerRadius = 20.0;
    
    final center = Offset(size.width / 2, size.height / 2);
    final scanAreaRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Create the rounded rectangle path for the scan area
    final roundedRect = RRect.fromRectAndRadius(
      scanAreaRect,
      const Radius.circular(cornerRadius),
    );

    // Create the background path (entire screen)
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create the hole for the scan area
    final holePath = Path()
      ..addRRect(roundedRect);

    // Subtract the hole from the background
    final completePath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    // Draw the semi-transparent background
    canvas.drawPath(
      completePath,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.fill,
    );

    // Create gradient for the border
    final borderGradient = ui.Gradient.linear(
      scanAreaRect.topLeft,
      scanAreaRect.bottomRight,
      [
        const Color(0xFF6B3FA0).withOpacity(0.8), // Purple theme color
        Colors.white.withOpacity(0.8),
      ],
    );

    // Draw the border with gradient
    canvas.drawRRect(
      roundedRect.deflate(-2), // Slightly smaller for border effect
      Paint()
        ..shader = borderGradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2),
    );

    // Add corner highlights
    final cornerPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(scanAreaRect.left + cornerRadius, scanAreaRect.top),
      Offset(scanAreaRect.left + cornerRadius + cornerLength, scanAreaRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.top + cornerRadius),
      Offset(scanAreaRect.left, scanAreaRect.top + cornerRadius + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanAreaRect.right - cornerRadius - cornerLength, scanAreaRect.top),
      Offset(scanAreaRect.right - cornerRadius, scanAreaRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.right, scanAreaRect.top + cornerRadius),
      Offset(scanAreaRect.right, scanAreaRect.top + cornerRadius + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.bottom - cornerRadius - cornerLength),
      Offset(scanAreaRect.left, scanAreaRect.bottom - cornerRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.left + cornerRadius, scanAreaRect.bottom),
      Offset(scanAreaRect.left + cornerRadius + cornerLength, scanAreaRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanAreaRect.right, scanAreaRect.bottom - cornerRadius - cornerLength),
      Offset(scanAreaRect.right, scanAreaRect.bottom - cornerRadius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.right - cornerRadius - cornerLength, scanAreaRect.bottom),
      Offset(scanAreaRect.right - cornerRadius, scanAreaRect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 