// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/loan.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Fungsi helper untuk mendapatkan warna status
  Color _getStatusColor(LoanStatus status) {
    switch (status) {
      case LoanStatus.approved:
        return Colors.green;
      case LoanStatus.pending:
        return Colors.orange;
      case LoanStatus.returned:
        return Colors.grey;
      case LoanStatus.rejected:
        return Colors.red;
    }
  }

  // Fungsi helper untuk mendapatkan teks status
  String _getStatusText(LoanStatus status) {
    switch (status) {
      case LoanStatus.approved:
        return 'Disetujui (Sedang Dipinjam)';
      case LoanStatus.pending:
        return 'Menunggu Persetujuan';
      case LoanStatus.returned:
        return 'Selesai (Dikembalikan)';
      case LoanStatus.rejected:
        return 'Ditolak';
    }
  }

  // Fungsi manual untuk format tanggal tanpa package intl
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Peminjaman')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: dummyLoans.length,
        itemBuilder: (context, index) {
          final loan = dummyLoans[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            elevation: 2,
            child: ListTile(
              // Icon Barang
              leading: Icon(
                Icons.inventory_2,
                color: Theme.of(context).primaryColor,
                size: 40,
              ),
              // Nama Barang
              title: Text(
                loan.productName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // Detail Tanggal (pakai fungsi manual)
              subtitle: Text(
                'Pinjam: ${_formatDate(loan.startDate)} - Kembali: ${_formatDate(loan.endDate)}',
              ),
              // Status di kanan - PERBAIKAN: ganti withOpacity
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(loan.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(loan.status),
                  style: TextStyle(
                    color: _getStatusColor(loan.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () {
                // TODO: Navigasi ke detail peminjaman
              },
            ),
          );
        },
      ),
    );
  }
}
