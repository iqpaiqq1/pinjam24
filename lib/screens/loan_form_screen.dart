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

  // Data untuk take over
  int _totalBorrowed = 0;
  bool _isLoadingBorrowedInfo = false;
  List<dynamic> _activeLoans = [];

  // WARNA SAMA PERSIS DENGAN HOMESCREEN
  final Color primaryBlue = const Color(0xFF1565C0);
  final Color darkBlue = const Color(0xFF0D47A1);
  final Color accentBlue = const Color(0xFF42A5F5);

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

  // Load total yang sedang dipinjam + simpan list loans
  Future<void> _loadBorrowedInfo() async {
    setState(() {
      _isLoadingBorrowedInfo = true;
    });

    try {
      final productId = _getProductId();

      final response = await ApiService.getActivePeminjaman();

      if (mounted && response['success'] == true) {
        final List<dynamic> allLoans = response['data'] ?? [];

        final productLoans = allLoans.where((loan) {
          final loanProductId = loan['product_id'] ?? loan['product']?['id'];
          final status = loan['status']?.toString().toLowerCase();
          return loanProductId == productId && status == 'dipinjam';
        }).toList();

        int totalBorrowed = 0;
        for (var loan in productLoans) {
          totalBorrowed += (loan['qty'] ?? 0) as int;
        }

        setState(() {
          _activeLoans = productLoans;
          _totalBorrowed = totalBorrowed;
          _isLoadingBorrowedInfo = false;
        });

        print(
            'Total borrowed: $_totalBorrowed from ${productLoans.length} loans');
      } else {
        setState(() {
          _isLoadingBorrowedInfo = false;
        });
      }
    } catch (e) {
      print('Error loading borrowed info: $e');
      if (mounted) {
        setState(() {
          _isLoadingBorrowedInfo = false;
        });
      }
    }
  }

  int? _findLoanIdByPin(String pin) {
    try {
      final matchedLoan = _activeLoans.firstWhere(
        (loan) => loan['pin_code']?.toString() == pin,
        orElse: () => null,
      );

      if (matchedLoan != null) {
        final loanId = matchedLoan['id'];
        final loanQty = matchedLoan['qty'] ?? 0;
        print('Found loan ID: $loanId with qty: $loanQty for PIN: $pin');
        return loanId;
      } else {
        print('No loan found with PIN: $pin');
        return null;
      }
    } catch (e) {
      print('Error finding loan by PIN: $e');
      return null;
    }
  }

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

    int? idPinjam;
    if (widget.isTakeOver) {
      idPinjam = _findLoanIdByPin(_borrowPinController.text);

      if (idPinjam == null) {
        _showErrorSnackBar(
          'PIN tidak valid! PIN tidak ditemukan di peminjaman aktif produk ini.',
        );
        return;
      }

      final qtyValidation = _validateTakeOverQuantity(
        _borrowPinController.text,
        _quantity,
      );

      if (qtyValidation != null) {
        _showErrorSnackBar(qtyValidation);
        return;
      }

      print('Take over validated: loan_id=$idPinjam, qty=$_quantity');
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
        idPinjam: idPinjam,
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
            'CATAT PIN INI UNTUK PENGEMBALIAN!',
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
    if (_isLoadingLocations || (_isLoadingBorrowedInfo && widget.isTakeOver)) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            widget.isTakeOver
                ? 'Ambil Alih: ${_getProductName()}'
                : 'Pinjam: ${_getProductName()}',
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: accentBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.isTakeOver
              ? 'Ambil Alih: ${_getProductName()}'
              : 'Pinjam: ${_getProductName()}',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductInfoCard(),
              const SizedBox(height: 24),
              if (widget.isTakeOver) ...[
                _buildTakeOverWarningCard(),
                const SizedBox(height: 24),
              ],
              _buildPinSection(),
              const SizedBox(height: 20),
              if (widget.isTakeOver) ...[
                _buildBorrowPinSection(),
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
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== UI DENGAN TEMA HOMESCREEN ====================

  Widget _buildProductInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isTakeOver ? Colors.orange[600] : primaryBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getProductName(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_outlined,
                      size: 16,
                      color: widget.isTakeOver ? Colors.orange[700] : Colors.green[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.isTakeOver
                          ? 'Sedang dipinjam: $_totalBorrowed unit'
                          : 'Stok tersedia: ${_getProductQuantity()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.isTakeOver ? Colors.orange[700] : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeOverWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mode Take Over',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stok habis. Total $_totalBorrowed unit sedang dipinjam oleh ${_activeLoans.length} pengguna.',
                  style: const TextStyle(color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Masukkan PIN salah satu peminjam untuk mengambil alih stok mereka.',
                  style: TextStyle(fontSize: 13, color: Colors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PIN Pengembalian Anda',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryBlue.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(color: primaryBlue.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: TextFormField(
            controller: _pinController,
            readOnly: true,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
              color: primaryBlue,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              suffixIcon: IconButton(
                icon: Icon(Icons.refresh_rounded, color: accentBlue, size: 28),
                onPressed: () => setState(() => _pinController.text = _generateRandomPin()),
                tooltip: 'Generate PIN Baru',
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty || value.length != 4) return 'PIN harus 4 digit';
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[800]),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'CATAT PIN INI! PIN digunakan untuk mengembalikan barang.',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBorrowPinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PIN Peminjam (Wajib untuk Take Over)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[400]!, width: 2),
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.15), blurRadius: 10)],
          ),
          child: TextFormField(
            controller: _borrowPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: '0000',
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: 20),
            ),
            validator: (value) {
              if (widget.isTakeOver && (value == null || value.length != 4)) {
                return 'PIN peminjam wajib 4 digit';
              }
              return null;
            },
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: DropdownButtonFormField<int>(
            value: _selectedLocationId,
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              prefixIcon: Icon(Icons.location_on_outlined, color: primaryBlue),
            ),
            hint: const Text('Pilih lokasi'),
            items: _locations.map<DropdownMenuItem<int>>((location) {
              return DropdownMenuItem<int>(
                value: location['id'],
                child: Text(location['location_name'] ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedLocationId = value),
            validator: (value) => value == null ? 'Wajib pilih lokasi' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jumlah Barang',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                color: _quantity > 1 ? Colors.red[600] : Colors.grey,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: !_isIncrementDisabled() ? () => setState(() => _quantity++) : null,
                color: !_isIncrementDisabled() ? Colors.green[600]! : Colors.grey,
              ),
            ],
          ),
        ),
        if (_isIncrementDisabled())
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Maksimum stok tersedia',
              style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _dateTile('Mulai', _selectedStartDate, () => _presentDatePicker(true))),
            const SizedBox(width: 12),
            Expanded(child: _dateTile('Selesai', _selectedEndDate, () => _presentDatePicker(false))),
          ],
        ),
      ],
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Pilih tanggal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: date != null ? FontWeight.bold : FontWeight.normal,
                color: date != null ? const Color(0xFF1F2937) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan (Opsional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: TextFormField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Contoh: Untuk keperluan ujian praktik',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitLoan,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isTakeOver ? Colors.orange[600] : primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.isTakeOver ? Icons.swap_horiz_rounded : Icons.check_circle_outline_rounded),
                  const SizedBox(width: 12),
                  Text(
                    widget.isTakeOver ? 'Ambil Alih Stok' : 'Konfirmasi Peminjaman',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}