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
      appBar: AppBar(
        title: const Text('Daftar Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadProducts,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tidak ada notifikasi baru')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search Bar & Filter
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      child: Column(
                        children: [
                          // Search Field
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari barang...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Category Filter
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final isSelected =
                                    _selectedCategory == category;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.2),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[700],
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
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
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada barang ditemukan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadProducts,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12.0),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  return ProductCard(
                                    product: product,
                                    onTap: () async {
                                      // ✅ Cek stok untuk menentukan mode take over
                                      final qty = _getQuantity(product);
                                      final isTakeOver = qty == 0;

                                      // Navigate ke form dengan parameter isTakeOver
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LoanFormScreen(
                                            product: product,
                                            isTakeOver: isTakeOver,
                                          ),
                                        ),
                                      );

                                      // Refresh products jika berhasil
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
    );
  }
}

// ✅ UPDATED: ProductCard - Tombol Pinjam SELALU aktif
class ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

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
    final primaryColor = Theme.of(context).primaryColor;
    final qty = _getQuantity(product);
    final isOutOfStock = qty == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap, // ✅ SELALU bisa diklik
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Product Image
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    size: 40, color: primaryColor),
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Product Name
                    Text(
                      _getProductName(product),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getCategoryName(product),
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      _getDescription(product),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Stock & Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Stock Info
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_outlined,
                              size: 16,
                              color: isOutOfStock ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stok: $qty',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isOutOfStock ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),

                        // ✅ Borrow Button - SELALU aktif
                        ElevatedButton.icon(
                          onPressed: onTap, // Tidak ada kondisi disable
                          icon: Icon(
                            isOutOfStock
                                ? Icons.swap_horiz
                                : Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: Text(isOutOfStock ? 'Take Over' : 'Pinjam'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isOutOfStock ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
    );
  }
}
