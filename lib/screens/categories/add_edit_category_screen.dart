import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryService = CategoryService();
  
  bool _isLoading = false;
  String _selectedIcon = 'category';
  String _selectedColor = '#00D9FF'; // Cyan from logo

  final List<Map<String, dynamic>> _icons = [
    {'name': 'category', 'icon': Icons.category_rounded},
    {'name': 'fastfood', 'icon': Icons.fastfood_rounded},
    {'name': 'local_drink', 'icon': Icons.local_drink_rounded},
    {'name': 'restaurant', 'icon': Icons.restaurant_rounded},
    {'name': 'cake', 'icon': Icons.cake_rounded},
    {'name': 'coffee', 'icon': Icons.coffee_rounded},
    {'name': 'lunch_dining', 'icon': Icons.lunch_dining_rounded},
    {'name': 'pizza', 'icon': Icons.local_pizza_rounded},
    {'name': 'icecream', 'icon': Icons.icecream_rounded},
    {'name': 'breakfast', 'icon': Icons.breakfast_dining_rounded},
    {'name': 'liquor', 'icon': Icons.liquor_rounded},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag_rounded},
    {'name': 'devices', 'icon': Icons.devices_rounded},
    {'name': 'checkroom', 'icon': Icons.checkroom_rounded},
    {'name': 'sports', 'icon': Icons.sports_soccer_rounded},
  ];

  final List<String> _colors = [
    '#00D9FF', // Cyan (Logo)
    '#FFB800', // Gold (Logo)
    '#10B981', // Green
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#06B6D4', // Cyan Blue
    '#F59E0B', // Orange
    '#3B82F6', // Blue
    '#6366F1', // Indigo
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description;
      _selectedIcon = widget.category!.iconName;
      _selectedColor = widget.category!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Map<String, dynamic> result;

      if (widget.category != null) {
        result = await _categoryService.updateCategory(
          categoryId: widget.category!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          iconName: _selectedIcon,
          color: _selectedColor,
        );
      } else {
        result = await _categoryService.addCategory(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          iconName: _selectedIcon,
          color: _selectedColor,
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? AppTheme.success : AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        if (result['success']) {
          Navigator.pop(context);
        }
      }
    }
  }

  Color _parseColor(String colorString) {
    return Color(int.parse(colorString.replaceAll('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.darkNavy,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Category' : 'Add Category',
          style: const TextStyle(
            color: AppTheme.darkNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _parseColor(_selectedColor).withOpacity(0.1),
                      _parseColor(_selectedColor).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _parseColor(_selectedColor).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: _parseColor(_selectedColor).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        _icons.firstWhere(
                          (i) => i['name'] == _selectedIcon,
                          orElse: () => _icons[0],
                        )['icon'],
                        size: 45,
                        color: _parseColor(_selectedColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nameController.text.isEmpty
                          ? 'Category Preview'
                          : _nameController.text,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _parseColor(_selectedColor),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 400.ms),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'e.g., Beverages',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.label_outline_rounded,
                      color: AppTheme.primaryCyan,
                      size: 20,
                    ),
                  ),
                ),
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.2),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter category description',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppTheme.primaryGold,
                      size: 20,
                    ),
                  ),
                  alignLabelWithHint: true,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2),
              const SizedBox(height: 24),

              // Icon Selection
              _buildSectionHeader('Select Icon', Icons.apps_rounded),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow(),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _icons.asMap().entries.map((entry) {
                    final index = entry.key;
                    final iconData = entry.value;
                    final isSelected = _selectedIcon == iconData['name'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedIcon = iconData['name']);
                      },
                      child: AnimatedContainer(
                        duration: AppAnimations.fast,
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _parseColor(_selectedColor).withOpacity(0.15)
                              : AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? _parseColor(_selectedColor)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData['icon'],
                          color: isSelected
                              ? _parseColor(_selectedColor)
                              : AppTheme.darkGray,
                          size: 26,
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: (index * 30).ms).scale();
                  }).toList(),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 24),

              // Color Selection
              _buildSectionHeader('Select Color', Icons.palette_rounded),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow(),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final color = entry.value;
                    final isSelected = _selectedColor == color;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedColor = color);
                      },
                      child: AnimatedContainer(
                        duration: AppAnimations.fast,
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: _parseColor(color),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.white : Colors.transparent,
                            width: 4,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _parseColor(color).withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppTheme.white,
                                size: 28,
                              )
                            : null,
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: (index * 30).ms).scale();
                  }).toList(),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              const SizedBox(height: 32),

              // Save Button
              Container(
                height: 56,
                decoration: AppTheme.gradientContainer(
                  gradient: LinearGradient(
                    colors: [
                      _parseColor(_selectedColor),
                      _parseColor(_selectedColor).withOpacity(0.8),
                    ],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isEdit ? 'Update Category' : 'Add Category',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_rounded, size: 22),
                          ],
                        ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkNavy,
          ),
        ),
      ],
    );
  }
}