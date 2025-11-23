// lib/screens/loan_form_screen.dart
import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'dart:math';

class LoanFormScreen extends StatefulWidget {
  final dynamic product;
  final bool isTakeOver;

  const LoanFormScreen({
    super.key,
    required this.product,
    this.isTakeOver = false,
  });

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _borrowPinController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  int? _selectedLocationId;
  int _quantity = 1;

  List<dynamic> _locations = [];
  bool _isLoading = false;
  bool _isLoadingLocations = true;

  // ✅ Data untuk take over
  int _totalBorrowed = 0;
  bool _isLoadingBorrowedInfo = false;
  List<dynamic> _activeLoans = []; // Simpan list peminjaman aktif

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _pinController.text = _generateRandomPin();

    if (widget.isTakeOver) {
      _loadBorrowedInfo();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _pinController.dispose();
    _borrowPinController.dispose();
    super.dispose();
  }

  // ✅ Load total yang sedang dipinjam + simpan list loans
  Future<void> _loadBorrowedInfo() async {
    setState(() {
      _isLoadingBorrowedInfo = true;
    });

    try {
      final productId = _getProductId();

      // Get all active loans
      final response = await ApiService.getActivePeminjaman();

      if (mounted && response['success'] == true) {
        final List<dynamic> allLoans = response['data'] ?? [];

        // Filter by product_id dan status dipinjam
        final productLoans = allLoans.where((loan) {
          final loanProductId = loan['product_id'] ?? loan['product']?['id'];
          final status = loan['status']?.toString().toLowerCase();
          return loanProductId == productId && status == 'dipinjam';
        }).toList();

        // Sum total borrowed
        int totalBorrowed = 0;
        for (var loan in productLoans) {
          totalBorrowed += (loan['qty'] ?? 0) as int;
        }

        setState(() {
          _activeLoans = productLoans; // Simpan list untuk cek PIN nanti
          _totalBorrowed = totalBorrowed;
          _isLoadingBorrowedInfo = false;
        });

        print(
            '📊 Total borrowed: $_totalBorrowed from ${productLoans.length} loans');
      } else {
        setState(() {
          _isLoadingBorrowedInfo = false;
        });
      }
    } catch (e) {
      print('❌ Error loading borrowed info: $e');
      if (mounted) {
        setState(() {
          _isLoadingBorrowedInfo = false;
        });
      }
    }
  }

  // ✅ FUNGSI BARU: Cari ID peminjaman berdasarkan PIN
  int? _findLoanIdByPin(String pin) {
    try {
      // Cari peminjaman yang PIN-nya cocok
      final matchedLoan = _activeLoans.firstWhere(
        (loan) => loan['pin_code']?.toString() == pin,
        orElse: () => null,
      );

      if (matchedLoan != null) {
        final loanId = matchedLoan['id'];
        final loanQty = matchedLoan['qty'] ?? 0;
        print('✅ Found loan ID: $loanId with qty: $loanQty for PIN: $pin');
        return loanId;
      } else {
        print('❌ No loan found with PIN: $pin');
        return null;
      }
    } catch (e) {
      print('❌ Error finding loan by PIN: $e');
      return null;
    }
  }

  // ✅ FUNGSI BARU: Validasi quantity vs loan yang akan di-take over
  String? _validateTakeOverQuantity(String pin, int requestedQty) {
    try {
      final matchedLoan = _activeLoans.firstWhere(
        (loan) => loan['pin_code']?.toString() == pin,
        orElse: () => null,
      );

      if (matchedLoan != null) {
        final availableQty = matchedLoan['qty'] ?? 0;
        if (requestedQty > availableQty) {
          return 'Quantity melebihi yang dipinjam user ini ($availableQty unit)';
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _generateRandomPin() {
    Random random = Random();
    String pin = '';
    for (int i = 0; i < 4; i++) {
      pin += random.nextInt(10).toString();
    }
    return pin;
  }

  Future<void> _loadLocations() async {
    try {
      final response = await ApiService.getLocations();

      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            _locations = response['data'] ?? [];
            _isLoadingLocations = false;
          });
        } else {
          setState(() {
            _isLoadingLocations = false;
          });
          _showErrorSnackBar('Gagal memuat lokasi');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
        });
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    }
  }

