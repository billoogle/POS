import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // formatting ke liye
import 'package:pos/helpers/currency_manager.dart';
import 'package:pos/screens/products/product_finder_screen.dart';
import 'package:pos/services/product_service.dart'; // Product service
import 'package:pos/services/sale_service.dart'; // Sale service
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import '../categories/categories_screen.dart';
import '../products/products_screen.dart';
import '../vendors/vendors_screen.dart';
import '../grn/grn_list_screen.dart';
import '../sales/pos_screen.dart';
import '../sales/sales_history_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart'; // Settings screen import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  String _userName = '';
  String _businessName = '';
  bool _isLoading = true;
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const CategoriesScreen(),
    const ProductsScreen(),
    const VendorsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (userData != null) {
        setState(() {
          _userName = userData['fullName'] ?? 'User';
          _businessName = userData['businessName'] ?? 'Business';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.error),
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.error, Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryCyan),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildHeader(),
            // Body
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryCyan.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow(color: Colors.black.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://i.ibb.co/mVtn3jPR/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.store_rounded,
                  color: AppTheme.primaryCyan,
                  size: 28,
                ),
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(width: 16),
          
          // Business Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _businessName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.2),
                const SizedBox(height: 2),
                Text(
                  'Hi, $_userName 👋',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2),
              ],
            ),
          ),
          
          // Logout Button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.white),
              onPressed: _logout,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.category_rounded, 'Categories'),
              _buildNavItem(2, Icons.inventory_2_rounded, 'Products'),
              _buildNavItem(3, Icons.business_rounded, 'Vendors'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        curve: AppAnimations.defaultCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.white : AppTheme.darkGray,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.white : AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// === UPDATED: HOME TAB (StatefulWidget) ===
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final SaleService _saleService = SaleService();
  final ProductService _productService = ProductService();
  
  late Stream<Map<String, dynamic>> _salesStatsStream;
  late Stream<int> _productCountStream;

  @override
  void initState() {
    super.initState();
    // Streams ko initialize karein
    _salesStatsStream = _saleService.getSalesStatsStream();
    _productCountStream = _productService.getProductCountStream();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16), // Reduced from 20
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: 20), // Reduced from 24

          // Modules Section
          _buildSectionHeader('Quick Actions', Icons.bolt_rounded),
          const SizedBox(height: 12), // Reduced from 16
          _buildModulesGrid(context),
          const SizedBox(height: 20), // Add bottom padding
        ],
      ),
    );
  }

  // dashboard_screen.dart - HomeTab Stats Section
// Replace _buildQuickStats() method:

Widget _buildQuickStats() {
  return Row(
    children: [
      // Today's Sales Stat Card
      Expanded(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _salesStatsStream,
          builder: (context, snapshot) {
            final revenue = snapshot.data?['todayRevenue'] ?? 0.0;
            
            // === NEW: Wrap with ValueListenableBuilder ===
            return ValueListenableBuilder<String>(
              valueListenable: CurrencyManager.currencySymbol,
              builder: (context, currency, child) {
                return _buildStatCard(
                  "Today's Sales",
                  CurrencyManager.format(revenue), // Dynamic currency
                  Icons.trending_up_rounded,
                  AppTheme.success,
                  0,
                );
              },
            );
          },
        ),
      ),
      const SizedBox(width: 12),
      
      // Total Products Stat Card (No currency needed)
      Expanded(
        child: StreamBuilder<int>(
          stream: _productCountStream,
          builder: (context, snapshot) {
            String value = snapshot.data?.toString() ?? '0';
            return _buildStatCard(
              'Products',
              value,
              Icons.inventory_2_rounded,
              AppTheme.primaryCyan,
              100,
            );
          },
        ),
      ),
    ],
  );
}

// No changes needed in _buildStatCard() method - it just displays the value

  Widget _buildStatCard(String label, String value, IconData icon, Color color, int delay) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10), // Reduced from 12
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24), // Reduced from 28
          ),
          const SizedBox(height: 12), // Reduced from 16
          Text(
            label,
            style: const TextStyle(
              fontSize: 13, // Reduced from 14
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20, // Reduced from 24
              fontWeight: FontWeight.bold,
              color: AppTheme.darkNavy,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: delay.ms).slideY(begin: 0.2);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkNavy,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2);
  }

  Widget _buildModulesGrid(BuildContext context) {
    final modules = [
      ModuleData('Find', 'Search Product', Icons.search_rounded, 
      AppTheme.info, () => Navigator.push(context, 
      MaterialPageRoute(builder: (_) => const ProductFinderScreen()))),
      
      ModuleData('GRN', 'Goods Received', Icons.receipt_long_rounded, 
          const Color(0xFF8B5CF6), () => Navigator.push(context, 
          MaterialPageRoute(builder: (_) => const GRNListScreen()))),
      ModuleData('POS', 'Point of Sale', Icons.point_of_sale_rounded, 
          AppTheme.primaryGold, () => Navigator.push(context, 
          MaterialPageRoute(builder: (_) => const POSScreen()))),
      ModuleData('Sales', 'Sales History', Icons.history_rounded, 
          AppTheme.success, () => Navigator.push(context, 
          MaterialPageRoute(builder: (_) => const SalesHistoryScreen()))),
      ModuleData('Reports', 'Analytics', Icons.analytics_rounded, 
          AppTheme.info, () => Navigator.push(context, 
          MaterialPageRoute(builder: (_) => const ReportsScreen()))),
      // === NEW: Settings Card Added ===
      ModuleData('Settings', 'Manage Account', Icons.settings_rounded, 
          AppTheme.darkGray, () => Navigator.push(context, 
          MaterialPageRoute(builder: (_) => const SettingsScreen()))),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15, // Slightly taller ratio
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleCard(module, index);
      },
    );
  }

  Widget _buildModuleCard(ModuleData module, int index) {
    return GestureDetector(
      onTap: module.onTap,
      child: Container(
        padding: const EdgeInsets.all(16), // Reduced padding
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow(),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 56, // Reduced size
              width: 56,
              decoration: BoxDecoration(
                color: module.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(module.icon, color: module.color, size: 28), // Reduced icon
            ),
            const SizedBox(height: 12), // Reduced spacing
            Text(
              module.title,
              style: const TextStyle(
                fontSize: 16, // Reduced font
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              module.subtitle,
              style: const TextStyle(
                fontSize: 11, // Reduced font
                color: AppTheme.darkGray,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class ModuleData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ModuleData(this.title, this.subtitle, this.icon, this.color, this.onTap);
}