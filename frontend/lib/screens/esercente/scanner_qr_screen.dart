import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/theme.dart';

/// Scanner QR per Esercente
class ScannerQRScreen extends StatefulWidget {
  const ScannerQRScreen({super.key});

  @override
  State<ScannerQRScreen> createState() => _ScannerQRScreenState();
}

class _ScannerQRScreenState extends State<ScannerQRScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null) return;

    setState(() => _isProcessing = true);

    // Parse QR data: "CLIENTE|ID|EMAIL"
    final parts = code.split('|');
    if (parts.length == 3 && parts[0] == 'CLIENTE') {
      final clienteId = int.tryParse(parts[1]);
      final clienteEmail = parts[2];

      if (clienteId != null) {
        Navigator.pop(context, {
          'cliente_id': clienteId,
          'cliente_email': clienteEmail,
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code non valido'),
          backgroundColor: AppTheme.errore,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scansiona QR Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primario,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    'Inquadra il QR code del cliente',
                    style: Theme.of(context).textTheme.bodyMedium,
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

