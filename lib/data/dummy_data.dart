// lib/data/dummy_data.dart

import '../models/product.dart';
import '../models/loan.dart';
import '../models/major.dart';
import '../models/class.dart';
import '../models/location.dart';

// =======================================================
// 1. DATA DUMMY PRODUK (BARANG)
// =======================================================

final List<Product> dummyProducts = [
  Product(
    id: 1,
    name: "Projector Epson EB-X41",
    description:
        "Proyektor LCD resolusi XGA (1024x768). Ideal untuk kelas dan presentasi kecil.",
    imageUrl: "assets/images/projector.jpg",
    quantity: 5,
    categoryName: "Elektronik",
  ),
  Product(
    id: 2,
    name: "Kamera DSLR Canon EOS 200D",
    description:
        "Kamera digital single-lens reflex (DSLR) dengan lensa kit 18-55mm.",
    imageUrl: "assets/images/camera.jpg",
    quantity: 2,
    categoryName: "Fotografi",
  ),
  Product(
    id: 3,
    name: "Kabel HDMI 5 Meter",
    description:
        "Kabel High-Definition Multimedia Interface untuk koneksi audio-visual.",
    imageUrl: "assets/images/hdmi.jpg",
    quantity: 10,
    categoryName: "Aksesoris",
  ),
  Product(
    id: 4,
    name: "Laptop Asus Vivobook 14",
    description:
        "Laptop ringan i5 Gen 11, cocok untuk tugas komputasi umum dan coding.",
    imageUrl: "assets/images/laptop.jpg",
    quantity: 3,
    categoryName: "Elektronik",
  ),
  Product(
    id: 5,
    name: "Tripod Kamera Heavy Duty",
    description:
        "Tripod aluminium tinggi maksimal 180cm dengan kepala ball-head.",
    imageUrl: "assets/images/tripod.jpg",
    quantity: 4,
    categoryName: "Fotografi",
  ),
];

// =======================================================
// 2. DATA DUMMY PEMINJAMAN (RIWAYAT)
// =======================================================

final List<Loan> dummyLoans = [
  Loan(
    id: 101,
    productName: "Projector Epson EB-X41",
    startDate: DateTime(2025, 11, 20),
    endDate: DateTime(2025, 11, 22),
    status: LoanStatus.approved,
  ),
  Loan(
    id: 102,
    productName: "Kabel HDMI 5 Meter",
    startDate: DateTime(2025, 11, 15),
    endDate: DateTime(2025, 11, 15),
    status: LoanStatus.returned,
  ),
  Loan(
    id: 103,
    productName: "Kamera DSLR Canon EOS 200D",
    startDate: DateTime(2025, 11, 21),
    endDate: DateTime(2025, 11, 23),
    status: LoanStatus.pending,
  ),
  Loan(
    id: 104,
    productName: "Laptop Asus Vivobook 14",
    startDate: DateTime(2025, 11, 10),
    endDate: DateTime(2025, 11, 12),
    status: LoanStatus.rejected,
  ),
  Loan(
    id: 105,
    productName: "Tripod Kamera Heavy Duty",
    startDate: DateTime(2025, 11, 18),
    endDate: DateTime(2025, 11, 19),
    status: LoanStatus.returned,
  ),
];

// =======================================================
// 3. DATA DUMMY JURUSAN (MAJOR)
// Digunakan di Dropdown Formulir
// =======================================================

final List<Major> dummyMajors = [
  Major(id: 1, name: 'Rekayasa Perangkat Lunak (RPL)'),
  Major(id: 2, name: 'Teknik Komputer & Jaringan (TKJ)'),
  Major(id: 3, name: 'Multimedia (MM)'),
  Major(id: 4, name: 'Desain Komunikasi Visual (DKV)'),
  Major(id: 5, name: 'Akuntansi (AKT)'),
];

// =======================================================
// 4. DATA DUMMY KELAS (CLASS)
// Digunakan di Dropdown Formulir
// =======================================================

final List<Class> dummyClasses = [
  Class(id: 101, name: 'X RPL 1'),
  Class(id: 102, name: 'XI RPL 2'),
  Class(id: 103, name: 'XII RPL 3'),
  Class(id: 104, name: 'XII TKJ 1'),
  Class(id: 105, name: 'XI MM 2'),
];

// =======================================================
// 5. DATA DUMMY LOKASI (LOCATION)
// Digunakan di Dropdown Formulir
// =======================================================

final List<Location> dummyLocations = [
  Location(id: 201, name: 'Gudang Lab Komputer 1'),
  Location(id: 202, name: 'Ruang Kepala Sekolah/Sekretariat'),
  Location(id: 203, name: 'Gudang Olahraga Belakang'),
  Location(id: 204, name: 'Ruang Multimedia'),
];
