import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/statch_logo.dart';

/// Profile Screen for user details with custom avatar support
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PreferencesService _prefsService = PreferencesService();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _nameController;
  DateTime? _selectedDate;
  int _selectedAvatarIndex = 0;
  String? _customImagePath;
  bool _hasChanges = false;

  // Financial-themed avatar icons
  static const List<IconData> _avatarIcons = [
    Icons.trending_up_rounded,        // Stocks
    Icons.account_balance_rounded,    // Bank/Finance
    Icons.pie_chart_rounded,          // Portfolio
    Icons.monetization_on_rounded,    // Money/Gold
    Icons.candlestick_chart_rounded,  // Trading
    Icons.analytics_rounded,          // Analytics
    Icons.show_chart_rounded,         // Charts
    Icons.savings_rounded,            // Savings
    Icons.currency_exchange_rounded,  // Exchange
    Icons.workspace_premium_rounded,  // Premium/Gold
    Icons.diamond_rounded,            // Wealth
    Icons.rocket_launch_rounded,      // Growth
  ];

  static const List<String> _avatarLabels = [
    'Trader',
    'Banker',
    'Investor',
    'Gold',
    'Charts',
    'Analyst',
    'Stocks',
    'Saver',
    'Exchange',
    'Premium',
    'Wealth',
    'Growth',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _prefsService.userName);
    _selectedDate = _prefsService.userDob;
    _selectedAvatarIndex = _prefsService.userAvatarIndex;
    _customImagePath = _prefsService.customAvatarPath;
    
    _nameController.addListener(_onChanges);
  }

  void _onChanges() {
    if (mounted) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onChanges);
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.robinhoodGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImagePickerSheet(context),
    );
  }

  Widget _buildImagePickerSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose Photo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPickerOption(
                context,
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromGallery();
                },
              ),
              _buildPickerOption(
                context,
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromCamera();
                },
              ),
              if (_customImagePath != null)
                _buildPickerOption(
                  context,
                  icon: Icons.delete_rounded,
                  label: 'Remove',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _removeCustomImage();
                  },
                ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPickerOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive ? AppTheme.robinhoodRed : AppTheme.robinhoodGreen;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        await _saveCustomImage(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        await _saveCustomImage(image);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _saveCustomImage(XFile image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${directory.path}/$fileName';
      
      // Delete old custom image if exists
      if (_customImagePath != null) {
        final oldFile = File(_customImagePath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
      
      // Copy new image
      await File(image.path).copy(savedPath);
      
      setState(() {
        _customImagePath = savedPath;
        _hasChanges = true;
      });
    } catch (e) {
      debugPrint('Error saving image: $e');
    }
  }

  void _removeCustomImage() async {
    if (_customImagePath != null) {
      final file = File(_customImagePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    setState(() {
      _customImagePath = null;
      _hasChanges = true;
    });
  }

  Future<void> _saveProfile() async {
    await _prefsService.setUserName(_nameController.text);
    await _prefsService.setUserDob(_selectedDate);
    await _prefsService.setUserAvatarIndex(_selectedAvatarIndex);
    await _prefsService.setCustomAvatarPath(_customImagePath);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Profile saved successfully'),
            ],
          ),
          backgroundColor: AppTheme.robinhoodGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 1),
        ),
      );
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppTheme.robinhoodGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: Column(
                children: [
                  // Main Avatar
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'profile_avatar',
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: AppTheme.robinhoodGreen,
                            backgroundImage: _customImagePath != null
                                ? FileImage(File(_customImagePath!))
                                : null,
                            child: _customImagePath == null
                                ? Icon(
                                    _avatarIcons[_selectedAvatarIndex],
                                    size: 56,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.robinhoodGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.black : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change photo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Avatar Icons Selection
            Text(
              'Or choose an avatar',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatarIcons.length,
                itemBuilder: (context, index) {
                  final isSelected = _customImagePath == null && 
                                     index == _selectedAvatarIndex;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatarIndex = index;
                          _customImagePath = null; // Clear custom image
                          _hasChanges = true;
                        });
                      },
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.robinhoodGreen.withValues(alpha: 0.2)
                                  : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.robinhoodGreen
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _avatarIcons[index],
                              size: 32,
                              color: isSelected
                                  ? AppTheme.robinhoodGreen
                                  : AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _avatarLabels[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? AppTheme.robinhoodGreen
                                  : AppTheme.mutedText,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Name Field
            Text(
              'Name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.robinhoodGreen,
                    width: 2,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Date of Birth Field
            Text(
              'Date of Birth',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('MMMM dd, yyyy').format(_selectedDate!)
                            : 'Select date',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _selectedDate != null ? null : AppTheme.mutedText,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Account Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.robinhoodGreen.withValues(alpha: 0.1),
                    AppTheme.robinhoodGreen.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.robinhoodGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.robinhoodGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const StatchLogo(size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statch Investor',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Egyptian Market Access',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.robinhoodGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
