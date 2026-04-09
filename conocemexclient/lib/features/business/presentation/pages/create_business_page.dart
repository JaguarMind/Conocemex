import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '/core/di/setup_dependencies.dart';
import '/core/services/cloudinary_service.dart';
import '/core/services/gemini_service.dart';
import '/core/services/image_picker_service.dart';
import '/features/business/presentation/pages/map_picker_page.dart';
import '/features/business/presentation/viewmodels/create_business_viewmodel.dart';
import '/features/category/domain/entities/category_entity.dart';
import '/l10n/app_localizations.dart';

class CreateBusinessPage extends StatefulWidget {
  const CreateBusinessPage({super.key});

  @override
  State<CreateBusinessPage> createState() => _CreateBusinessPageState();
}

class _CreateBusinessPageState extends State<CreateBusinessPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  late final CreateBusinessViewModel _viewModel;
  String? _selectedCategoryId;

  // Imagen del negocio (Cloudinary)
  bool _isUploading = false;
  Uint8List? _businessImage;
  String? _uploadedImageUrl;

  // IA para autocompletar
  bool _isAnalyzing = false;

  bool get _hasGemini => GetIt.instance.isRegistered<GeminiService>();

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<CreateBusinessViewModel>();
    _viewModel.reset();
    _viewModel.loadCategories();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
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

  // ─── UPLOAD IMAGEN (solo sube a Cloudinary, no analiza) ───
  Future<void> _pickBusinessImage(bool fromCamera) async {
    final picker = getIt<ImagePickerService>();
    final bytes = fromCamera
        ? await picker.pickFromCamera()
        : await picker.pickFromGallery();
    if (bytes == null || !mounted) return;

    setState(() {
      _isUploading = true;
      _businessImage = bytes;
    });

    try {
      final cloudinary = getIt<CloudinaryService>();
      final url = await cloudinary.uploadImage(
        bytes,
        folder: CloudinaryFolder.businesses,
      );
      _uploadedImageUrl = url;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen subida correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isUploading = false);
  }

  // ─── IA AUTOCOMPLETAR (toma foto y analiza con IA) ───
  Future<void> _analyzeWithAi(bool fromCamera) async {
    final picker = getIt<ImagePickerService>();
    final bytes = fromCamera
        ? await picker.pickFromCamera()
        : await picker.pickFromGallery();
    if (bytes == null || !mounted) return;

    setState(() => _isAnalyzing = true);

    try {
      final gemini = getIt<GeminiService>();
      final result = await gemini.analyzeBusinessImage(bytes);
      if (!mounted) return;

      if (result['name'] != null) _nameController.text = result['name'] as String;
      if (result['phone'] != null) _phoneController.text = result['phone'] as String;
      if (result['address'] != null) _addressController.text = result['address'] as String;
      if (result['latitude'] != null) _latController.text = result['latitude'].toString();
      if (result['longitude'] != null) _lngController.text = result['longitude'].toString();

      final slug = result['category_slug'] as String?;
      if (slug != null && _viewModel.categories.isNotEmpty) {
        final match = _viewModel.categories.cast<CategoryEntity?>().firstWhere(
              (c) => c!.slug == slug,
              orElse: () => null,
            );
        if (match != null) _selectedCategoryId = match.id;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campos autocompletados con IA'),
          backgroundColor: Colors.green,
        ),
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

  void _showImagePickerSheet() {
    _showSourceSheet(
      title: 'Foto del negocio',
      onCamera: () => _pickBusinessImage(true),
      onGallery: () => _pickBusinessImage(false),
    );
  }

  void _showAiSheet() {
    _showSourceSheet(
      title: 'Autocompletar con IA',
      onCamera: () => _analyzeWithAi(true),
      onGallery: () => _analyzeWithAi(false),
    );
  }

  void _showSourceSheet({
    required String title,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue, fontSize: 16)),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: _primaryGreen),
                ),
                title: const Text('Tomar foto', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(ctx); onCamera(); },
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: _primaryGreen),
                ),
                title: const Text('Elegir de galeria', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(ctx); onGallery(); },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registro de Negocio',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _darkBlue),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── 1. Zona de foto del negocio (Cloudinary) ───
              _buildPhotoSection(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 2. Boton IA (separado) ───
                    if (_hasGemini) ...[
                      _buildAiButton(),
                      const SizedBox(height: 20),
                    ],

                    // ─── 3. Campos del formulario ───
                    _buildLabel('NOMBRE DEL NEGOCIO'),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Ej: Tacos Don Pepe',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 18),

                    _buildLabel('CATEGORIA'),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 18),

                    _buildLabel('TELEFONO'),
                    _buildTextField(
                      controller: _phoneController,
                      hint: '+52 55 1234 5678',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),

                    _buildLabel('UBICACION'),
                    // Boton para abrir mapa
                    GestureDetector(
                      onTap: _openMapPicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bgGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: _addressController.text.isEmpty
                              ? Border.all(color: _darkBlue.withValues(alpha: 0.08))
                              : Border.all(color: _primaryGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: _primaryGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.map, color: _primaryGreen, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_addressController.text.isNotEmpty) ...[
                                    Text(
                                      _addressController.text,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue, fontSize: 13),
                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_latController.text.isNotEmpty)
                                      Text(
                                        '${_latController.text}, ${_lngController.text}',
                                        style: TextStyle(fontSize: 11, color: _darkBlue.withValues(alpha: 0.35)),
                                      ),
                                  ] else
                                    Text(
                                      AppLocalizations.of(context)!.tapToSelectLocation,
                                      style: TextStyle(fontWeight: FontWeight.w600, color: _darkBlue.withValues(alpha: 0.35), fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: _darkBlue.withValues(alpha: 0.3)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ─── 4. Boton Confirmar ───
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _viewModel.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: _darkBlue,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 8,
                          shadowColor: _primaryGreen.withValues(alpha: 0.4),
                        ),
                        child: _viewModel.isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _darkBlue))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 20),
                                  SizedBox(width: 8),
                                  Text('Confirmar y Publicar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Al publicar aceptas los terminos de uso.',
                        style: TextStyle(fontSize: 12, color: _darkBlue.withValues(alpha: 0.3), fontWeight: FontWeight.w500),
                      ),
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

  Future<void> _openMapPicker() async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(initialLat: lat, initialLng: lng),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latController.text = result.latitude.toStringAsFixed(6);
        _lngController.text = result.longitude.toStringAsFixed(6);
        if (result.address != null && result.address!.isNotEmpty) {
          _addressController.text = result.address!;
        }
      });
    }
  }

  // ─── Zona de foto (solo upload a Cloudinary) ───
  Widget _buildPhotoSection() {
    if (_isUploading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        height: 150,
        decoration: BoxDecoration(
          color: _primaryGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryGreen.withValues(alpha: 0.2)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 3, color: _primaryGreen),
            SizedBox(height: 14),
            Text('Subiendo imagen...', style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 15)),
          ],
        ),
      );
    }

    if (_businessImage != null) {
      return GestureDetector(
        onTap: _showImagePickerSheet,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(image: MemoryImage(_businessImage!), fit: BoxFit.cover),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
              ),
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                const Text('Cambiar foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                if (_uploadedImageUrl != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: _primaryGreen, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Subida', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Estado vacio
    return GestureDetector(
      onTap: _showImagePickerSheet,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        height: 150,
        decoration: BoxDecoration(
          color: _bgGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _darkBlue.withValues(alpha: 0.08), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.camera_alt, color: _primaryGreen, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Sube una foto de tu\nlocal o negocio',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Formatos: JPG, PNG',
              style: TextStyle(fontSize: 12, color: _darkBlue.withValues(alpha: 0.35)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Boton IA (separado de la foto) ───
  Widget _buildAiButton() {
    if (_isAnalyzing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primaryGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primaryGreen.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen)),
            SizedBox(width: 12),
            Text('Analizando imagen con IA...', style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue)),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _showAiSheet,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: _primaryGreen.withValues(alpha: 0.4), width: 2),
          backgroundColor: _primaryGreen.withValues(alpha: 0.04),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: _primaryGreen, size: 18),
            SizedBox(width: 8),
            Text('Autocompletar con IA', style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _darkBlue.withValues(alpha: 0.45), letterSpacing: 1.5)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _darkBlue.withValues(alpha: 0.25), fontWeight: FontWeight.w500),
        filled: true, fillColor: _bgGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = _viewModel.categories;
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        hintText: 'Selecciona una categoria',
        hintStyle: TextStyle(color: _darkBlue.withValues(alpha: 0.25), fontWeight: FontWeight.w500),
        filled: true, fillColor: _bgGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: categories.map((CategoryEntity cat) {
        return DropdownMenuItem<String>(
          value: cat.id,
          child: Text('${cat.icon ?? ''} ${cat.name}'.trim(), style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategoryId = value),
      validator: (v) => v == null ? 'Selecciona una categoria' : null,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.tapToSelectLocation),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _viewModel.createBusiness(
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId!,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      latitude: lat,
      longitude: lng,
      coverImageUrl: _uploadedImageUrl,
    );
  }
}
