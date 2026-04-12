import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/daily_menu.dart';
import '../../models/daily_menu_item.dart';
import '../../services/daily_menu_service.dart';
import '../../services/profile_service.dart';
import '../../utils/constants.dart';
import '../../utils/supabase_config.dart';
import 'package:intl/intl.dart';

/// Daily Menu Management Screen
/// Allows cooks to manage their daily menu offerings
class DailyMenuManagementScreen extends StatefulWidget {
  const DailyMenuManagementScreen({super.key});

  @override
  State<DailyMenuManagementScreen> createState() =>
      _DailyMenuManagementScreenState();
}

class _DailyMenuManagementScreenState extends State<DailyMenuManagementScreen> {
  final _menuService = DailyMenuService();
  final _profileService = ProfileService();
  final _scrollController = ScrollController();
  final Map<MealCategory, GlobalKey> _categoryKeys = {
    MealCategory.special: GlobalKey(),
    MealCategory.breakfast: GlobalKey(),
    MealCategory.lunch: GlobalKey(),
    MealCategory.dinner: GlobalKey(),
    MealCategory.snacks: GlobalKey(),
  };

  DateTime _selectedDate = DateTime.now();
  DailyMenu? _currentMenu;
  bool _isLoading = true;
  MealCategory? _selectedCategory;
  String? _cookId;

