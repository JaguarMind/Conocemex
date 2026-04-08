import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '/core/di/setup_dependencies.dart';
import '/core/services/cloudinary_service.dart';
import '/core/services/gemini_service.dart';
import '/core/services/image_picker_service.dart';
import '/features/offering/presentation/viewmodels/offerings_viewmodel.dart';

class CreateOfferingPage extends StatefulWidget {
  final String businessId;
  const CreateOfferingPage({super.key, required this.businessId});

  @override
  State<CreateOfferingPage> createState() => _CreateOfferingPageState();
}

class _CreateOfferingPageState extends State<CreateOfferingPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  late final OfferingsViewModel _viewModel;
  String _selectedType = 'product';
  String _selectedPriceType = 'fixed';

  // Imagen del producto (Cloudinary)
  bool _isUploading = false;
  Uint8List? _productImage;
  String? _uploadedImageUrl;

  // IA
  bool _isAnalyzing = false;

  bool get _hasGemini => GetIt.instance.isRegistered<GeminiService>();

  static const _priceTypes = {
    'fixed': 'Precio fijo',
    'from': 'Desde',
    'hourly': 'Por hora',
    'per_person': 'Por persona',
    'quote': 'Cotizar',
  };

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<OfferingsViewModel>();
    _viewModel.reset();
    _viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_viewModel.isSuccess) {
      _viewModel.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
      return;
    }
    if (_viewModel.error != null) {
      final error = _viewModel.error!;
      _viewModel.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
    setState(() {});
  }

  // ─── UPLOAD solo a Cloudinary ───
  Future<void> _pickProductImage(bool fromCamera) async {
    final picker = getIt<ImagePickerService>();
    final bytes = fromCamera ? await picker.pickFromCamera() : await picker.pickFromGallery();
    if (bytes == null || !mounted) return;

    setState(() { _isUploading = true; _productImage = bytes; });

    try {
      final url = await getIt<CloudinaryService>().uploadImage(bytes, folder: CloudinaryFolder.offerings);
      _uploadedImageUrl = url;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen subida'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isUploading = false);
  }

  // ─── IA autocompletar ───
  Future<void> _analyzeWithAi(bool fromCamera) async {
    final picker = getIt<ImagePickerService>();
    final bytes = fromCamera ? await picker.pickFromCamera() : await picker.pickFromGallery();
    if (bytes == null || !mounted) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await getIt<GeminiService>().analyzeOfferingImage(bytes);
      if (!mounted) return;
      if (result['name'] != null) _nameController.text = result['name'] as String;
      if (result['description'] != null) _descriptionController.text = result['description'] as String;
      if (result['price_mxn'] != null) {
        final price = (result['price_mxn'] as num).toDouble();
        if (price > 0) _priceController.text = price.toString();
      }
      if (result['type'] != null) {
        final t = result['type'] as String;
        if (t == 'product' || t == 'service') _selectedType = t;
      }
      if (result['price_type'] != null) {
        final pt = result['price_type'] as String;
        if (_priceTypes.containsKey(pt)) _selectedPriceType = pt;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campos autocompletados'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error IA: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isAnalyzing = false);
  }

  void _showSourceSheet({required String title, required void Function(bool) onPick}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue, fontSize: 16)),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.camera_alt, color: _primaryGreen)),
              title: const Text('Tomar foto', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(ctx); onPick(true); },
            ),
            ListTile(
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.photo_library, color: _primaryGreen)),
              title: const Text('Elegir de galeria', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(ctx); onPick(false); },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _darkBlue), onPressed: () => Navigator.pop(context)),
        title: const Text('Nuevo Producto/Servicio', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _darkBlue)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Foto del producto
              _buildPhotoSection(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // 2. Boton IA separado
                  if (_hasGemini) ...[
                    _buildAiButton(),
                    const SizedBox(height: 20),
                  ],

                  // 3. Formulario
                  _buildLabel('TIPO'),
                  const SizedBox(height: 4),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'product', label: Text('Producto'), icon: Icon(Icons.shopping_bag)),
                      ButtonSegment(value: 'service', label: Text('Servicio'), icon: Icon(Icons.design_services)),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (v) => setState(() => _selectedType = v.first),
                    style: SegmentedButton.styleFrom(selectedBackgroundColor: _primaryGreen.withValues(alpha: 0.15), selectedForegroundColor: _darkBlue),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('NOMBRE'),
                  _buildTextField(controller: _nameController, hint: 'Ej: Tacos al pastor', validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null),
                  const SizedBox(height: 18),

                  _buildLabel('DESCRIPCION'),
                  _buildTextField(controller: _descriptionController, hint: 'Describe tu producto o servicio', maxLines: 3),
                  const SizedBox(height: 18),

                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildLabel('PRECIO (MXN)'),
                      _buildTextField(controller: _priceController, hint: '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Invalido';
                        return null;
                      }),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildLabel('TIPO PRECIO'),
                      DropdownButtonFormField<String>(
                        value: _selectedPriceType,
                        decoration: InputDecoration(filled: true, fillColor: _bgGrey, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
                        items: _priceTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14)))).toList(),
                        onChanged: (v) => setState(() => _selectedPriceType = v ?? 'fixed'),
                      ),
                    ])),
                  ]),

                  if (_selectedType == 'service') ...[
                    const SizedBox(height: 18),
                    _buildLabel('DURACION (MINUTOS)'),
                    _buildTextField(controller: _durationController, hint: 'Ej: 60', keyboardType: TextInputType.number),
                  ],

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _viewModel.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, foregroundColor: _darkBlue, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), elevation: 8, shadowColor: _primaryGreen.withValues(alpha: 0.4)),
                      child: _viewModel.isLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _darkBlue))
                          : const Text('Guardar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Photo section (solo Cloudinary) ───
  Widget _buildPhotoSection() {
    if (_isUploading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0), height: 180,
        decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: _primaryGreen), SizedBox(height: 12),
          Text('Subiendo imagen...', style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue)),
        ])),
      );
    }
    if (_productImage != null) {
      return GestureDetector(
        onTap: () => _showSourceSheet(title: 'Foto del producto', onPick: _pickProductImage),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0), height: 180,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: DecorationImage(image: MemoryImage(_productImage!), fit: BoxFit.cover)),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent])),
            alignment: Alignment.bottomCenter, padding: const EdgeInsets.all(14),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: Colors.white, size: 18), SizedBox(width: 6), Text('Cambiar foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))]),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _showSourceSheet(title: 'Foto del producto', onPick: _pickProductImage),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0), height: 180,
        decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(16), border: Border.all(color: _darkBlue.withValues(alpha: 0.08), width: 2)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.add_a_photo, color: _primaryGreen, size: 26)),
          const SizedBox(height: 12),
          const Text('Sube una foto del producto', style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 15)),
          const SizedBox(height: 4),
          Text('JPG, PNG', style: TextStyle(fontSize: 12, color: _darkBlue.withValues(alpha: 0.35))),
        ]),
      ),
    );
  }

  // ─── Boton IA separado ───
  Widget _buildAiButton() {
    if (_isAnalyzing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: _primaryGreen.withValues(alpha: 0.2))),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen)),
          SizedBox(width: 12),
          Text('Analizando con IA...', style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue)),
        ]),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _showSourceSheet(title: 'Autocompletar con IA', onPick: _analyzeWithAi),
      icon: const Icon(Icons.auto_awesome, color: _primaryGreen, size: 20),
      label: const Text('Autocompletar campos con IA', style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: _primaryGreen.withValues(alpha: 0.4), width: 2),
        backgroundColor: _primaryGreen.withValues(alpha: 0.04),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _darkBlue.withValues(alpha: 0.45), letterSpacing: 1.5)),
  );

  Widget _buildTextField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: _darkBlue.withValues(alpha: 0.25), fontWeight: FontWeight.w500),
        filled: true, fillColor: _bgGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final duration = _durationController.text.trim();
    _viewModel.createOffering(
      businessId: widget.businessId, type: _selectedType, name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      priceMxn: double.parse(_priceController.text.trim()), priceType: _selectedPriceType,
      durationMin: duration.isEmpty ? null : int.parse(duration),
      imageUrl: _uploadedImageUrl,
    );
  }
}
