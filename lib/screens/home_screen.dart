// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'loan_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final Color primaryBlue = const Color(0xFF1565C0);
  final Color darkBlue = const Color(0xFF0D47A1);
  final Color accentBlue = const Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen initState');
    print('🔑 Current token: ${ApiService.token}');
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      print('📦 Attempting to load products...');
      print('🔑 Token before API call: ${ApiService.token}');
      final response = await ApiService.getProducts();

      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            _products = response['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Gagal memuat produk';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get filteredProducts {
    return _products.where((product) {
      final productName = product['product_name']?.toString().toLowerCase() ??
          product['name']?.toString().toLowerCase() ??
          '';
      final categoryName = product['category']?['category_name']?.toString() ??
          product['category_name']?.toString() ??
          '';

      final matchesSearch = productName.contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Semua' || categoryName == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get categories {
    final cats = _products
        .map((product) {
          return product['category']?['category_name']?.toString() ??
              product['category_name']?.toString() ??
              'Lainnya';
        })
        .toSet()
        .toList();

    return ['Semua', ...cats];
  }

  String _getProductName(dynamic product) {
    return product['product_name'] ?? product['name'] ?? 'Unknown Product';
  }

  String _getCategoryName(dynamic product) {
    return product['category']?['category_name'] ??
        product['category_name'] ??
        'Lainnya';
  }

  String _getDescription(dynamic product) {
    return product['description'] ??
        product['product_description'] ??
        'Tidak ada deskripsi';
  }

  int _getQuantity(dynamic product) {
    return product['qty'] ?? product['quantity'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Custom Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.inventory_2_rounded,
                      size: 50,
                      color: Colors.white,
                    );
                  },
                ),
                const Spacer(),
                // Refresh Button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryBlue.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _loadProducts,
                      customBorder: const CircleBorder(),
                      child: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF42A5F5),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.refresh_rounded,
                              color: accentBlue,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Page Title
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Barang',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Tidak ada notifikasi baru'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Icon(
                          Icons.notifications_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 64,
                                  color: Colors.red[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Oops!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadProducts,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Search Bar & Filter
                          Container(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              children: [
                                // Search Field
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF1F2937),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Cari barang...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: Colors.grey[400],
                                        size: 22,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Category Filter
                                SizedBox(
                                  height: 44,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: categories.length,
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final category = categories[index];
                                      final isSelected = _selectedCategory == category;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 10),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedCategory = category;
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected ? primaryBlue : Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? primaryBlue
                                                    : Colors.grey.withOpacity(0.2),
                                                width: 1.5,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: primaryBlue.withOpacity(0.3),
                                                        blurRadius: 12,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ]
                                                  : const [
                                                      BoxShadow(
                                                        color: Color(0x0A000000),
                                                        blurRadius: 8,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                            ),
                                            child: Text(
                                              category,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Products List
                          Expanded(
                            child: filteredProducts.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.inventory_2_rounded,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          'Tidak ada barang ditemukan',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Coba cari dengan kata kunci lain',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadProducts,
                                    color: primaryBlue,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                      itemCount: filteredProducts.length,
                                      physics: const BouncingScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final product = filteredProducts[index];
                                        return _ProductCard(
                                          product: product,
                                          onTap: () async {
                                            final qty = _getQuantity(product);
                                            final isTakeOver = qty == 0;

                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LoanFormScreen(
                                                  product: product,
                                                  isTakeOver: isTakeOver,
                                                ),
                                              ),
                                            );

                                            if (result == true) {
                                              _loadProducts();
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// Product Card Widget
class _ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  final Color primaryBlue = const Color(0xFF1565C0);

  String _getProductName(dynamic product) {
    return product['product_name'] ?? product['name'] ?? 'Unknown Product';
  }

  String _getCategoryName(dynamic product) {
    return product['category']?['category_name'] ??
        product['category_name'] ??
        'Lainnya';
  }

  String _getDescription(dynamic product) {
    return product['description'] ??
        product['product_description'] ??
        'Tidak ada deskripsi';
  }

  int _getQuantity(dynamic product) {
    return product['qty'] ?? product['quantity'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final qty = _getQuantity(product);
    final isOutOfStock = qty == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Product Icon with Gradient
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? Colors.orange[400]
                        : primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isOutOfStock
                                ? Colors.orange[400]!
                                : primaryBlue)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        _getProductName(product),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Category
                      Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getCategoryName(product),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        _getDescription(product),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Stock & Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Stock Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? Colors.red[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isOutOfStock
                                    ? Colors.red[200]!
                                    : Colors.green[200]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_outlined,
                                  size: 14,
                                  color: isOutOfStock
                                      ? Colors.red[700]
                                      : Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Stok: $qty',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: isOutOfStock
                                        ? Colors.red[700]
                                        : Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action Button
                          Container(
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? Colors.orange[400]
                                  : const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onTap,
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isOutOfStock
                                            ? Icons.swap_horiz_rounded
                                            : Icons.check_circle_outline_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isOutOfStock ? 'Take Over' : 'Pinjam',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}