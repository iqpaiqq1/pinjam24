// lib/screens/loan_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../data/dummy_data.dart';
import '../models/location.dart';

class LoanFormScreen extends StatefulWidget {
  final Product product;

  const LoanFormScreen({super.key, required this.product});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  // Form Key untuk validasi
  final _formKey = GlobalKey<FormState>();

  // State untuk data input - SESUAI API
  Location? _selectedLocation;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _note = '';
  int _qty = 1;
  String _pinCode = '';

  // Untuk override pinjaman (opsional)
  String? _overridePin;
  int? _overrideLoanId;

  bool _isLoading = false;

  // Fungsi untuk langsung call API tanpa ApiService
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

  // Fungsi Submit Form
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi wajib diisi!')),
        );
        return;
      }

      if (_pinCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN wajib diisi!')),
        );
        return;
      }

      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // Data yang sesuai dengan API PHP
        final loanData = {
          'product_id': widget.product.id,
          'location_id': _selectedLocation!.id,
          'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
          'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
          'pin_code': _pinCode,
          'note': _note,
          'qty': _qty,
          if (_overrideLoanId != null) 'id_pinjam': _overrideLoanId,
          if (_overridePin != null && _overridePin!.isNotEmpty)
            'override_pin': _overridePin,
        };

        // Panggil API langsung
        final response = await _createPeminjaman(loanData);

        if (response['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final errorMessage =
              response['error'] ?? response['message'] ?? 'Terjadi kesalahan';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );

          // Tampilkan opsi override jika stok habis
          if (errorMessage.toString().toLowerCase().contains('stok habis')) {
            _showOverrideOption();
          }
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
  }

  // Tampilkan dialog untuk override pinjaman
  void _showOverrideOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stok Tidak Tersedia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Stok barang habis. Anda dapat meminjam dari user lain dengan:'),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'ID Peminjaman yang akan dioverride',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _overrideLoanId = int.tryParse(value);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'PIN Override',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) {
                _overridePin = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitForm(); // Coba submit lagi dengan data override
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text('Pinjam: ${widget.product.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- 1. Detail Barang (Info) ---
              Card(
                color: primaryColor.withOpacity(0.05),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, color: primaryColor),
                      const SizedBox(width: 10),
                      Text(
                        'Stok Tersedia: ${widget.product.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- 2. Quantity ---
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Jumlah (Qty)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah wajib diisi';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty < 1) {
                    return 'Jumlah minimal 1';
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
                ),
                obscureText: true,
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
              const SizedBox(height: 16),

              // --- 4. Dropdown Lokasi ---
              DropdownButtonFormField<Location>(
                decoration: const InputDecoration(
                  labelText: 'Lokasi Pengambilan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                value: _selectedLocation,
                items: dummyLocations.map((loc) {
                  return DropdownMenuItem(
                    value: loc,
                    child: Text(loc.name),
                  );
                }).toList(),
                onChanged: (Location? newValue) {
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
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Pinjam',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_startDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Kembali',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_endDate),
                          style: const TextStyle(fontSize: 16),
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
                ),
                maxLines: 3,
                onSaved: (value) => _note = value ?? '',
              ),
              const SizedBox(height: 16),

              // --- Info Override (jika diperlukan) ---
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Jika stok habis, Anda bisa meminjam dari user lain dengan ID Peminjaman dan PIN override',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- 7. Tombol Submit ---
              SizedBox(
                width: double.infinity,
                height: 50,
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
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
