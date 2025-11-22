// lib/models/loan.dart
import 'package:flutter/material.dart'; // Import ini dibutuhkan jika Anda menggunakan Colors, tapi tidak wajib untuk enum/class dasar

// Enumerator untuk Status Peminjaman
enum LoanStatus {
  pending, // Menunggu Persetujuan Admin
  approved, // Disetujui (Sedang Dipinjam)
  returned, // Sudah Dikembalikan
  rejected, // Ditolak
}

// Model Data untuk Riwayat Peminjaman
class Loan {
  final int id;
  final String productName;
  final DateTime startDate;
  final DateTime endDate;
  final LoanStatus status; // Menggunakan enum LoanStatus

  Loan({
    required this.id,
    required this.productName,
    required this.startDate,
    required this.endDate,
    required this.status,
  });
}
