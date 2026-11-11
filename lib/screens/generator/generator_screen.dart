import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/qr_provider.dart';
import '../../utils/app_theme.dart';

import 'package:share_plus/share_plus.dart';

import '../../services/qr_export_service.dart';
import '../../models/qr_history_model.dart';
import '../../services/qr_history_service.dart';
import '../../models/saved_qr_model.dart';
import '../../services/saved_qr_service.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final QRExportService _exportService = QRExportService();

  String _selectedType = 'Text';
  String _wifiSecurity = 'WPA';
  Color _qrColor = const Color(0xFF241B3A);
  Color _backgroundColor = Colors.white;

  final List<Color> _qrColors = [
    Color(0xFF241B3A), // Midnight Plum
    Color(0xFF7655E8), // Brand Violet
    Color(0xFF244C66), // Slate Blue
    Color(0xFF1F6B57), // Forest Green
  ];

  final List<Color> _backgroundColors = [
    Colors.white,
    Color(0xFFF3EFFF), // Soft Lavender
    Color(0xFFEFF5FA), // Cool Mist
    Color(0xFFF8F5EF), // Warm Ivory
  ];

  final Map<String, TextEditingController> _controllers = {
    'text': TextEditingController(),
    'url': TextEditingController(),
    'phone': TextEditingController(),
    'email': TextEditingController(),
    'message': TextEditingController(),
    'ssid': TextEditingController(),
    'password': TextEditingController(),
    'name': TextEditingController(),
    'latitude': TextEditingController(),
    'longitude': TextEditingController(),
  };

  final List<String> _types = [
    'Text',
    'Website',
    'Phone',
    'Email',
    'SMS',
    'Wi-Fi',
    'Contact',
    'Location',
    'Social',
  ];
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<QRProvider>().clearGeneratedContent();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildInput(
    String key,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter $label',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildColorSelector({
    required String title,
    required List<Color> colors,
    required Color selectedColor,
    required ValueChanged<Color> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: colors.map((color) {
            final isSelected = color == selectedColor;

            return GestureDetector(
              onTap: () => onSelected(color),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade400,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    final icons = <String, IconData>{
      'Text': Icons.text_fields_rounded,
      'Website': Icons.language_rounded,
      'Phone': Icons.phone_rounded,
      'Email': Icons.email_outlined,
      'SMS': Icons.sms_outlined,
      'Wi-Fi': Icons.wifi_rounded,
      'Contact': Icons.person_outline_rounded,
      'Location': Icons.location_on_outlined,
      'Social': Icons.share_outlined,
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _types.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final type = _types[index];
        final isSelected = _selectedType == type;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedType = type;
            });

            context.read<QRProvider>().clearGeneratedContent();
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF0EBFF)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.white12 : const Color(0xFFEAE7F0)),
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icons[type],
                  size: 25,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  type,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF5B43BD)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFields() {
    switch (_selectedType) {
      case 'Text':
        return [_buildInput('text', 'Text', maxLines: 3)];

      case 'Website':
      case 'Social':
        return [
          _buildInput('url', 'Website URL', keyboardType: TextInputType.url),
        ];

      case 'Phone':
        return [
          _buildInput(
            'phone',
            'Phone Number',
            keyboardType: TextInputType.phone,
          ),
        ];

      case 'Email':
        return [
          _buildInput(
            'email',
            'Email Address',
            keyboardType: TextInputType.emailAddress,
          ),
        ];

      case 'SMS':
        return [
          _buildInput(
            'phone',
            'Phone Number',
            keyboardType: TextInputType.phone,
          ),
          _buildInput('message', 'Message', maxLines: 3),
        ];

      case 'Wi-Fi':
        return [
          _buildInput('ssid', 'Network Name (SSID)'),
          _buildInput('password', 'Wi-Fi Password'),
          DropdownButtonFormField<String>(
            initialValue: _wifiSecurity,
            decoration: InputDecoration(
              labelText: 'Security Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('No Password')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _wifiSecurity = value);
              }
            },
          ),
        ];

      case 'Contact':
        return [
          _buildInput('name', 'Full Name'),
          _buildInput(
            'phone',
            'Phone Number',
            keyboardType: TextInputType.phone,
          ),
          _buildInput(
            'email',
            'Email Address',
            keyboardType: TextInputType.emailAddress,
          ),
        ];

      case 'Location':
        return [
          _buildInput(
            'latitude',
            'Latitude',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
          _buildInput(
            'longitude',
            'Longitude',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
          ),
        ];

      default:
        return [];
    }
  }

  Future<void> _shareQR() async {
    final content = context.read<QRProvider>().generatedContent;

    if (content.isEmpty) return;

    try {
      final imageBytes = await _exportService.generateImage(
        content: content,
        qrColor: _qrColor,
        backgroundColor: _backgroundColor,
      );

      final file = await _exportService.saveImage(imageBytes);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'My QR Code'),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share QR code. Please try again.'),
        ),
      );
    }
  }

  Future<void> _saveQRToGallery() async {
    final content = context.read<QRProvider>().generatedContent;

    if (content.isEmpty) return;

    try {
      final imageBytes = await _exportService.generateImage(
        content: content,
        qrColor: _qrColor,
        backgroundColor: _backgroundColor,
      );

      await _exportService.saveToGallery(imageBytes);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code saved to Gallery successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save QR code. Please try again.'),
        ),
      );
    }
  }

  Future<void> _saveToSavedQRs() async {
    final content = context.read<QRProvider>().generatedContent;

    if (content.isEmpty) return;

    try {
      final result = await SavedQRService.instance.saveQR(
        SavedQRModel(
          content: content,
          qrType: _selectedType,
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !result
                ? 'QR code already exists in Saved QR Codes.'
                : 'QR code added to Saved QR Codes successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save QR code. Please try again.'),
        ),
      );
    }
  }

  void _generateQR() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final values = {
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
      'security': _wifiSecurity,
    };

    context.read<QRProvider>().generate(type: _selectedType, values: values);

    final content = context.read<QRProvider>().generatedContent;

    if (content.isNotEmpty) {
      QRHistoryService.instance.addHistory(
        QRHistoryModel(
          content: content,
          qrType: _selectedType,
          actionType: 'Generated',
          createdAt: DateTime.now(),
        ),
      );
    }

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final qrProvider = context.watch<QRProvider>();
    final content = qrProvider.generatedContent;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generate QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Your QR Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a type and enter the information you want to share.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            _buildTypeSelector(),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white12
                      : const Color(0xFFEAE7F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  Form(
                    key: _formKey,
                    child: Column(children: _buildFields()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _generateQR,
                icon: const Icon(Icons.qr_code_2),
                label: const Text(
                  'Generate QR Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            if (content.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Your QR Code',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              _buildColorSelector(
                title: 'QR Code Color',
                colors: _qrColors,
                selectedColor: _qrColor,
                onSelected: (color) {
                  setState(() => _qrColor = color);
                },
              ),
              const SizedBox(height: 20),
              _buildColorSelector(
                title: 'Background Color',
                colors: _backgroundColors,
                selectedColor: _backgroundColor,
                onSelected: (color) {
                  setState(() => _backgroundColor = color);
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: content,
                    version: QrVersions.auto,
                    size: 220,
                    gapless: true,
                    // ignore: deprecated_member_use
                    foregroundColor: _qrColor,
                    backgroundColor: _backgroundColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'QR code generated successfully!',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveQRToGallery,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text(
                          'Export',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveToSavedQRs,
                        icon: const Icon(Icons.bookmark_outline_rounded),
                        label: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareQR,
                        icon: const Icon(Icons.share_rounded),
                        label: const Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
