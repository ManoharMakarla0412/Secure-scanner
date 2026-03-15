import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:securescan/features/scan/services/scanner_service.dart';
import 'package:securescan/l10n/app_localizations.dart';

class ScanImageScreen extends StatefulWidget {
  const ScanImageScreen({super.key});

  @override
  State<ScanImageScreen> createState() => _ScanImageScreenState();
}

class _ScanImageScreenState extends State<ScanImageScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isScanning = false;
  String? _resultText;

  Future<void> _pickAndScanImage() async {
    setState(() {
      _resultText = null;
    });

    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _selectedImage = image;
      _isScanning = true;
    });

    try {
      final historyItem = await ScannerService.scanImage(image.path);
      if (historyItem != null) {
        setState(() {
          _resultText = historyItem.value;
        });
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.scanResultTitle),
              content: Text(l10n.noCodeFound),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
        }
        setState(() {
          _resultText = AppLocalizations.of(context)!.noCodeFound;
        });
      }
    } catch (e) {
      setState(() {
        _resultText = 'Failed to scan image: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanImage),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                l10n.onboarding1Subtitle,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Pick button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _pickAndScanImage,
                  icon: const Icon(Icons.photo_library_outlined,color: Colors.white,),
                  label: Text(
                    _isScanning ? '${l10n.scan}...' : l10n.permissionGalleryDesc,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Preview selected image
              if (_selectedImage != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      'No image selected yet.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Result
              if (_resultText != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scanResultTitle,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _resultText!,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}