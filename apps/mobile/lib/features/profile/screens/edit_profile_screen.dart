import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Profile? initialProfile;

  const EditProfileScreen({
    Key? key,
    required this.userId,
    this.initialProfile,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final FocusNode _nameFocus;
  late final FocusNode _heightFocus;
  late final FocusNode _weightFocus;
  DateTime? _birthDate;
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  String? _errorMessage;
  late final ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(userId: widget.userId);
    _nameController = TextEditingController(text: widget.initialProfile?.name);
    _heightController = TextEditingController(
      text: widget.initialProfile?.height?.toString(),
    );
    _weightController = TextEditingController(
      text: widget.initialProfile?.weight?.toString(),
    );
    _birthDate = widget.initialProfile?.birthDate;

    _nameFocus = FocusNode();
    _heightFocus = FocusNode();
    _weightFocus = FocusNode();

    _nameFocus.addListener(_handleNameFocusChange);
    _heightFocus.addListener(_handleHeightFocusChange);
    _weightFocus.addListener(_handleWeightFocusChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _nameFocus.removeListener(_handleNameFocusChange);
    _heightFocus.removeListener(_handleHeightFocusChange);
    _weightFocus.removeListener(_handleWeightFocusChange);
    _nameFocus.dispose();
    _heightFocus.dispose();
    _weightFocus.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  void _handleNameFocusChange() {
    if (!_nameFocus.hasFocus) {
      _saveName();
    }
  }

  void _handleHeightFocusChange() {
    if (!_heightFocus.hasFocus) {
      _saveHeight();
    }
  }

  void _handleWeightFocusChange() {
    if (!_weightFocus.hasFocus) {
      _saveWeight();
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name == widget.initialProfile?.name) return;
    
    if (name.length < 2) {
      _showError('Имя должно содержать минимум 2 символа');
      return;
    }

    await _updateField(() => _profileService.updateName(name));
  }

  Future<void> _saveHeight() async {
    final heightText = _heightController.text.trim();
    if (heightText.isEmpty) return;

    final height = double.tryParse(heightText);
    if (height == null) {
      _showError('Некорректное значение роста');
      return;
    }

    if (height < 50 || height > 250) {
      _showError('Рост должен быть от 50 до 250 см');
      return;
    }

    if (height == widget.initialProfile?.height) return;

    await _updateField(() => _profileService.updateHeight(height));
  }

  Future<void> _saveWeight() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) return;

    final weight = double.tryParse(weightText);
    if (weight == null) {
      _showError('Некорректное значение веса');
      return;
    }

    if (weight < 3 || weight > 300) {
      _showError('Вес должен быть от 3 до 300 кг');
      return;
    }

    if (weight == widget.initialProfile?.weight) return;

    await _updateField(() => _profileService.updateWeight(weight));
  }

  Future<void> _updateField(Future<void> Function() updateFn) async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    try {
      await updateFn();
    } catch (e) {
      _showError('Не удалось сохранить изменения: ${e.toString()}');
    } finally {
      if (mounted) {
        _isLoading.value = false;
      }
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null && picked != _birthDate) {
      setState(() => _birthDate = picked);
      await _updateField(() => _profileService.updateBirthDate(picked));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  RepaintBoundary(
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Имя',
                        hintText: 'Введите ваше имя',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(height: 24),
                  RepaintBoundary(
                    child: TextField(
                      readOnly: true,
                      onTap: _selectDate,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Дата рождения',
                        hintText: 'Выберите дату рождения',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color: theme.primaryColor,
                        ),
                      ),
                      controller: TextEditingController(
                        text: _birthDate != null ? _formatDate(_birthDate!) : '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  RepaintBoundary(
                    child: TextField(
                      controller: _heightController,
                      focusNode: _heightFocus,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Рост',
                        hintText: 'Введите ваш рост в см',
                        suffixText: 'см',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  RepaintBoundary(
                    child: TextField(
                      controller: _weightController,
                      focusNode: _weightFocus,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Вес',
                        hintText: 'Введите ваш вес в кг',
                        suffixText: 'кг',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}$')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isLoading,
            builder: (context, isLoading, child) {
              return isLoading ? const _LoadingIndicator() : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
} 