  @override
  void initState() {
    super.initState();
    _initAndLoadMenu();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initAndLoadMenu() async {
    final cook = await _profileService.getCurrentProfile();
    _cookId = cook?.id;
    await _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    if (_cookId != null) {
      final menu = await _menuService.getDailyMenu(_selectedDate, _cookId!);
      setState(() {
        _currentMenu = menu;
        _isLoading = false;
      });
    } else {
      setState(() {
        _currentMenu = DailyMenu(date: _selectedDate, items: []);
        _isLoading = false;
      });
    }
  }

  Future<void> _updateItem(DailyMenuItem item) async {
    await _menuService.updateMenuItem(_selectedDate, item);
    await _loadMenu();
  }

  Future<void> _deleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dish'),
        content: const Text('Are you sure you want to remove this dish from today\'s menu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await _menuService.deleteDailyMenuItem(itemId);
      if (success) {
        await _loadMenu();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete item'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _publishMenu() async {
    if (_cookId == null || _currentMenu == null) return;
    final success = await _menuService.publishMenu(
      _selectedDate,
      _cookId!,
      _currentMenu!.items,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Menu published & synced successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToCategory(MealCategory category) {
    final key = _categoryKeys[category];
    if (key?.currentContext != null) {
      setState(() => _selectedCategory = category);
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showAddDishBottomSheet(MealCategory category) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '10');
    final formKey = GlobalKey<FormState>();
    XFile? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      category == MealCategory.special ? 'Add Special' : 'Add Dish',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    // Image Picker
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (image != null) {
                            setModalState(() => selectedImage = image);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb 
                                    ? Image.network(selectedImage!.path, fit: BoxFit.cover)
                                    : Image.file(File(selectedImage!.path), fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    const Text('Add Dish Photo *', style: TextStyle(color: Color(0xFF94A3B8))),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Dish Name *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter dish name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Price (₹) *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter price' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isUploading ? null : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (selectedImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a photo')),
                            );
                            return;
                          }
                          if (_cookId == null) return;

                          setModalState(() => isUploading = true);

                          try {
                            final timestamp = DateTime.now().millisecondsSinceEpoch;
                            final path = '$_cookId/daily/dish_$timestamp.jpg';
                            final bytes = await selectedImage!.readAsBytes();
                            
                            await SupabaseConfig.client.storage
                                .from('kitchen-photos')
                                .uploadBinary(path, bytes);

                            final imageUrl = SupabaseConfig.client.storage
                                .from('kitchen-photos')
                                .getPublicUrl(path);

                            final item = DailyMenuItem(
                              id: '',
                              name: nameController.text.trim(),
                              description: descController.text.trim(),
                              imageUrl: imageUrl,
                              category: category,
                              price: double.parse(priceController.text.trim()),
                              quantity: int.tryParse(qtyController.text.trim()) ?? 10,
                              isAvailable: true,
                            );

                            final success = await _menuService.addDailyMenuItem(
                              _selectedDate,
                              _cookId!,
                              item,
                            );

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (success) await _loadMenu();
                          } catch (e) {
                            debugPrint('Error adding daily item: $e');
                          } finally {
                            setModalState(() => isUploading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isUploading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              category == MealCategory.special ? 'Add Special' : 'Add Dish',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          _buildDateSelector(),
          _buildCategoryFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMenuContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
              ),
              const Expanded(
                child: Text(
                  'Manage Daily Menu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.person, size: 20, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 72,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 7,
          itemBuilder: (context, index) {
            final date = DateTime.now().add(Duration(days: index - 1));
            final isSelected = _isSameDay(date, _selectedDate);
            final isToday = _isSameDay(date, DateTime.now());

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildDateCard(date, isSelected, isToday),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateCard(DateTime date, bool isSelected, bool isToday) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
        _loadMenu();
      },
      child: Container(
        width: 64,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday ? 'Today' : DateFormat('EEE').format(date),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: isSelected ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('Specials', MealCategory.special),
            const SizedBox(width: 8),
            _buildFilterChip('Breakfast', MealCategory.breakfast),
            const SizedBox(width: 8),
            _buildFilterChip('Lunch', MealCategory.lunch),
            const SizedBox(width: 8),
            _buildFilterChip('Dinner', MealCategory.dinner),
            const SizedBox(width: 8),
            _buildFilterChip('Snacks', MealCategory.snacks),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, MealCategory category) {
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () => _scrollToCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContent() {
    if (_currentMenu == null) {
      return const Center(child: Text('No menu available'));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's Specials
          Container(
            key: _categoryKeys[MealCategory.special],
            child: _buildCategorySection(
              'Today\'s Specials',
              _currentMenu!.specials,
              MealCategory.special,
              isPrimary: true,
            ),
          ),
          const SizedBox(height: 24),

          // Breakfast
          Container(
            key: _categoryKeys[MealCategory.breakfast],
            child: _buildCategorySection(
              'Breakfast',
              _currentMenu!.breakfastItems,
              MealCategory.breakfast,
            ),
          ),
          const SizedBox(height: 24),

          // Lunch
          Container(
            key: _categoryKeys[MealCategory.lunch],
            child: _buildCategorySection(
              'Lunch',
              _currentMenu!.lunchItems,
              MealCategory.lunch,
            ),
          ),
          const SizedBox(height: 24),

          // Dinner
          Container(
            key: _categoryKeys[MealCategory.dinner],
            child: _buildCategorySection(
              'Dinner',
              _currentMenu!.dinnerItems,
              MealCategory.dinner,
            ),
          ),
          const SizedBox(height: 24),

          // Snacks
          Container(
            key: _categoryKeys[MealCategory.snacks],
            child: _buildCategorySection(
              'Snacks',
              _currentMenu!.snackItems,
              MealCategory.snacks,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    String title,
    List<DailyMenuItem> items,
    MealCategory category, {
    bool isPrimary = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isPrimary ? 16 : 0),
      decoration: isPrimary
          ? BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? AppColors.primary : Colors.black,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddDishBottomSheet(category),
                icon: Icon(
                  Icons.add_circle,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: Text(
                  isPrimary ? 'Add Special' : 'Add Dish',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDishCard(item),
            ),
          ),
          if (isPrimary) _buildAddAnotherButton(category),
        ],
      ),
    );
  }

  Widget _buildDishCard(DailyMenuItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image, name, toggle
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: item.isAvailable
                        ? null
                        : const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: item.isAvailable,
                          onChanged: (value) {
                            _updateItem(item.copyWith(isAvailable: value));
                          },
                          activeTrackColor: AppColors.secondary,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _deleteItem(item.id),
                        ),
                      ],
                    ),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Price and quantity
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRICE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.price.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QTY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: item.isAvailable && item.quantity > 0
                                ? () {
                                    _updateItem(
                                      item.copyWith(
                                        quantity: item.quantity - 1,
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.remove, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.quantity.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: item.isAvailable
                                ? () {
                                    _updateItem(
                                      item.copyWith(
                                        quantity: item.quantity + 1,
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.add, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddAnotherButton(MealCategory category) {
    return GestureDetector(
      onTap: () => _showAddDishBottomSheet(category),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'Add another special',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final earnings = _currentMenu?.totalEarnings ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Potential Earnings',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  '₹${earnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _publishMenu,
                icon: const Icon(Icons.check_circle, size: 24),
                label: const Text(
                  'Publish Menu Updates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
