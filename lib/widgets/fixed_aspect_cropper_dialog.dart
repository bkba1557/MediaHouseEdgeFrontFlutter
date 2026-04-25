import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?> showFixedAspectCropperDialog(
  BuildContext context, {
  required XFile sourceFile,
  required double aspectRatio,
  String title = 'قص الصورة',
}) async {
  final bytes = await sourceFile.readAsBytes();
  if (!context.mounted) return null;

  return showDialog<XFile>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FixedAspectCropperDialog(
      sourceFile: sourceFile,
      imageBytes: bytes,
      aspectRatio: aspectRatio,
      title: title,
    ),
  );
}

class _FixedAspectCropperDialog extends StatefulWidget {
  final XFile sourceFile;
  final Uint8List imageBytes;
  final double aspectRatio;
  final String title;

  const _FixedAspectCropperDialog({
    required this.sourceFile,
    required this.imageBytes,
    required this.aspectRatio,
    required this.title,
  });

  @override
  State<_FixedAspectCropperDialog> createState() =>
      _FixedAspectCropperDialogState();
}

class _FixedAspectCropperDialogState extends State<_FixedAspectCropperDialog> {
  final CropController _controller = CropController();
  bool _isCropping = false;

  Future<void> _crop() async {
    if (_isCropping) return;
    setState(() => _isCropping = true);
    _controller.crop();
  }

  Future<void> _handleResult(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        if (!mounted) return;
        Navigator.of(context).pop(
          XFile.fromData(
            croppedImage,
            name: 'cropped-${widget.sourceFile.name}',
            mimeType: widget.sourceFile.mimeType,
          ),
        );
      case CropFailure():
        if (!mounted) return;
        setState(() => _isCropping = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر قص الصورة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(size.width - 24, 980.0);
    final dialogHeight = math.min(size.height - 32, 760.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              color: Colors.black,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'حرّك الصورة وحدد الجزء الظاهر داخل الإطار',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isCropping
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: const Color(0xFF0B0B0B),
                child: Crop(
                  image: widget.imageBytes,
                  controller: _controller,
                  aspectRatio: widget.aspectRatio,
                  fixCropRect: true,
                  interactive: true,
                  radius: 18,
                  baseColor: const Color(0xFF0B0B0B),
                  maskColor: Colors.black.withValues(alpha: 0.55),
                  progressIndicator: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE50914)),
                  ),
                  onCropped: (result) {
                    unawaited(_handleResult(result));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCropping
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isCropping ? null : _crop,
                      icon: _isCropping
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.crop_outlined),
                      label: Text(_isCropping ? 'جارٍ القص...' : 'اعتماد القص'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