  Future<void> _presentDatePicker(bool isStartDate) async {
    final now = DateTime.now();
    final initialDate = isStartDate
        ? (_selectedStartDate ?? now.add(const Duration(days: 1)))
        : (_selectedEndDate ??
            (_selectedStartDate?.add(const Duration(days: 1)) ??
                now.add(const Duration(days: 2))));

    final firstDate = isStartDate ? now : (_selectedStartDate ?? now);
    final lastDate = now.add(const Duration(days: 365));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = pickedDate;
          if (_selectedEndDate != null &&
              _selectedEndDate!.isBefore(pickedDate)) {
            _selectedEndDate = null;
          }
        } else {
          _selectedEndDate = pickedDate;
        }
      });
    }
  }

  int _getProductQuantity() {
    return widget.product['qty'] ?? widget.product['quantity'] ?? 0;
  }

  String _getProductName() {
    return widget.product['product_name'] ?? widget.product['name'] ?? 'Produk';
  }

  int _getProductId() {
    return widget.product['id'] ?? 0;
  }

  int _getMaxQuantity() {
    if (widget.isTakeOver) {
      return _totalBorrowed > 0 ? _totalBorrowed : 1;
    } else {
      final availableStock = _getProductQuantity();
      return availableStock > 0 ? availableStock : 1;
    }
  }

  bool _isIncrementDisabled() {
    return _quantity >= _getMaxQuantity();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _submitLoan() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Mohon lengkapi semua field');
      return;
    }

    if (_selectedStartDate == null || _selectedEndDate == null) {
      _showErrorSnackBar('Mohon pilih tanggal peminjaman dan pengembalian');
      return;
    }

    if (_selectedLocationId == null) {
      _showErrorSnackBar('Mohon pilih lokasi peminjaman');
      return;
    }

    if (widget.isTakeOver && _borrowPinController.text.isEmpty) {
      _showErrorSnackBar(
        'Mohon masukkan PIN peminjam untuk mengambil alih stok',
      );
      return;
    }

    // ✅ VALIDASI TAMBAHAN: Cek PIN dan qty untuk take over
    int? idPinjam;
    if (widget.isTakeOver) {
      // Cari ID peminjaman berdasarkan PIN
      idPinjam = _findLoanIdByPin(_borrowPinController.text);

      if (idPinjam == null) {
        _showErrorSnackBar(
          'PIN tidak valid! PIN tidak ditemukan di peminjaman aktif produk ini.',
        );
        return;
      }

      // Validasi quantity
      final qtyValidation = _validateTakeOverQuantity(
        _borrowPinController.text,
        _quantity,
      );

      if (qtyValidation != null) {
        _showErrorSnackBar(qtyValidation);
        return;
      }

      print('✅ Take over validated: loan_id=$idPinjam, qty=$_quantity');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.createPeminjaman(
        productId: _getProductId(),
        locationId: _selectedLocationId!,
        startDate: _selectedStartDate!.toIso8601String().split('T')[0],
        endDate: _selectedEndDate!.toIso8601String().split('T')[0],
        pinCode: _pinController.text,
        qty: _quantity,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        idPinjam: idPinjam, // ✅ Kirim ID peminjaman yang akan di-take over
        overridePin: widget.isTakeOver ? _borrowPinController.text : null,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response['success'] == true) {
          _showSuccessSnackBar(
            '${widget.isTakeOver ? "Take over" : "Peminjaman"} ${_getProductName()} berhasil!\n'
            'PIN Anda: ${_pinController.text}\n'
            '⚠️ CATAT PIN INI UNTUK PENGEMBALIAN!',
          );

          Navigator.of(context).pop(true);
        } else {
          _showErrorSnackBar(response['message'] ?? 'Gagal membuat peminjaman');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    if (_isLoadingLocations || (_isLoadingBorrowedInfo && widget.isTakeOver)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isTakeOver
                ? 'Ambil Alih: ${_getProductName()}'
                : 'Pinjam: ${_getProductName()}',
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isTakeOver
              ? 'Ambil Alih: ${_getProductName()}'
              : 'Pinjam: ${_getProductName()}',
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductInfoCard(primaryColor),
              const SizedBox(height: 24),
              if (widget.isTakeOver) ...[
                _buildTakeOverWarningCard(),
                const SizedBox(height: 24),
              ],
              _buildPinSection(primaryColor),
              const SizedBox(height: 20),
              if (widget.isTakeOver) ...[
                _buildBorrowPinSection(primaryColor),
                const SizedBox(height: 20),
              ],
              _buildLocationDropdown(),
              const SizedBox(height: 20),
              _buildQuantitySelector(),
              const SizedBox(height: 20),
              _buildDatePickers(),
              const SizedBox(height: 20),
              _buildNoteField(),
              const SizedBox(height: 30),
              _buildSubmitButton(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfoCard(Color primaryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getProductName(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_outlined,
                            size: 16,
                            color: widget.isTakeOver
                                ? Colors.orange
                                : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.isTakeOver
                                ? 'Sedang dipinjam: $_totalBorrowed unit (${_activeLoans.length} peminjam)'
                                : 'Stok Tersedia: ${_getProductQuantity()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.isTakeOver
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTakeOverWarningCard() {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange[700], size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode Take Over',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok tersedia habis. Total $_totalBorrowed unit sedang dipinjam oleh ${_activeLoans.length} pengguna. Masukkan PIN salah satu peminjam untuk mengambil alih stok mereka.',
                    style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💡 Tips: Stok yang Anda ambil akan otomatis dikurangi dari peminjaman user tersebut.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                      fontStyle: FontStyle.italic,
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

  Widget _buildPinSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.vpn_key, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'PIN Pengembalian Anda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[300]!, width: 2),
          ),
          child: TextFormField(
            controller: _pinController,
            readOnly: true,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.red,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0000',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _pinController.text = _generateRandomPin();
                  });
                },
                tooltip: 'Generate PIN Baru',
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'PIN wajib ada';
              }
              if (value.length != 4) {
                return 'PIN harus 4 digit';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[900], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ CATAT PIN INI! PIN digunakan untuk mengembalikan barang.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBorrowPinSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'PIN Peminjam (Wajib)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[300]!, width: 2),
          ),
          child: TextFormField(
            controller: _borrowPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Masukkan PIN peminjam',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              counterText: '',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (widget.isTakeOver) {
                if (value == null || value.isEmpty) {
                  return 'PIN peminjam wajib diisi untuk take over';
                }
                if (value.length != 4) {
                  return 'PIN harus 4 digit';
                }
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan PIN dari salah satu peminjam aktif. Sistem akan otomatis mengurangi qty dari peminjaman mereka.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.red[700],
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi Peminjaman',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedLocationId,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            hint: const Text('Pilih lokasi'),
            items: _locations.map<DropdownMenuItem<int>>((location) {
              return DropdownMenuItem<int>(
                value: location['id'],
                child: Text(location['location_name'] ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLocationId = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Lokasi wajib dipilih';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    final maxQty = _getMaxQuantity();
    final isAtMax = _isIncrementDisabled();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Jumlah',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              widget.isTakeOver
                  ? '(Maks: $_totalBorrowed total dipinjam)'
                  : '(Maks: $maxQty)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1
                    ? () {
                        setState(() {
                          _quantity--;
                        });
                      }
                    : null,
                color: _quantity > 1 ? Colors.red : Colors.grey,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isAtMax)
                      Text(
                        'Maksimum',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: isAtMax
                    ? null
                    : () {
                        setState(() {
                          _quantity++;
                        });
                      },
                color: isAtMax ? Colors.grey : Colors.green,
              ),
            ],
          ),
        ),
        if (widget.isTakeOver)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '⚠️ Pilih qty yang ingin diambil alih. Qty peminjam akan dikurangi otomatis.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDatePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal Peminjaman',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _presentDatePicker(true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mulai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedStartDate != null
                                  ? '${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year}'
                                  : 'Pilih tanggal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedStartDate != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _presentDatePicker(false),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selesai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedEndDate != null
                                  ? '${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}'
                                  : 'Pilih tanggal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedEndDate != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan (Opsional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Contoh: Untuk keperluan ujian praktik',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              prefixIcon: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(Icons.edit_note),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(Color primaryColor) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitLoan,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isTakeOver ? Colors.orange : primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isTakeOver
                        ? Icons.swap_horiz
                        : Icons.check_circle_outline,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isTakeOver
                        ? 'Ambil Alih Stok'
                        : 'Konfirmasi Peminjaman',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
