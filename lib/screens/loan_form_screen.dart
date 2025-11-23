// lib/screens/loan_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../data/dummy_data.dart';
import '../models/location.dart';
import '../service/api_service.dart';

class LoanFormScreen extends StatefulWidget {
  final Product product;

  const LoanFormScreen({super.key, required this.product});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  Location? _selectedLocation;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _note = '';
  int _qty = 1;
  String _pinCode = '';

  // Untuk override pinjaman
  String? _overridePin;
  int? _overrideLoanId;

  bool _isLoading = false;

  Future<Map<String, dynamic>> _createPeminjaman(
      Map<String, dynamic> body) async {
    const String baseUrl = "http://192.168.1.7:8000/api";

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/peminjaman"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // Fungsi untuk menampilkan Date Picker
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        }
      });
    }
  }

  // Fungsi untuk mendapatkan daftar pinjaman aktif yang bisa di-override
  Future<void> _fetchAvailableLoans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final active = await ApiService.getActivePeminjaman();

      if (active['data'] != null && active['data'].isNotEmpty) {
        // Filter hanya pinjaman untuk product yang sama
        final availableLoans = active['data'].where((loan) {
          return loan['product_id'] == widget.product.id;
        }).toList();

        if (availableLoans.isNotEmpty) {
          _showOverrideDialog(availableLoans);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada pinjaman aktif untuk barang ini'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada pinjaman aktif tersedia'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Dialog untuk memilih pinjaman yang akan di-override
  void _showOverrideDialog(List<dynamic> availableLoans) {
    int? selectedLoanId;
    String selectedPin = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Pinjam dari User Lain'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stok barang habis. Pilih pinjaman aktif yang ingin Anda ambil alih:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown pilih pinjaman
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Pinjaman',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    value: selectedLoanId,
                    items: availableLoans.map((loan) {
                      String startDateStr = 'Tanggal tidak valid';
                      String endDateStr = 'Tanggal tidak valid';

                      try {
                        startDateStr = DateFormat('dd MMM yyyy').format(
                            DateTime.parse(loan['start_date'].toString()));
                        endDateStr = DateFormat('dd MMM yyyy').format(
                            DateTime.parse(loan['end_date'].toString()));
                      } catch (e) {
                        print('Error parsing date: $e');
                      }

                      return DropdownMenuItem<int?>(
                        value: loan['id'] != null
                            ? int.tryParse(loan['id'].toString())
                            : null,
                        child: Text(
                          'PINJAMAN #${loan['id']} ($startDateStr - $endDateStr)',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setDialogState(() {
                        selectedLoanId = newValue;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Input PIN dari user sebelumnya
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'PIN dari Peminjam Sebelumnya',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan PIN yang dibuat peminjam sebelumnya',
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      selectedPin = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'PIN wajib diisi';
                      }
                      if (value.length < 4) {
                        return 'PIN minimal 4 karakter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  // Info
                  Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Minta PIN kepada user yang sedang meminjam barang ini',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: selectedLoanId != null && selectedPin.isNotEmpty
                    ? () {
                        _overrideLoanId = selectedLoanId;
                        _overridePin = selectedPin;
                        Navigator.pop(context);
                        _submitForm();
                      }
                    : null,
                child: const Text('Ambil Alih'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Lokasi wajib diisi!')));
        return;
      }

      if (_pinCode.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('PIN wajib diisi!')));
        return;
      }

      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        final loanData = {
          'product_id': widget.product.id,
          'location_id': _selectedLocation!.id,
          'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
          'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
          'pin_code': _pinCode,
          'note': _note,
          'qty': _qty,
          if (_overrideLoanId != null) 'id_pinjam': _overrideLoanId,
          if (_overridePin != null) 'override_pin': _overridePin,
        };

        final response = await _createPeminjaman(loanData);

        // SUKSES
        if (response['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
          return;
        }

        // STOK HABIS - tawarkan override
        final errorMessage =
            response['error'] ?? response['message'] ?? 'Terjadi kesalahan';

        if (errorMessage.toString().toLowerCase().contains("stok habis")) {
          // Tawarkan untuk pinjam dari user lain
          _fetchAvailableLoans();
          return;
        }

        // ERROR LAIN
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
Widget build(BuildContext context) {
  final primaryColor = Theme.of(context).primaryColor;

  return Scaffold(
    appBar: AppBar(
      title: Text('Pinjam: ${widget.product.name}'),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(  // HAPUS loading condition di sini
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Info Stok ---
            Card(
              color: widget.product.quantity > 0
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      widget.product.quantity > 0
                          ? Icons.inventory_2
                          : Icons.warning,
                      color: widget.product.quantity > 0
                          ? Colors.green
                          : Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stok Tersedia: ${widget.product.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: widget.product.quantity > 0
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          if (widget.product.quantity == 0)
                            const Text(
                              'Stok habis, tetapi bisa pinjam dari user lain',
                              style: TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Tombol Cari Pinjaman Aktif (jika stok habis) ---
            if (widget.product.quantity == 0)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _fetchAvailableLoans, // TAMBAHKAN loading disabler
                      icon: const Icon(Icons.search),
                      label: const Text('Cari Pinjaman Aktif dari User Lain'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // --- 2. Quantity ---
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Jumlah (Qty)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              keyboardType: TextInputType.number,
              initialValue: '1',
              enabled: !_isLoading, // DISABLE field ketika loading
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah wajib diisi';
                }
                final qty = int.tryParse(value);
                if (qty == null || qty < 1) {
                  return 'Jumlah minimal 1';
                }
                if (qty > widget.product.quantity && widget.product.quantity > 0) {
                  return 'Jumlah melebihi stok tersedia';
                }
                return null;
              },
              onSaved: (value) => _qty = int.parse(value!),
            ),
            const SizedBox(height: 16),

            // --- 3. PIN Code ---
            
TextFormField(
  decoration: const InputDecoration(
    labelText: 'PIN Code',
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.lock),
    hintText: 'Masukkan PIN untuk keamanan',
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
  ),
  obscureText: true,
  enabled: !_isLoading,
  onChanged: (value) {  // TAMBAHKAN INI
    setState(() {
      _pinCode = value;
    });
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'PIN wajib diisi';
    }
    if (value.length < 4) {
      return 'PIN minimal 4 karakter';
    }
    return null;
  },
  onSaved: (value) => _pinCode = value!,
),

            // --- 4. Dropdown Lokasi ---
            DropdownButtonFormField<Location>(
              decoration: const InputDecoration(
                labelText: 'Lokasi Pengambilan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              value: _selectedLocation,
              items: dummyLocations.map((loc) {
                return DropdownMenuItem(
                  value: loc,
                  child: Text(loc.name),
                );
              }).toList(),
              onChanged: _isLoading ? null : (Location? newValue) { // DISABLE ketika loading
                setState(() {
                  _selectedLocation = newValue;
                });
              },
              validator: (value) => value == null ? 'Pilih Lokasi' : null,
            ),
            const SizedBox(height: 16),

            // --- 5. Tanggal Peminjaman & Pengembalian ---
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _isLoading ? null : () => _selectDate(context, true), // DISABLE ketika loading
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Pinjam',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        filled: _isLoading,
                        fillColor: _isLoading ? Colors.grey[200] : null,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_startDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: _isLoading ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _isLoading ? null : () => _selectDate(context, false), // DISABLE ketika loading
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal Kembali',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_month),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        filled: _isLoading,
                        fillColor: _isLoading ? Colors.grey[200] : null,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_endDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: _isLoading ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 6. Catatan (Note) ---
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Catatan Tambahan (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              maxLines: 3,
              enabled: !_isLoading, // DISABLE ketika loading
              onSaved: (value) => _note = value ?? '',
            ),
            const SizedBox(height: 20),

            // --- Info Sistem PIN ---
            Card(
              color: Colors.blue.withOpacity(0.1),
              elevation: 1,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Sistem PIN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• PIN ini akan digunakan untuk mengembalikan barang\n'
                      '• Jika stok habis, Anda bisa pinjam dari user lain dengan PIN mereka\n'
                      '• Jaga kerahasiaan PIN Anda',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 7. Tombol Submit ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.send_rounded, size: 24),
                      label: const Text(
                        'Ajukan Peminjaman',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
}