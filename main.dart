// VILLIARD v2.5.2 - game billiard bergaya 8 Ball Pool (Flutter) - 10 avatar, border api 2D, bola menggelinding
// Fitur: lobi bergaya 8 Ball Pool, profil (username, avatar, level, statistik),
// skin cue (beli & pakai), skin meja otomatis per arena, 14 arena (termasuk Osaka, Seoul, Dubai, Rio, Cairo, Paris, New York, Las Vegas), Minigames (Lucky Shoot, Power Timing),
// uang awal Rp 2.000.000, fisika bola, aturan 8-ball (bola 8 wajib pilih lubang dulu), lawan AI,
// sfx koin saat masuk arena, hadiah harian, misi (harian & utama), border avatar (beli / misi),
// setelan: roda bidik (bidik halus) + stelan grafik,
// kontrol drag-to-aim + power slider kiri, ball-in-hand.
// Fitur tambahan (inject coins, autoplay, pantulan, auto queue, long line)
// dikontrol dari aplikasi pendamping Bloader lewat jembatan lokal 127.0.0.1.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show ContentType, HttpRequest, HttpServer, InternetAddress;
import 'dart:math';
import 'dart:typed_data' show Float32List, Float64List;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart'
    show AudioPlayer, AssetSource, ReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// ======================================================================
// KONSTANTA MEJA
// ======================================================================
const double kW = 800; // lebar area main
const double kH = 400; // tinggi area main
const double kR = 10.5; // jari-jari bola
const double kRail = 38; // tebal kayu

const List<Offset> kPockets = [
  Offset(0, 0),
  Offset(kW / 2, -5),
  Offset(kW, 0),
  Offset(0, kH),
  Offset(kW / 2, kH + 5),
  Offset(kW, kH),
];

double pocketRadius(int i) => (i == 1 || i == 4) ? 22 : 25;

const List<String> kPocketNames = [
  'kiri atas',
  'tengah atas',
  'kanan atas',
  'kiri bawah',
  'tengah bawah',
  'kanan bawah',
];

const List<Color> kBallColors = [
  Color(0xFFF5F5F5), // 0 putih
  Color(0xFFF2C500), // 1
  Color(0xFF1F4FD8), // 2
  Color(0xFFD62828), // 3
  Color(0xFF6A1B9A), // 4
  Color(0xFFF57C00), // 5
  Color(0xFF1B8A3A), // 6
  Color(0xFF8B1E2D), // 7
  Color(0xFF111111), // 8
  Color(0xFFF2C500), // 9
  Color(0xFF1F4FD8), // 10
  Color(0xFFD62828), // 11
  Color(0xFF6A1B9A), // 12
  Color(0xFFF57C00), // 13
  Color(0xFF1B8A3A), // 14
  Color(0xFF8B1E2D), // 15
];

// ======================================================================
// ARENA
// ======================================================================
// Skin meja: setiap arena punya tampilan meja sendiri.
class TableSkin {
  final String title;
  final Color railTop, railBottom, trim, sight;
  // motif kain: 0 polos, 1 garis, 2 berlian, 3 bintang, 4 lingkaran, 5 diagonal, 6 sakura
  final int pattern;
  const TableSkin(this.title, this.railTop, this.railBottom, this.trim,
      this.sight, this.pattern);
}

const List<String> kPatternNames = [
  'Polos',
  'Garis',
  'Berlian',
  'Bintang',
  'Lingkaran',
  'Diagonal',
  'Sakura',
  'Taegeuk',
  'Arabesque',
  'Samba',
  'Piramida',
  'Fleur-de-lis',
  'Skyline',
  'Kasino',
];

class Venue {
  final String name, country, flag, ai;
  final int fee;
  final Color felt, accent;
  final double aiError; // makin kecil makin jago
  final TableSkin skin;
  const Venue(this.name, this.country, this.flag, this.ai, this.fee, this.felt,
      this.accent, this.aiError, this.skin);
}

const List<Venue> kVenues = [
  Venue(
      'Bandung',
      'Indonesia',
      '🇮🇩',
      'Asep',
      50000,
      Color(0xFF1E7A46),
      Color(0xFF4ADE80),
      0.060,
      TableSkin('Meja Kayu Jati', Color(0xFF8A5A2B), Color(0xFF4A2C14),
          Color(0xFF4ADE80), Color(0xFFF5E6C8), 0)),
  Venue(
      'Jakarta',
      'Indonesia',
      '🇮🇩',
      'Bang Jago',
      100000,
      Color(0xFF1D5FB4),
      Color(0xFF60A5FA),
      0.045,
      TableSkin('Meja Metro Baja', Color(0xFF4B5563), Color(0xFF1F2937),
          Color(0xFF60A5FA), Color(0xFFE5E7EB), 1)),
  Venue(
      'Bekasi',
      'Indonesia',
      '🇮🇩',
      'Ujang',
      200000,
      Color(0xFF0F766E),
      Color(0xFF2DD4BF),
      0.035,
      TableSkin('Meja Walnut Teal', Color(0xFF6B4423), Color(0xFF2E1B0E),
          Color(0xFF2DD4BF), Color(0xFFF5E6C8), 2)),
  Venue(
      'Singapore',
      'Singapore',
      '🇸🇬',
      'Mr. Tan',
      500000,
      Color(0xFFA3262F),
      Color(0xFFF87171),
      0.025,
      TableSkin('Meja Lakuer Merah', Color(0xFF2B2B2B), Color(0xFF0A0A0A),
          Color(0xFFF87171), Color(0xFFFDE68A), 3)),
  Venue(
      'Thailand',
      'Thailand',
      '🇹🇭',
      'Somchai',
      1000000,
      Color(0xFF5B2A86),
      Color(0xFFC084FC),
      0.016,
      TableSkin('Meja Ungu Royal', Color(0xFF5B2A86), Color(0xFF24103A),
          Color(0xFFC084FC), Color(0xFFFDE68A), 4)),
  Venue(
      'Malaysia',
      'Malaysia',
      '🇲🇾',
      'Encik Amir',
      2000000,
      Color(0xFF0B2E6B),
      Color(0xFFFACC15),
      0.008,
      TableSkin('Meja Emas Sultan', Color(0xFFE5B73B), Color(0xFF8A6A12),
          Color(0xFFFFFFFF), Color(0xFF0B2E6B), 5)),
  Venue(
      'Osaka',
      'Jepang',
      '🇯🇵',
      'Tanaka',
      5000000,
      Color(0xFF7A1F4B),
      Color(0xFFF9A8D4),
      0.004,
      TableSkin('Meja Sakura Lakuer', Color(0xFF1F1F2E), Color(0xFF08080F),
          Color(0xFFF9A8D4), Color(0xFFFFE4EF), 6)),
  Venue(
      'Seoul',
      'Korea Selatan',
      '🇰🇷',
      'Min-jun',
      10000000,
      Color(0xFF0F3D6E),
      Color(0xFF93C5FD),
      0.003,
      TableSkin('Meja Hanok Biru', Color(0xFFE5E7EB), Color(0xFF6B7280),
          Color(0xFFEF4444), Color(0xFF111827), 7)),
  Venue(
      'Dubai',
      'Uni Emirat Arab',
      '🇦🇪',
      'Sheikh Rashid',
      25000000,
      Color(0xFF14532D),
      Color(0xFFFDE047),
      0.002,
      TableSkin('Meja Emas Arabesque', Color(0xFFD4A017), Color(0xFF6B4E00),
          Color(0xFFFFF7CC), Color(0xFF14532D), 8)),
  Venue(
      'Rio',
      'Brasil',
      '🇧🇷',
      'Carlos',
      50000000,
      Color(0xFF166534),
      Color(0xFFFACC15),
      0.001,
      TableSkin('Meja Samba Karnaval', Color(0xFF1D4ED8), Color(0xFF0B1F5C),
          Color(0xFFFACC15), Color(0xFFFFFFFF), 9)),
  Venue(
      'Cairo',
      'Mesir',
      '🇪🇬',
      'Khufu',
      100000000,
      Color(0xFF7C5A14),
      Color(0xFFFBBF24),
      0.0008,
      TableSkin('Meja Piramida Pasir', Color(0xFFC9A227), Color(0xFF5C4400),
          Color(0xFF38BDF8), Color(0xFF1E3A8A), 10)),
  Venue(
      'Paris',
      'Prancis',
      '🇫🇷',
      'Pierre',
      250000000,
      Color(0xFF7B1E3A),
      Color(0xFFFDA4AF),
      0.0006,
      TableSkin('Meja Fleur Royal', Color(0xFFF5F0E6), Color(0xFFB8A98A),
          Color(0xFF1D4ED8), Color(0xFF7B1E3A), 11)),
  Venue(
      'New York',
      'Amerika Serikat',
      '🇺🇸',
      'Mike',
      500000000,
      Color(0xFF0F2A43),
      Color(0xFF38BDF8),
      0.0004,
      TableSkin('Meja Manhattan Noir', Color(0xFF374151), Color(0xFF111827),
          Color(0xFFFACC15), Color(0xFFE5E7EB), 12)),
  Venue(
      'Las Vegas',
      'Amerika Serikat',
      '🇺🇸',
      'Tony',
      1000000000,
      Color(0xFF7F1D1D),
      Color(0xFFF43F5E),
      0.0002,
      TableSkin('Meja Kasino Neon', Color(0xFF1F1147), Color(0xFF0A0420),
          Color(0xFFF43F5E), Color(0xFFFDE047), 13)),
];

// ======================================================================
// UANG
// ======================================================================
String mx(double m) => m == m.roundToDouble() ? m.toInt().toString() : m.toString();

String rp(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp ${v < 0 ? '-' : ''}$b';
}

class Wallet {
  static const int startCoins = 2000000; // uang pertama 2M
  static final ValueNotifier<int> coins = ValueNotifier<int>(startCoins);
  static SharedPreferences? _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    coins.value = _p!.getInt('coins') ?? startCoins;
  }

  static Future<void> add(int d) async {
    coins.value += d;
    await _p?.setInt('coins', coins.value);
  }
}

// ======================================================================
// SUARA (aset: assets/sound/hit.mp3, coins.wav, arena.mp3 & lose.mp3)
// ======================================================================
class Sfx {
  static final List<AudioPlayer> _hit = [];
  static int _i = 0, _last = 0;
  static AudioPlayer? _coin, _arena, _lose;

  // ReleaseMode.stop + stop() sebelum play() agar suara bisa diputar
  // berulang kali (bukan hanya sekali).
  static Future<void> init() async {
    try {
      for (var k = 0; k < 6; k++) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        _hit.add(p);
      }
      final c = AudioPlayer();
      await c.setReleaseMode(ReleaseMode.stop);
      _coin = c;
      final a = AudioPlayer();
      await a.setReleaseMode(ReleaseMode.stop);
      _arena = a;
    } catch (_) {}
  }

  static Future<void> _go(AudioPlayer p, String asset, double vol) async {
    try {
      await p.stop();
      await p.setVolume(vol.clamp(0.0, 1.0));
      await p.play(AssetSource(asset));
    } catch (_) {}
  }

  // Bunyi bola/stik/bantalan; [vol] 0..1 sesuai kerasnya benturan.
  static void hit(double vol) {
    if (_hit.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _last < 35) return;
    _last = now;
    final p = _hit[_i++ % _hit.length];
    _go(p, 'sound/hit.mp3', vol.clamp(0.05, 1.0));
  }

  static void coins() {
    final c = _coin;
    if (c == null) return;
    _go(c, 'sound/coins.wav', 0.9);
  }

  // Nada turun yang lembut saat pemain kalah (assets/sound/lose.mp3)
  static Future<void> lose() async {
    try {
      var l = _lose;
      if (l == null) {
        l = AudioPlayer();
        await l.setReleaseMode(ReleaseMode.stop);
        _lose = l;
      }
      await _go(l, 'sound/lose.mp3', 0.85);
    } catch (_) {}
  }

  // Sfx koin tumpah saat pemain masuk arena (assets/sound/arena.mp3).
  static void arena() {
    final a = _arena;
    if (a == null) return;
    _go(a, 'sound/arena.mp3', 0.9);
  }
}

// ======================================================================
// BOT ACAK (nama & avatar berubah tiap pertandingan)
// ======================================================================
// Nama bot per negara arena (nama wajar, tidak alay)
const Map<String, List<String>> kBotNamePool = {
  'Indonesia': [
    'Rafi Pratama', 'Dimas Wijaya', 'Fajar Nugroho', 'Bagas Saputra',
    'Arya Mahendra', 'Reza Hakim', 'Galih Permana', 'Yoga Firmansyah',
    'Rangga Putra', 'Naufal Rizki', 'Ilham Kusuma', 'Bayu Santoso',
    'Hendra Lim', 'Kevin Wijaya', 'Alvin Tanoto', 'Dewi Lestari',
    'Nadia Putri', 'Sinta Maharani', 'Citra Anggun', 'Wayan Adi',
  ],
  'Singapore': [
    'Tan Wei Ming', 'Lim Jun Hao', 'Marcus Chua', 'Daniel Ong',
    'Jasmine Koh', 'Ryan Teo', 'Aaron Lee', 'Wei Lin', 'Kelvin Goh',
    'Shawn Ng',
  ],
  'Thailand': [
    'Somchai K.', 'Kittisak P.', 'Anan Suwan', 'Pichai T.', 'Ploy Rattana',
    'Nattaya S.', 'Chanon S.', 'Thanawat J.', 'Arthit M.', 'Narin Chai',
  ],
  'Malaysia': [
    'Amir Hakimi', 'Faiz Rahman', 'Hafiz Azman', 'Aiman Zikri',
    'Syafiq Ali', 'Nurul Aina', 'Farid Hassan', 'Irfan Danial',
    'Haziq Roslan', 'Zulkifli R.',
  ],
  'Jepang': [
    'Kenji Tanaka', 'Hiro Yamada', 'Ryu Sato', 'Takumi Mori', 'Daiki Ito',
    'Haruto Kimura', 'Sora Nakamura', 'Yuki Hayashi', 'Ren Matsuda',
    'Aoi Fujita',
  ],
  'Korea Selatan': [
    'Min-jun Kim', 'Seo-jun Park', 'Ji-ho Lee', 'Do-yoon Choi',
    'Hyun-woo Han', 'Joon-ho Kang', 'Ha-eun Yoon', 'Seung-min Oh',
    'Ji-woo Shin', 'Tae-hyun Bae',
  ],
  'Uni Emirat Arab': [
    'Rashid Mansour', 'Khalid Farouk', 'Omar Al Falasi', 'Hamdan Saeed',
    'Zayed Karim', 'Yousef Haddad', 'Tariq Nasser', 'Faisal Aziz',
    'Layla Rahman', 'Saif Khalil',
  ],
  'Brasil': [
    'Carlos Mendes', 'Rafael Souza', 'Thiago Lima', 'Bruno Alves',
    'Lucas Ferraz', 'Mateus Rocha', 'Diego Santos', 'Gabriel Costa',
    'Camila Duarte', 'Pedro Lopes',
  ],
  'Mesir': [
    'Omar Farouk', 'Karim Mostafa', 'Youssef Adel', 'Tarek Salem',
    'Ahmed Nabil', 'Hossam Reda', 'Mahmoud Fawzy', 'Amr Sherif',
    'Nour Hamed', 'Mariam Saad',
  ],
  'Prancis': [
    'Pierre Dubois', 'Louis Marchand', 'Hugo Lefevre', 'Antoine Roux',
    'Julien Moreau', 'Mathis Girard', 'Etienne Blanc', 'Camille Laurent',
    'Lucas Bernard', 'Theo Fontaine',
  ],
  'Amerika Serikat': [
    'Mike Sullivan', 'Tony Russo', 'Jake Morgan', 'Ethan Brooks',
    'Ryan Caldwell', 'Nathan Cole', 'Chris Walker', 'Dylan Hayes',
    'Jordan Pierce', 'Austin Reed',
  ],
};

// Urutan avatar dari yang paling sederhana ke yang paling mewah.
// Bot di arena murah memakai avatar awal, bot di arena mahal memakai
// avatar akhir (mahkota, macan kumbang, bola api).
const List<int> kAvatarRank = [4, 5, 0, 6, 3, 2, 8, 1, 7, 9];

// Border bot per tingkat arena (indeks = urutan arena di kVenues).
// Makin mahal arena, makin mahal & bagus border lawannya.
const List<List<String>> kBotBorderTiers = [
  ['basic'], // Bandung
  ['basic', 'bronze'], // Jakarta
  ['silver'], // Bekasi
  ['silver', 'gold'], // Singapore
  ['gold', 'streak'], // Thailand
  ['neon'], // Malaysia
  ['neon', 'rose'], // Osaka
  ['rose', 'globe'], // Seoul
  ['royal'], // Dubai
  ['royal', 'vegas'], // Rio
  ['inferno'], // Cairo
  ['inferno', 'champion'], // Paris
  ['champion', 'diamond', 'phoenix'], // New York
  ['diamond', 'phoenix', 'galaxy'], // Las Vegas
];

// Skin cue bot per tingkat arena (hanya tampilan, tidak mengubah kekuatan bot)
const List<List<String>> kBotCueTiers = [
  ['classic'], // Bandung
  ['classic'], // Jakarta
  ['ebony'], // Bekasi
  ['ebony', 'ruby'], // Singapore
  ['ruby'], // Thailand
  ['ocean'], // Malaysia
  ['ocean', 'gold'], // Osaka
  ['gold'], // Seoul
  ['galaxy', 'blaze'], // Dubai
  ['blaze', 'frost'], // Rio
  ['frost', 'galaxy'], // Cairo
  ['thunder'], // Paris
  ['thunder', 'dragon'], // New York
  ['dragon', 'prism'], // Las Vegas
];

class BotProfile {
  final String name;
  final int avatar; // indeks di kAvatars
  final String border; // id di kBorders
  final String cue; // id di kCues
  const BotProfile(this.name, this.avatar, this.border, [this.cue = 'classic']);
  static const empty = BotProfile('Lawan', 4, 'basic');
  CueSkin get cueSkin =>
      kCues.firstWhere((c) => c.id == cue, orElse: () => kCues.first);
}

int _venueTier(Venue v) {
  final i = kVenues.indexWhere((e) => e.name == v.name);
  return (i < 0 ? 0 : i).clamp(0, kBotBorderTiers.length - 1).toInt();
}

// Bot acak tiap pertandingan. Makin mahal arena -> makin mahal border &
// makin mewah avatar. Avatar bot selalu beda dari avatar pemain.
BotProfile makeBot(Venue v, Random r, {int? avoidAvatar}) {
  final t = _venueTier(v);
  final names = kBotNamePool[v.country] ?? kBotNamePool['Indonesia']!;
  final name = names[r.nextInt(names.length)];
  final center = t / (kVenues.length - 1) * (kAvatarRank.length - 1);
  final cand = <int>[];
  for (var k = 0; k < kAvatarRank.length; k++) {
    final a = kAvatarRank[k];
    if ((k - center).abs() <= 2.2 && a != avoidAvatar) cand.add(a);
  }
  if (cand.isEmpty) cand.add(kAvatarRank[center.round()]);
  final avatar = cand[r.nextInt(cand.length)];
  final bs = kBotBorderTiers[t];
  final cs = kBotCueTiers[t];
  return BotProfile(
      name, avatar, bs[r.nextInt(bs.length)], cs[r.nextInt(cs.length)]);
}

// Dipakai animasi "mencari lawan" (nama & avatar berganti cepat)
BotProfile flickerBot(Random r) {
  final pools = kBotNamePool.values.toList();
  final pool = pools[r.nextInt(pools.length)];
  return BotProfile(
      pool[r.nextInt(pool.length)], r.nextInt(kAvatars.length), 'basic');
}

// ======================================================================
// SKIN CUE
// ======================================================================
// Efek 2D animasi pada cue
enum CueFx { none, shine, fire, electric, sparkle, rainbow }

// Jam global untuk efek (detik). Dipakai painter mana pun tanpa controller.
final Stopwatch _fxClock = Stopwatch()..start();
double get _fxNow => _fxClock.elapsedMilliseconds / 1000.0;

class CueSkin {
  final String id, name, desc;
  final int price, level; // harga & level minimal
  final List<Color> shaft; // 3 warna: ujung -> pangkal
  final Color ring, tip;
  final bool glow;
  // Kekuatan cue: power = pengali kecepatan pukulan, acc = akurasi (0..1,
  // makin tinggi makin lurus), aim = pengali panjang garis bidik.
  final double power, acc, aim;
  final CueFx fx;
  final List<Color> fxColors; // [luar, tengah, inti]
  const CueSkin(this.id, this.name, this.desc, this.price, this.level,
      this.shaft, this.ring, this.tip,
      {this.glow = false,
      this.power = 1.0,
      this.acc = 0.70,
      this.aim = 1.0,
      this.fx = CueFx.none,
      this.fxColors = const []});

  List<Color> get fx3 => fxColors.length >= 3
      ? fxColors
      : [shaft[1], ring, const Color(0xFFFFFFFF)];
}

const List<CueSkin> kCues = [
  CueSkin('classic', 'Klasik', 'Kayu maple standar', 0, 1,
      [Color(0xFFF3D9A4), Color(0xFFB9803F), Color(0xFF3A2312)],
      Color(0xFFC9A227), Color(0xFF3B82F6),
      power: 1.0, acc: 0.70, aim: 1.0, fx: CueFx.shine),
  CueSkin('ebony', 'Eboni', 'Hitam elegan dengan cincin emas', 250000, 2,
      [Color(0xFFD9C7A0), Color(0xFF2B2B2B), Color(0xFF0A0A0A)],
      Color(0xFFD4AF37), Color(0xFF22C55E),
      power: 1.10, acc: 0.78, aim: 1.25, fx: CueFx.shine),
  CueSkin('ruby', 'Ruby', 'Merah menyala, api menjilat', 500000, 3,
      [Color(0xFFFDE2E2), Color(0xFFDC2626), Color(0xFF450A0A)],
      Color(0xFFFACC15), Color(0xFFEF4444),
      power: 1.20,
      acc: 0.85,
      aim: 1.5,
      fx: CueFx.fire,
      fxColors: [Color(0xFFDC2626), Color(0xFFF97316), Color(0xFFFDE047)]),
  CueSkin('ocean', 'Samudra', 'Biru laut dengan percikan petir', 750000, 5,
      [Color(0xFFE0F2FE), Color(0xFF0284C7), Color(0xFF0C2A4A)],
      Color(0xFF22D3EE), Color(0xFF38BDF8),
      power: 1.30,
      acc: 0.90,
      aim: 1.75,
      fx: CueFx.electric,
      fxColors: [Color(0xFF0EA5E9), Color(0xFF22D3EE), Color(0xFFFFFFFF)]),
  CueSkin('gold', 'Emas Sultan', 'Berkilau keemasan', 2500000, 8,
      [Color(0xFFFFF7CC), Color(0xFFF5B301), Color(0xFF7A4B00)],
      Color(0xFFFFFFFF), Color(0xFF111111),
      glow: true,
      power: 1.45,
      acc: 0.96,
      aim: 2.0,
      fx: CueFx.sparkle,
      fxColors: [Color(0xFFD97706), Color(0xFFFDE047), Color(0xFFFFFBEB)]),
  CueSkin('galaxy', 'Galaksi', 'Ungu kosmik bercahaya', 4000000, 12,
      [Color(0xFFF5D0FE), Color(0xFF9333EA), Color(0xFF1E1B4B)],
      Color(0xFF22D3EE), Color(0xFFF472B6),
      glow: true,
      power: 1.60,
      acc: 1.0,
      aim: 2.4,
      fx: CueFx.sparkle,
      fxColors: [Color(0xFF9333EA), Color(0xFFE879F9), Color(0xFFFFFFFF)]),
  // ---- 5 cue baru (bisa dibeli di toko) ----
  CueSkin('blaze', 'Api Neraka', 'Cue berapi, nyala sepanjang batang', 6000000, 10,
      [Color(0xFFFFEDD5), Color(0xFFEA580C), Color(0xFF3B0A02)],
      Color(0xFFFDE047), Color(0xFFF97316),
      glow: true,
      power: 1.65,
      acc: 1.0,
      aim: 2.5,
      fx: CueFx.fire,
      fxColors: [Color(0xFFDC2626), Color(0xFFF97316), Color(0xFFFDE047)]),
  CueSkin('frost', 'Kristal Es', 'Es berkilau, bintang salju menari', 9000000, 12,
      [Color(0xFFF0F9FF), Color(0xFF7DD3FC), Color(0xFF0C4A6E)],
      Color(0xFFFFFFFF), Color(0xFF67E8F9),
      glow: true,
      power: 1.70,
      acc: 1.0,
      aim: 2.6,
      fx: CueFx.sparkle,
      fxColors: [Color(0xFF38BDF8), Color(0xFFBAE6FD), Color(0xFFFFFFFF)]),
  CueSkin('thunder', 'Petir', 'Sambaran petir biru menyelimuti cue', 14000000, 14,
      [Color(0xFFE0E7FF), Color(0xFF4F46E5), Color(0xFF0F0A3C)],
      Color(0xFFFDE047), Color(0xFFA5B4FC),
      glow: true,
      power: 1.75,
      acc: 1.0,
      aim: 2.8,
      fx: CueFx.electric,
      fxColors: [Color(0xFF6366F1), Color(0xFFA5B4FC), Color(0xFFFFFFFF)]),
  CueSkin('dragon', 'Naga Emas', 'Api emas naga, kuat dan presisi', 22000000, 16,
      [Color(0xFFFEF3C7), Color(0xFFB45309), Color(0xFF1C0A00)],
      Color(0xFFFDE047), Color(0xFFDC2626),
      glow: true,
      power: 1.80,
      acc: 1.0,
      aim: 3.0,
      fx: CueFx.fire,
      fxColors: [Color(0xFFF59E0B), Color(0xFFFDE047), Color(0xFFFFFFFF)]),
  CueSkin('prism', 'Prisma', 'Warna pelangi berputar + kilau bintang', 35000000, 18,
      [Color(0xFFFFFFFF), Color(0xFFF472B6), Color(0xFF312E81)],
      Color(0xFFFFFFFF), Color(0xFFFFFFFF),
      glow: true,
      power: 1.85,
      acc: 1.0,
      aim: 3.2,
      fx: CueFx.rainbow,
      fxColors: [Color(0xFFF472B6), Color(0xFF22D3EE), Color(0xFFFFFFFF)]),
];

// Menggambar cue dari [tip] (ujung pukul) ke arah berlawanan [dir].
void drawCue(Canvas c, CueSkin s, Offset tip, Offset dir,
    {double length = 480,
    double wTip = 2.2,
    double wEnd = 5,
    bool shadow = true}) {
  final perp = Offset(-dir.dy, dir.dx);
  final end = tip - dir * length;
  final path = Path()
    ..moveTo(tip.dx + perp.dx * wTip, tip.dy + perp.dy * wTip)
    ..lineTo(end.dx + perp.dx * wEnd, end.dy + perp.dy * wEnd)
    ..lineTo(end.dx - perp.dx * wEnd, end.dy - perp.dy * wEnd)
    ..lineTo(tip.dx - perp.dx * wTip, tip.dy - perp.dy * wTip)
    ..close();
  if (shadow) {
    c.drawPath(path.shift(const Offset(3, 4)),
        Paint()..color = Colors.black.withAlpha(70));
  }
  final u = (_fxNow % 3.0) / 3.0; // putaran 3 detik
  var shaftCols = s.shaft;
  var glowCol = s.ring;
  if (s.fx == CueFx.rainbow) {
    // warna pelangi berputar sepanjang batang
    Color hue(double h, double v) =>
        HSVColor.fromAHSV(1, (h % 360 + 360) % 360, 0.55, v).toColor();
    final h0 = u * 360;
    shaftCols = [hue(h0, 1.0), hue(h0 + 90, 0.95), hue(h0 + 200, 0.35)];
    glowCol = hue(h0 + 45, 1.0);
  }
  if (s.glow) {
    c.drawPath(
        path,
        Paint()
          ..color = glowCol.withAlpha(140)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }
  c.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
            tip, end, shaftCols, const [0.0, 0.55, 1.0]));
  final band = max(1.5, length * 0.009);
  for (final f in const [0.70, 0.745]) {
    final m = tip - dir * (length * f);
    final w = wTip + (wEnd - wTip) * f;
    c.drawLine(m + perp * w, m - perp * w,
        Paint()
          ..color = s.ring
          ..strokeWidth = band);
  }
  c.drawLine(
      tip,
      tip - dir * max(4.0, length * 0.02),
      Paint()
        ..color = s.tip
        ..strokeWidth = wTip * 2.1);
  if (s.fx != CueFx.none) {
    _cueFx(c, s, tip, dir, perp, length, wTip, wEnd, u);
  }
}

double _cueHash(int i, int salt) {
  final x = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

Path _cueStar(Offset c, double l) {
  final i = l * 0.22;
  return Path()
    ..moveTo(c.dx, c.dy - l)
    ..lineTo(c.dx + i, c.dy - i)
    ..lineTo(c.dx + l, c.dy)
    ..lineTo(c.dx + i, c.dy + i)
    ..lineTo(c.dx, c.dy + l)
    ..lineTo(c.dx - i, c.dy + i)
    ..lineTo(c.dx - l, c.dy)
    ..lineTo(c.dx - i, c.dy - i)
    ..close();
}

// Efek 2D di sepanjang batang cue. f = 0 di ujung pukul, 1 di pangkal.
void _cueFx(Canvas c, CueSkin s, Offset tip, Offset dir, Offset perp,
    double length, double wTip, double wEnd, double u) {
  final cols = s.fx3;
  double wAt(double f) => wTip + (wEnd - wTip) * f;
  Offset at(double f, double off) => tip - dir * (length * f) + perp * off;
  final sc = max(3.0, length * 0.02); // satuan ukuran efek
  switch (s.fx) {
    case CueFx.shine:
      // pita kilau putih meluncur dari ujung ke pangkal
      final f0 = u * 1.3 - 0.15;
      final seg = Path();
      final a = f0.clamp(0.0, 1.0).toDouble(),
          b = (f0 + 0.10).clamp(0.0, 1.0).toDouble();
      if (b - a > 0.002) {
        seg
          ..moveTo(at(a, wAt(a)).dx, at(a, wAt(a)).dy)
          ..lineTo(at(b, wAt(b)).dx, at(b, wAt(b)).dy)
          ..lineTo(at(b, -wAt(b)).dx, at(b, -wAt(b)).dy)
          ..lineTo(at(a, -wAt(a)).dx, at(a, -wAt(a)).dy)
          ..close();
        c.drawPath(seg, Paint()..color = Colors.white.withAlpha(120));
      }
      break;
    case CueFx.fire:
      final n = max(8, (length / 26).round());
      final paint = Paint()..style = PaintingStyle.fill;
      const hs = [1.0, 0.66, 0.36];
      const ws = [1.0, 0.7, 0.4];
      const al = [200, 230, 248];
      for (var layer = 0; layer < 3; layer++) {
        paint.color = cols[layer].withAlpha(al[layer]);
        for (var i = 0; i < n; i++) {
          final f = 0.06 + 0.9 * (i + 0.5) / n;
          final side = i.isEven ? 1.0 : -1.0;
          final ph = _cueHash(i, 1);
          final k = 3 + (i * 7 + 2) % 5;
          final fl = 0.5 + 0.5 * sin(2 * pi * (k * u + ph));
          final wave = 0.5 + 0.5 * sin(2 * pi * (3 * f - u));
          final h = sc * 1.5 * (0.4 + 0.6 * (0.55 * fl + 0.45 * wave)) *
              hs[layer] * (0.8 + 0.4 * _cueHash(i, 2));
          final hw = length / n * 0.55 * ws[layer];
          final base = at(f, side * wAt(f) * 0.6);
          final bl = base - dir * hw;
          final br = base + dir * hw;
          // ujung api condong ke belakang (ke arah pangkal) seperti terbawa angin
          final tipP = base + perp * (side * h) - dir * (h * 0.35 + sin(2 * pi * (k - 1) * u) * h * 0.2);
          final c1 = bl + perp * (side * h * 0.55);
          final c2 = br + perp * (side * h * 0.55);
          final path = Path()
            ..moveTo(bl.dx, bl.dy)
            ..quadraticBezierTo(c1.dx, c1.dy, tipP.dx, tipP.dy)
            ..quadraticBezierTo(c2.dx, c2.dy, br.dx, br.dy)
            ..close();
          c.drawPath(path, paint);
        }
      }
      // bara kecil naik dari batang
      for (var j = 0; j < 6; j++) {
        final life = (u * (1 + j % 2) + _cueHash(j, 3)) % 1.0;
        final side = j.isEven ? 1.0 : -1.0;
        final base = at(0.1 + 0.8 * _cueHash(j, 4), side * wAt(0.5));
        final pos = base + perp * (side * life * sc * 3.2);
        paint.color = Color.lerp(cols[2], cols[0], life)!
            .withAlpha((255 * (1 - life)).round().clamp(0, 255).toInt());
        c.drawCircle(pos, (1 - life) * sc * 0.4 + 0.5, paint);
      }
      break;
    case CueFx.electric:
      final step = (u * 24).floor();
      final glowP = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = max(2.0, sc * 0.9)
        ..color = cols[0].withAlpha(120);
      final midP = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = max(1.2, sc * 0.45)
        ..color = cols[1].withAlpha(220);
      final coreP = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = max(0.8, sc * 0.22)
        ..color = cols[2];
      for (var a = 0; a < 3; a++) {
        final r = Random(step * 17 + a * 101);
        if (r.nextDouble() < 0.2) continue; // kedip
        final f0 = 0.03 + r.nextDouble() * 0.65;
        final span = 0.14 + r.nextDouble() * 0.2;
        final side = r.nextBool() ? 1.0 : -1.0;
        const seg = 9;
        final path = Path();
        for (var k = 0; k <= seg; k++) {
          final f = (f0 + span * k / seg).clamp(0.0, 1.0).toDouble();
          final off = side * (wAt(f) + (k == 0 || k == seg ? 0.0 : (0.2 + r.nextDouble() * 1.3) * sc))
              + (r.nextDouble() - 0.5) * sc * 0.6;
          final pt = at(f, off);
          if (k == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        c.drawPath(path, glowP);
        c.drawPath(path, midP);
        c.drawPath(path, coreP);
      }
      break;
    case CueFx.sparkle:
    case CueFx.rainbow:
      final m = max(5, (length / 40).round());
      final fill = Paint()..style = PaintingStyle.fill;
      for (var j = 0; j < m; j++) {
        final k = 1 + (j % 2);
        final life = (u * k + _cueHash(j, 7)) % 1.0;
        final sp = pow(sin(pi * life), 2).toDouble();
        if (sp < 0.02) continue;
        final f = 0.05 + 0.9 * _cueHash(j, 8);
        final off = (_cueHash(j, 9) - 0.5) * 2 * (wAt(f) + sc * 1.4);
        final pos = at(f, off);
        final l = sc * (0.9 + 0.8 * _cueHash(j, 10)) * sp;
        fill.color = cols[1].withAlpha(150);
        c.drawPath(_cueStar(pos, l * 1.35), fill);
        fill.color = cols[2];
        c.drawPath(_cueStar(pos, l), fill);
      }
      break;
    case CueFx.none:
      break;
  }
}

// ======================================================================
// PROFIL PEMAIN
// ======================================================================
// 10 avatar bawaan (gambar). File: assets/avatars/av_0.png .. av_9.png
const List<String> kAvatars = [
  'assets/avatars/av_0.png', // hoodie + bola 8 (biru)
  'assets/avatars/av_1.png', // bola 8 + mahkota emas
  'assets/avatars/av_2.png', // serigala biru
  'assets/avatars/av_3.png', // bola 8 + dua stik (perak)
  'assets/avatars/av_4.png', // pemain di bar
  'assets/avatars/av_5.png', // bola 8 di meja hijau
  'assets/avatars/av_6.png', // pemain bertopi (ungu)
  'assets/avatars/av_7.png', // macan kumbang + mahkota
  'assets/avatars/av_8.png', // ular merah
  'assets/avatars/av_9.png', // bola 8 berapi + stik
];
// warna latar cadangan (dipakai bila gambar gagal dimuat)
const List<Color> kAvatarColors = [
  Color(0xFF0B2A6E),
  Color(0xFF3B2A07),
  Color(0xFF0B1E4D),
  Color(0xFF1F2937),
  Color(0xFF3B2410),
  Color(0xFF0B3B2E),
  Color(0xFF2E1065),
  Color(0xFF3B2A07),
  Color(0xFF450A0A),
  Color(0xFF3B2410),
];

String? validateName(String raw) {
  final s = raw.trim();
  if (s.length < 3) return 'Minimal 3 karakter';
  if (s.length > 14) return 'Maksimal 14 karakter';
  if (!RegExp(r'^[A-Za-z0-9_ ]+$').hasMatch(s)) {
    return 'Hanya huruf, angka, spasi, dan _';
  }
  return null;
}

class ProfileStore extends ChangeNotifier {
  ProfileStore._();
  static final ProfileStore i = ProfileStore._();

  static const int xpPerLevel = 100;
  static const int xpWin = 40, xpLose = 10;

  SharedPreferences? _p;
  String name = '';
  int avatar = 0, wins = 0, losses = 0, xp = 0;
  String cueId = 'classic';
  Set<String> owned = {'classic'};
  String borderId = 'basic';
  Set<String> ownedBorders = {'basic'};

  bool get isNew => name.isEmpty;
  int get level => 1 + xp ~/ xpPerLevel;
  double get levelProgress => (xp % xpPerLevel) / xpPerLevel;
  int get games => wins + losses;
  int get winRate => games == 0 ? 0 : (wins * 100 / games).round();
  CueSkin get cue =>
      kCues.firstWhere((c) => c.id == cueId, orElse: () => kCues.first);

  Future<void> init() async {
    final p = _p = await SharedPreferences.getInstance();
    name = p.getString('p_name') ?? '';
    avatar = (p.getInt('p_avatar') ?? 0) % kAvatars.length;
    wins = p.getInt('p_wins') ?? 0;
    losses = p.getInt('p_losses') ?? 0;
    xp = p.getInt('p_xp') ?? 0;
    cueId = p.getString('p_cue') ?? 'classic';
    owned = (p.getStringList('p_owned') ?? <String>['classic']).toSet()
      ..add('classic');
    ownedBorders = (p.getStringList('p_borders') ?? <String>['basic']).toSet()
      ..add('basic');
    borderId = p.getString('p_border') ?? 'basic';
    if (!ownedBorders.contains(borderId) ||
        !kBorders.any((b) => b.id == borderId)) {
      borderId = 'basic';
    }
  }

  Future<void> _save() async {
    final p = _p;
    if (p == null) return;
    await p.setString('p_name', name);
    await p.setInt('p_avatar', avatar);
    await p.setInt('p_wins', wins);
    await p.setInt('p_losses', losses);
    await p.setInt('p_xp', xp);
    await p.setString('p_cue', cueId);
    await p.setStringList('p_owned', owned.toList());
    await p.setString('p_border', borderId);
    await p.setStringList('p_borders', ownedBorders.toList());
  }

  Future<void> setProfile(String newName, int newAvatar) async {
    name = newName.trim();
    avatar = newAvatar % kAvatars.length;
    notifyListeners();
    await _save();
  }

  // Catat hasil pertandingan. Mengembalikan true jika naik level.
  Future<bool> record(bool win) async {
    final before = level;
    if (win) {
      wins++;
      xp += xpWin;
    } else {
      losses++;
      xp += xpLose;
    }
    notifyListeners();
    await _save();
    return level > before;
  }

  // Dipakai Bloader: naikkan level langsung (tiap level = xpPerLevel XP)
  Future<void> addLevels(int n) async {
    if (n <= 0) return;
    xp += n * xpPerLevel;
    notifyListeners();
    await _save();
  }

  Future<void> equip(String id) async {
    if (!owned.contains(id)) return;
    cueId = id;
    notifyListeners();
    await _save();
  }

  Future<bool> buy(CueSkin c) async {
    if (owned.contains(c.id) ||
        level < c.level ||
        Wallet.coins.value < c.price) {
      return false;
    }
    await Wallet.add(-c.price);
    owned.add(c.id);
    cueId = c.id;
    notifyListeners();
    await _save();
    return true;
  }

  // ---- border avatar ----
  AvatarBorder get border => borderById(borderId);

  Future<void> equipBorder(String id) async {
    if (!ownedBorders.contains(id)) return;
    borderId = id;
    notifyListeners();
    await _save();
  }

  Future<bool> buyBorder(AvatarBorder b) async {
    if (ownedBorders.contains(b.id) ||
        b.price <= 0 ||
        level < b.minLevel ||
        Wallet.coins.value < b.price) {
      return false;
    }
    await Wallet.add(-b.price);
    ownedBorders.add(b.id);
    borderId = b.id;
    notifyListeners();
    await _save();
    return true;
  }

  // dipakai oleh hadiah misi (tidak otomatis dipasang)
  Future<void> grantBorder(String id) async {
    if (!kBorders.any((b) => b.id == id)) return;
    if (ownedBorders.add(id)) {
      notifyListeners();
      await _save();
    }
  }
}

// ======================================================================
// MOD (fitur tambahan)
// ======================================================================
class Mod extends ChangeNotifier {
  Mod._();
  static final Mod i = Mod._();
  static const int injectAmount = 1000000;

  bool autoplay = false, autoQueue = false, longLine = false, autoBounce = false;
  // Bekukan lawan (bot). Pemain (kamu) tidak pernah ikut dibekukan.
  bool freezeOpp = false;

  // Mod HANYA jalan saat Bloader aktif. Bloader mengirim "detak" tiap
  // beberapa detik; kalau berhenti (Stop Mods / aplikasi ditutup) semua mod
  // mati sendiri. Pengaturan tidak disimpan, jadi tiap game dibuka mod mati.
  DateTime? _lastPing;
  Timer? _watch;
  bool get active =>
      _lastPing != null &&
      DateTime.now().difference(_lastPing!) < const Duration(seconds: 12);

  bool get anyOn => autoplay || autoQueue || longLine || autoBounce || freezeOpp;

  Future<void> init() async {
    // hapus pengaturan mod lama dari versi sebelumnya
    final p = await SharedPreferences.getInstance();
    for (final k in ['m_auto', 'm_queue', 'm_long', 'm_bounce']) {
      await p.remove(k);
    }
    _watch?.cancel();
    _watch = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!active && anyOn) reset();
    });
  }

  // dipanggil Bloader (detak)
  void ping() {
    final was = active;
    _lastPing = DateTime.now();
    if (!was) notifyListeners();
  }

  void deactivate() {
    _lastPing = null;
    reset();
  }

  void reset() {
    autoplay = autoQueue = longLine = autoBounce = freezeOpp = false;
    notifyListeners();
  }

  void set(
      {bool? autoplay,
      bool? autoQueue,
      bool? longLine,
      bool? autoBounce,
      bool? freezeOpp}) {
    if (!active) return;
    if (autoplay != null) {
      this.autoplay = autoplay;
      if (!autoplay) this.autoBounce = false;
    }
    if (autoBounce != null) {
      this.autoBounce = autoBounce;
      if (autoBounce) this.autoplay = true;
    }
    if (autoQueue != null) this.autoQueue = autoQueue;
    if (longLine != null) this.longLine = longLine;
    if (freezeOpp != null) this.freezeOpp = freezeOpp;
    notifyListeners();
  }
}

// ======================================================================
// BORDER AVATAR (bisa dibeli atau didapat dari misi)
// ======================================================================
// Jenis efek 2D animasi di sekeliling border
enum BorderFx { none, shine, fire, electric, sparkle }

class AvatarBorder {
  final String id, name;
  final List<Color> colors;
  final int price, minLevel;
  final String? mission; // id misi yang memberi border ini
  final double width;
  final bool glow, twin;
  final BorderFx fx;
  final List<Color> fxColors; // [luar, tengah, inti]
  final double fxPower; // 1 = normal; >1 api lebih besar
  const AvatarBorder(this.id, this.name, this.colors,
      {this.price = 0,
      this.minLevel = 1,
      this.mission,
      this.width = 3,
      this.glow = false,
      this.twin = false,
      this.fx = BorderFx.none,
      this.fxColors = const [],
      this.fxPower = 1});

  List<Color> get fx3 => fxColors.length >= 3
      ? fxColors
      : [
          colors.first,
          colors[colors.length > 1 ? 1 : 0],
          const Color(0xFFFFFFFF)
        ];
}

const List<AvatarBorder> kBorders = [
  AvatarBorder('basic', 'Standar', [Color(0xFFFACC15), Color(0xFFF59E0B)],
      width: 2, fx: BorderFx.shine),
  AvatarBorder('silver', 'Perak',
      [Color(0xFFF1F5F9), Color(0xFF94A3B8), Color(0xFFE2E8F0)],
      price: 300000, fx: BorderFx.shine),
  AvatarBorder('gold', 'Emas',
      [Color(0xFFFDE047), Color(0xFFD97706), Color(0xFFFDE047)],
      price: 500000,
      fx: BorderFx.sparkle,
      fxColors: [Color(0xFFD97706), Color(0xFFFDE047), Color(0xFFFFFBEB)]),
  AvatarBorder('neon', 'Neon',
      [Color(0xFF22D3EE), Color(0xFF3B82F6), Color(0xFF22D3EE)],
      price: 2000000,
      mission: 'm_pot500',
      glow: true,
      fx: BorderFx.electric,
      fxColors: [Color(0xFF0EA5E9), Color(0xFF22D3EE), Color(0xFFFFFFFF)]),
  AvatarBorder('rose', 'Mawar',
      [Color(0xFFFB7185), Color(0xFFE11D48), Color(0xFFFDA4AF)],
      price: 5000000,
      twin: true,
      fx: BorderFx.sparkle,
      fxColors: [Color(0xFFE11D48), Color(0xFFFB7185), Color(0xFFFFE4E6)]),
  AvatarBorder('royal', 'Royal',
      [Color(0xFFA855F7), Color(0xFFFACC15), Color(0xFFA855F7)],
      price: 25000000,
      minLevel: 5,
      mission: 'm_lvl10',
      glow: true,
      twin: true,
      fx: BorderFx.fire,
      fxColors: [Color(0xFF7C3AED), Color(0xFFC084FC), Color(0xFFF5D0FE)]),
  AvatarBorder('inferno', 'Api',
      [Color(0xFFFACC15), Color(0xFFEA580C), Color(0xFFDC2626)],
      price: 60000000,
      glow: true,
      width: 4,
      fx: BorderFx.fire,
      fxPower: 1.25,
      fxColors: [Color(0xFFDC2626), Color(0xFFF97316), Color(0xFFFDE047)]),
  AvatarBorder('diamond', 'Berlian',
      [Color(0xFFA5F3FC), Color(0xFFFFFFFF), Color(0xFF67E8F9), Color(0xFFFFFFFF)],
      price: 150000000,
      minLevel: 8,
      glow: true,
      twin: true,
      width: 4,
      fx: BorderFx.sparkle,
      fxColors: [Color(0xFF67E8F9), Color(0xFFA5F3FC), Color(0xFFFFFFFF)]),
  AvatarBorder('bronze', 'Perunggu',
      [Color(0xFFF59E0B), Color(0xFF92400E), Color(0xFFFBBF24)],
      mission: 'm_win25',
      fx: BorderFx.fire,
      fxPower: 0.8,
      fxColors: [Color(0xFF92400E), Color(0xFFF59E0B), Color(0xFFFEF3C7)]),
  AvatarBorder('champion', 'Juara',
      [Color(0xFFFDE047), Color(0xFFFFFFFF), Color(0xFFF59E0B), Color(0xFFFFFFFF)],
      mission: 'm_win100',
      glow: true,
      twin: true,
      width: 4,
      fx: BorderFx.fire,
      fxPower: 1.1,
      fxColors: [Color(0xFFF59E0B), Color(0xFFFDE047), Color(0xFFFFFFFF)]),
  AvatarBorder('globe', 'Dunia',
      [Color(0xFF22C55E), Color(0xFF0EA5E9), Color(0xFF22C55E)],
      mission: 'm_arena5',
      glow: true,
      fx: BorderFx.fire,
      fxColors: [Color(0xFF0EA5E9), Color(0xFF22C55E), Color(0xFFD9F99D)]),
  AvatarBorder('vegas', 'Vegas',
      [Color(0xFFF43F5E), Color(0xFFFDE047), Color(0xFFF43F5E), Color(0xFF7C3AED)],
      mission: 'm_vegas',
      glow: true,
      twin: true,
      fx: BorderFx.fire,
      fxColors: [Color(0xFF7C3AED), Color(0xFFF43F5E), Color(0xFFFDE047)]),
  AvatarBorder('streak', 'Streak',
      [Color(0xFF38BDF8), Color(0xFFA7F3D0), Color(0xFF38BDF8)],
      mission: 'm_daily7',
      fx: BorderFx.electric,
      fxColors: [Color(0xFF0EA5E9), Color(0xFFA7F3D0), Color(0xFFFFFFFF)]),
  AvatarBorder('phoenix', 'Phoenix',
      [Color(0xFFFDE047), Color(0xFFF97316), Color(0xFFDC2626), Color(0xFFFDE047)],
      price: 300000000,
      minLevel: 10,
      glow: true,
      twin: true,
      width: 5,
      fx: BorderFx.fire,
      fxPower: 1.5,
      fxColors: [Color(0xFFB91C1C), Color(0xFFFB923C), Color(0xFFFEF9C3)]),
  AvatarBorder('galaxy', 'Galaksi',
      [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF22D3EE), Color(0xFF6366F1)],
      price: 750000000,
      minLevel: 12,
      glow: true,
      twin: true,
      width: 5,
      fx: BorderFx.sparkle,
      fxColors: [Color(0xFF4338CA), Color(0xFFEC4899), Color(0xFFFFFFFF)]),
];

AvatarBorder borderById(String id) =>
    kBorders.firstWhere((b) => b.id == id, orElse: () => kBorders.first);

// ======================================================================
// SETELAN GAME (roda bidik + grafik)
// ======================================================================
class GameSettings extends ChangeNotifier {
  GameSettings._();
  static final GameSettings i = GameSettings._();

  SharedPreferences? _p;
  bool aimWheel = true;
  double wheelSens = 0.5; // 0.1 (halus) .. 1.0 (cepat)
  bool pattern = true, shadows = true, shine = true, effects = true;
  bool fps30 = false;

  // 0 rendah, 1 sedang, 2 tinggi, -1 kustom
  int get quality {
    if (!pattern && !shadows && !shine && !effects) return 0;
    if (pattern && shadows && !shine && !effects) return 1;
    if (pattern && shadows && shine && effects) return 2;
    return -1;
  }

  Future<void> init() async {
    final p = _p = await SharedPreferences.getInstance();
    aimWheel = p.getBool('s_wheel') ?? true;
    wheelSens = (p.getDouble('s_wsens') ?? 0.5).clamp(0.1, 1.0).toDouble();
    pattern = p.getBool('s_pattern') ?? true;
    shadows = p.getBool('s_shadows') ?? true;
    shine = p.getBool('s_shine') ?? true;
    effects = p.getBool('s_effects') ?? true;
    fps30 = p.getBool('s_fps30') ?? false;
  }

  void _save() {
    final p = _p;
    if (p == null) return;
    p.setBool('s_wheel', aimWheel);
    p.setDouble('s_wsens', wheelSens);
    p.setBool('s_pattern', pattern);
    p.setBool('s_shadows', shadows);
    p.setBool('s_shine', shine);
    p.setBool('s_effects', effects);
    p.setBool('s_fps30', fps30);
  }

  void update(
      {bool? aimWheel,
      double? wheelSens,
      bool? pattern,
      bool? shadows,
      bool? shine,
      bool? effects,
      bool? fps30}) {
    if (aimWheel != null) this.aimWheel = aimWheel;
    if (wheelSens != null) this.wheelSens = wheelSens;
    if (pattern != null) this.pattern = pattern;
    if (shadows != null) this.shadows = shadows;
    if (shine != null) this.shine = shine;
    if (effects != null) this.effects = effects;
    if (fps30 != null) this.fps30 = fps30;
    notifyListeners();
    _save();
  }

  void setQuality(int q) {
    pattern = q >= 1;
    shadows = q >= 1;
    shine = q >= 2;
    effects = q >= 2;
    notifyListeners();
    _save();
  }
}

// ======================================================================
// HADIAH HARIAN
// ======================================================================
class DailyStore extends ChangeNotifier {
  DailyStore._();
  static final DailyStore i = DailyStore._();
  static const List<int> rewards = [
    100000,
    150000,
    250000,
    400000,
    600000,
    1000000,
    2500000
  ];

  SharedPreferences? _p;
  int streak = 0, lastDay = 0, totalClaims = 0;

  static int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  Future<void> init() async {
    final p = _p = await SharedPreferences.getInstance();
    streak = p.getInt('d_streak') ?? 0;
    lastDay = p.getInt('d_last') ?? 0;
    totalClaims = p.getInt('d_total') ?? 0;
  }

  // streak yang masih berlaku hari ini (putus jika kemarin terlewat)
  int get _live {
    if (lastDay == 0) return 0;
    final now = DateTime.now();
    if (lastDay == dayKey(now)) return streak;
    final y = dayKey(DateTime(now.year, now.month, now.day - 1));
    return lastDay == y ? streak : 0;
  }

  bool get canClaim => dayKey(DateTime.now()) > lastDay;

  // jumlah hari yang sudah diambil pada siklus 7 hari yang sedang tampil
  int get doneInCycle {
    final s = _live;
    if (s == 0) return 0;
    return canClaim ? s % 7 : ((s - 1) % 7) + 1;
  }

  // hari ke-berapa (1..7) yang bisa diambil sekarang; 0 jika sudah diambil
  int get nextDay => canClaim ? (_live % 7) + 1 : 0;

  Future<int> claim() async {
    if (!canClaim) return 0;
    final amount = rewards[nextDay - 1];
    streak = _live + 1;
    lastDay = dayKey(DateTime.now());
    totalClaims++;
    notifyListeners();
    final p = _p;
    if (p != null) {
      await p.setInt('d_streak', streak);
      await p.setInt('d_last', lastDay);
      await p.setInt('d_total', totalClaims);
    }
    await Wallet.add(amount);
    return amount;
  }
}

// ======================================================================
// MISI (harian & utama)
// ======================================================================
class Mission {
  final String id, title, desc, key;
  final int target, reward;
  final bool daily;
  final String? border; // id border hadiah
  const Mission(this.id, this.title, this.desc, this.key, this.target,
      this.reward,
      {this.daily = false, this.border});
}

const List<Mission> kMissions = [
  Mission('d_play', 'Pemanasan', 'Main 3 pertandingan', 'play', 3, 100000,
      daily: true),
  Mission('d_win', 'Pemenang Hari Ini', 'Menang 2 pertandingan', 'win', 2,
      250000,
      daily: true),
  Mission('d_pot', 'Tembakan Jitu', 'Masukkan 20 bola', 'pot', 20, 150000,
      daily: true),
  Mission('m_win5', 'Langkah Pertama', 'Menang 5 pertandingan', 'win', 5,
      300000),
  Mission('m_win25', 'Pemain Handal', 'Menang 25 pertandingan', 'win', 25,
      1500000,
      border: 'bronze'),
  Mission('m_win100', 'Raja Meja', 'Menang 100 pertandingan', 'win', 100,
      10000000,
      border: 'champion'),
  Mission('m_pot100', 'Kolektor Bola', 'Masukkan 100 bola', 'pot', 100,
      500000),
  Mission('m_pot500', 'Mesin Pocket', 'Masukkan 500 bola', 'pot', 500,
      3000000,
      border: 'neon'),
  Mission('m_lvl5', 'Naik Kelas', 'Capai level 5', 'level', 5, 500000),
  Mission('m_lvl10', 'Veteran', 'Capai level 10', 'level', 10, 2000000,
      border: 'royal'),
  Mission('m_arena5', 'Keliling Dunia', 'Menang di 5 arena berbeda', 'arena',
      5, 2000000,
      border: 'globe'),
  Mission('m_vegas', 'Penjudi Ulung', 'Menang di arena Las Vegas', 'vegas', 1,
      5000000,
      border: 'vegas'),
  Mission('m_daily7', 'Rajin Login', 'Ambil hadiah harian 7 kali', 'daily', 7,
      1000000,
      border: 'streak'),
];

class MissionStore extends ChangeNotifier {
  MissionStore._();
  static final MissionStore i = MissionStore._();

  SharedPreferences? _p;
  final Map<String, int> _life = {}, _day = {};
  final Set<String> _won = {}, _claimed = {}, _dclaimed = {};
  int _dayKey = 0;

  Future<void> init() async {
    final p = _p = await SharedPreferences.getInstance();
    _readMap(p.getStringList('ms_life'), _life);
    _readMap(p.getStringList('ms_dayc'), _day);
    _won.addAll(p.getStringList('ms_won') ?? const <String>[]);
    _claimed.addAll(p.getStringList('ms_claimed') ?? const <String>[]);
    _dclaimed.addAll(p.getStringList('ms_dclaimed') ?? const <String>[]);
    _dayKey = p.getInt('ms_day') ?? 0;
    if (!p.containsKey('ms_life')) {
      // pemain lama: ambil hitungan dari statistik yang sudah ada
      _life['win'] = ProfileStore.i.wins;
      _life['play'] = ProfileStore.i.games;
    }
    _rollDay();
  }

  void _readMap(List<String>? l, Map<String, int> m) {
    for (final e in l ?? const <String>[]) {
      final k = e.indexOf('=');
      if (k > 0) m[e.substring(0, k)] = int.tryParse(e.substring(k + 1)) ?? 0;
    }
  }

  void _rollDay() {
    final t = DailyStore.dayKey(DateTime.now());
    if (t != _dayKey) {
      _dayKey = t;
      _day.clear();
      _dclaimed.clear();
      _save();
    }
  }

  void _save() {
    final p = _p;
    if (p == null) return;
    p.setStringList(
        'ms_life', _life.entries.map((e) => '${e.key}=${e.value}').toList());
    p.setStringList(
        'ms_dayc', _day.entries.map((e) => '${e.key}=${e.value}').toList());
    p.setStringList('ms_won', _won.toList());
    p.setStringList('ms_claimed', _claimed.toList());
    p.setStringList('ms_dclaimed', _dclaimed.toList());
    p.setInt('ms_day', _dayKey);
  }

  void add(String key, [int n = 1]) {
    if (n <= 0) return;
    _rollDay();
    _life[key] = (_life[key] ?? 0) + n;
    _day[key] = (_day[key] ?? 0) + n;
    _save();
    notifyListeners();
  }

  // dipanggil sekali setiap pertandingan selesai
  void onMatch(bool win, String venue) {
    if (win) {
      _won.add(venue);
      add('win');
    }
    add('play');
  }

  int progress(Mission m) {
    _rollDay();
    switch (m.key) {
      case 'level':
        return ProfileStore.i.level;
      case 'arena':
        return _won.length;
      case 'vegas':
        return _won.contains('Las Vegas') ? 1 : 0;
      case 'daily':
        return DailyStore.i.totalClaims;
    }
    return (m.daily ? _day : _life)[m.key] ?? 0;
  }

  bool done(Mission m) => progress(m) >= m.target;
  bool claimed(Mission m) => (m.daily ? _dclaimed : _claimed).contains(m.id);
  int get claimable => kMissions.where((m) => done(m) && !claimed(m)).length;

  Future<bool> claim(Mission m) async {
    if (!done(m) || claimed(m)) return false;
    (m.daily ? _dclaimed : _claimed).add(m.id);
    _save();
    notifyListeners();
    await Wallet.add(m.reward);
    final b = m.border;
    if (b != null) await ProfileStore.i.grantBorder(b);
    return true;
  }
}

// ======================================================================
// JEMBATAN BLOADER (hanya loopback 127.0.0.1, wajib token)
// ======================================================================
class Bridge {
  static const int port = 38417;
  static const String token = 'BLDR-7f3a91c2-VLRD-ONLY';
  static HttpServer? _s;

  static Future<void> start() async {
    if (_s != null) return;
    try {
      _s = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } catch (_) {
      return;
    }
    _s!.listen(_handle, onError: (_) {});
  }

  static Map<String, dynamic> _state() => {
        'app': 'villiard',
        'autoplay': Mod.i.autoplay,
        'autoBounce': Mod.i.autoBounce,
        'autoQueue': Mod.i.autoQueue,
        'longLine': Mod.i.longLine,
        'freezeOpp': Mod.i.freezeOpp,
        'active': Mod.i.active,
        'level': ProfileStore.i.level,
        'coins': Wallet.coins.value,
      };

  static Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      if (req.headers.value('x-bloader-token') != token) {
        res.statusCode = 403;
        await res.close();
        return;
      }
      Map<String, dynamic> out;
      final path = req.uri.path;
      // Semua aksi mod ditolak kalau Bloader belum aktif
      if ((path == '/set' || path == '/coins' || path == '/levelup') &&
          !Mod.i.active) {
        res.statusCode = 409;
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'error': 'not_active'}));
        await res.close();
        return;
      }
      switch (path) {
        case '/activate':
          Mod.i.ping();
          out = _state();
          break;
        case '/deactivate':
          Mod.i.deactivate();
          out = _state();
          break;
        case '/levelup':
          final lt = await utf8.decoder.bind(req).join();
          var n = 1;
          try {
            final lj = jsonDecode(lt);
            if (lj is Map && lj['levels'] is num) n = (lj['levels'] as num).toInt();
          } catch (_) {}
          await ProfileStore.i.addLevels(n.clamp(1, 50).toInt());
          out = _state();
          break;
        case '/hello':
        case '/state':
          out = _state();
          break;
        case '/set':
          final txt = await utf8.decoder.bind(req).join();
          final j = jsonDecode(txt);
          if (j is Map<String, dynamic>) {
            bool? b(String k) => j[k] is bool ? j[k] as bool : null;
            Mod.i.set(
              autoplay: b('autoplay'),
              autoBounce: b('autoBounce'),
              autoQueue: b('autoQueue'),
              longLine: b('longLine'),
              freezeOpp: b('freezeOpp'),
            );
          }
          out = _state();
          break;
        case '/coins':
          await Wallet.add(Mod.injectAmount);
          out = _state();
          break;
        default:
          res.statusCode = 404;
          await res.close();
          return;
      }
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode(out));
    } catch (_) {
      res.statusCode = 500;
    }
    await res.close();
  }
}

// ======================================================================
// MAIN
// ======================================================================
// Masalah saat startup (ditampilkan kecil di layar logo supaya bisa difoto)
final List<String> kStartupIssues = [];

// Tiap langkah awal diberi batas waktu dan tidak boleh menjatuhkan game:
// kalau satu langkah macet atau error, game tetap lanjut ke layar utama.
Future<void> _boot(String name, Future<void> Function() f,
    {int sec = 8}) async {
  try {
    await f().timeout(Duration(seconds: sec));
  } catch (e) {
    kStartupIssues.add('$name: ${e.toString().split('\n').first}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _boot('layar', () async {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }, sec: 3);
  await _boot('dompet', () async => await Wallet.init());
  await _boot('profil', () async => await ProfileStore.i.init());
  await _boot('mod', () async => await Mod.i.init());
  await _boot('setelan', () async => await GameSettings.i.init());
  await _boot('harian', () async => await DailyStore.i.init());
  await _boot('misi', () async => await MissionStore.i.init());
  await _boot('suara', () async => await Sfx.init(), sec: 5);
  await _boot('jembatan', () async => await Bridge.start(), sec: 3);
  _keepAwake(true); // layar tetap menyala selama game dibuka
  runApp(const VilliardApp());
}

// Layar tidak mati saat game ditinggal (autoplay / auto queue tetap jalan)
void _keepAwake(bool on) {
  try {
    final f = on ? WakelockPlus.enable() : WakelockPlus.disable();
    f.catchError((_) {});
  } catch (_) {}
}

class _KeepAwake extends StatefulWidget {
  final Widget child;
  const _KeepAwake({required this.child});
  @override
  State<_KeepAwake> createState() => _KeepAwakeState();
}

class _KeepAwakeState extends State<_KeepAwake> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _keepAwake(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // pasang ulang saat kembali ke game (sebagian HP melepasnya)
    if (state == AppLifecycleState.resumed) _keepAwake(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class VilliardApp extends StatelessWidget {
  const VilliardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Villiard',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF1E88FF),
      ),
      builder: (context, child) => _KeepAwake(child: child ?? const SizedBox()),
      home: const SplashScreen(),
    );
  }
}

// ======================================================================
// SPLASH
// ======================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
        Duration(milliseconds: kStartupIssues.isEmpty ? 1800 : 6000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LobbyScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 220),
            const SizedBox(height: 8),
            const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3)),
            if (kStartupIssues.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(kStartupIssues.take(3).join('\n'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFFFBBF24))),
              ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// WIDGET BERSAMA
// ======================================================================
// Gambar avatar bulat (aset). Dipakai di semua tempat avatar pemain.
class _AvatarPic extends StatelessWidget {
  final int index;
  final double size;
  const _AvatarPic({required this.index, required this.size});

  @override
  Widget build(BuildContext context) {
    final i = index % kAvatars.length;
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.asset(
      kAvatars[i],
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: px < 64 ? 64 : px,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Container(color: kAvatarColors[i]),
    );
  }
}

class _Avatar extends StatelessWidget {
  final int index;
  final double size;
  final bool selected;
  final String? frame; // id border avatar (opsional)
  const _Avatar(
      {required this.index,
      this.size = 40,
      this.selected = false,
      this.frame});

  @override
  Widget build(BuildContext context) {
    final i = index % kAvatars.length;
    final f = frame;
    if (f != null) {
      return _Framed(
        border: borderById(f),
        size: size,
        child: Container(
          color: kAvatarColors[i],
          child: _AvatarPic(index: i, size: size),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kAvatarColors[i],
        border: Border.all(
            color: selected ? Colors.white : Colors.white30,
            width: selected ? 3 : 1.5),
      ),
      child: _AvatarPic(index: i, size: size),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Wallet.coins,
      builder: (_, c, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c < kVenues.first.fee)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(
                onPressed: () => Wallet.add(500000),
                child: const Text('Bonus Rp 500.000'),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFACC15), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(rp(c),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFFFACC15))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pratinjau cue horizontal.
class _CuePainter extends CustomPainter {
  final CueSkin s;
  _CuePainter(this.s, [Listenable? repaint]) : super(repaint: repaint);
  @override
  void paint(Canvas c, Size size) {
    drawCue(c, s, Offset(size.width - 4, size.height / 2), const Offset(1, 0),
        length: max(10.0, size.width - 12),
        wTip: 2.2,
        wEnd: 5,
        shadow: false);
  }

  @override
  bool shouldRepaint(covariant _CuePainter old) => old.s != s;
}

// Pratinjau cue yang beranimasi (efek api / listrik / bintang).
class _CueView extends StatefulWidget {
  final CueSkin cue;
  const _CueView(this.cue);
  @override
  State<_CueView> createState() => _CueViewState();
}

class _CueViewState extends State<_CueView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3000));

  @override
  void initState() {
    super.initState();
    GameSettings.i.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(covariant _CueView old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final want = widget.cue.fx != CueFx.none && GameSettings.i.effects;
    if (want) {
      if (!_c.isAnimating) _c.repeat();
    } else if (_c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    GameSettings.i.removeListener(_sync);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
            size: Size.infinite, painter: _CuePainter(widget.cue, _c)),
      );
}

// Ikon cue miring untuk tombol menu.
class _CueIconPainter extends CustomPainter {
  final CueSkin s;
  _CueIconPainter(this.s);
  @override
  void paint(Canvas c, Size size) {
    drawCue(c, s, Offset(size.width - 3, 3), Offset(0.7071, -0.7071),
        length: size.width * 1.3,
        wTip: 1.4,
        wEnd: 3,
        shadow: false);
  }

  @override
  bool shouldRepaint(covariant _CueIconPainter old) => old.s != s;
}

// ======================================================================
// EDITOR PROFIL (username + avatar)
// ======================================================================
Future<void> showProfileEditor(BuildContext context, {bool first = false}) {
  final ctrl = TextEditingController(text: ProfileStore.i.name);
  var av = ProfileStore.i.avatar;
  String? err;
  return showDialog<void>(
    context: context,
    barrierDismissible: !first,
    builder: (dctx) => StatefulBuilder(
      builder: (dctx, setS) => PopScope(
        canPop: !first,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0E1A33),
          title: Text(first ? 'Selamat datang! 👋' : 'Ubah profil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  maxLength: 14,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Contoh: RajaBiliar',
                    errorText: err,
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Pilih avatar',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < kAvatars.length; i++)
                      GestureDetector(
                        onTap: () => setS(() => av = i),
                        child: _Avatar(index: i, size: 50, selected: av == i),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            if (!first)
              TextButton(
                  onPressed: () => Navigator.pop(dctx),
                  child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final e = validateName(ctrl.text);
                if (e != null) {
                  setS(() => err = e);
                  return;
                }
                await ProfileStore.i.setProfile(ctrl.text, av);
                if (dctx.mounted) Navigator.pop(dctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ======================================================================
// LOBI (gaya 8 Ball Pool) + ANIMASI
// ======================================================================
Route<T> _fadeSlide<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) {
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0.06, 0), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );

void _soon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 1200),
      content: Text('$what segera hadir'),
    ));
}

Future<void> _startVenue(BuildContext context, Venue v) async {
  if (Wallet.coins.value < v.fee) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1500),
        content: Text('Uang kurang. Arena ${v.name} butuh ${rp(v.fee)}'),
      ));
    return;
  }
  await Wallet.add(-v.fee);
  if (!context.mounted) return;
  Navigator.of(context).push(_fadeSlide<void>(GameScreen(venue: v)));
}

Venue get _osaka => kVenues.firstWhere((v) => v.name == 'Osaka');

const TextStyle _kBarLabel = TextStyle(
    fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFF3E3CC));

TextStyle _tileStyle(double size) => TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      height: 1.05,
      shadows: const [
        Shadow(color: Color(0x99000000), blurRadius: 3, offset: Offset(0, 2))
      ],
    );

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with TickerProviderStateMixin {
  // sinar & kilau (8 dtk), bola bergulir (26 dtk), kedip (1.8 dtk),
  // kilap tombol (3.4 dtk), animasi masuk (sekali).
  late final AnimationController _loop = AnimationController(
      vsync: this, duration: const Duration(seconds: 8))
    ..repeat();
  late final AnimationController _roll = AnimationController(
      vsync: this, duration: const Duration(seconds: 26))
    ..repeat();
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);
  late final AnimationController _shine = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3400))
    ..repeat();
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..forward();
  late final List<Animation<double>> _st = List.generate(8, (i) {
    final s = (i * 0.08).clamp(0.0, 0.6);
    final e = (s + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
        parent: _enter, curve: Interval(s, e, curve: Curves.easeOutBack));
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ProfileStore.i.isNew) {
        showProfileEditor(context, first: true).then((_) => _maybeDaily());
      } else {
        _maybeDaily();
      }
    });
  }

  // hadiah harian muncul otomatis sekali tiap aplikasi dibuka (jika belum diambil)
  static bool _dailyAsked = false;
  void _maybeDaily() {
    if (!mounted || _dailyAsked || !DailyStore.i.canClaim) return;
    _dailyAsked = true;
    _open(const DailyRewardScreen());
  }

  @override
  void dispose() {
    _loop.dispose();
    _roll.dispose();
    _pulse.dispose();
    _shine.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _open(Widget w) => Navigator.of(context).push(_fadeSlide<void>(w));

  void _special() {
    Venue? best;
    for (final v in kVenues) {
      if (Wallet.coins.value >= v.fee) best = v;
    }
    if (best == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text('Uang belum cukup untuk arena mana pun')));
      return;
    }
    _startVenue(context, best);
  }

  Widget _stagger(int i, Widget child, {Offset from = const Offset(0, 0.5)}) {
    final a = _st[i];
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (_, c) {
        final v = a.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: FractionalTranslation(
              translation: Offset(from.dx * (1 - v), from.dy * (1 - v)),
              child: c),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB45309),
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, __) =>
                    CustomPaint(painter: _LobbyBgPainter(_loop.value)),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _roll,
                builder: (_, __) =>
                    CustomPaint(painter: _LobbyTablePainter(_roll.value)),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _stagger(0, _topBar(), from: const Offset(0, -1)),
                Expanded(child: Center(child: _logo())),
                SizedBox(height: 104, child: _menuRow()),
                const SizedBox(height: 8),
                SizedBox(height: 58, child: _bottomRow()),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- logo ----------------
  Widget _logo() {
    return LayoutBuilder(builder: (ctx, box) {
      final h = box.maxHeight.clamp(40.0, 150.0);
      return AnimatedBuilder(
        animation: Listenable.merge([_pulse, _loop]),
        builder: (_, __) {
          final p = Curves.easeInOut.transform(_pulse.value);
          final bob = sin(_loop.value * 2 * pi) * 3;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: h * 2.8,
                height: h * 1.15,
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [
                    Colors.white.withAlpha((40 + 70 * p).round()),
                    Colors.transparent
                  ]),
                ),
              ),
              Transform.translate(
                offset: Offset(0, bob),
                child: Transform.scale(
                  scale: 1 + 0.035 * p,
                  child: Image.asset('assets/logo.png',
                      height: h * 0.92, fit: BoxFit.contain),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  // ---------------- bar atas ----------------
  Widget _topBar() {
    Widget divider() => Container(
        width: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.black38);
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B3A12), Color(0xFF2E1604)]),
        border: Border(bottom: BorderSide(color: Color(0xFFFACC15), width: 1.5)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: AnimatedBuilder(
        animation: ProfileStore.i,
        builder: (_, __) {
          final p = ProfileStore.i;
          return Row(
            children: [
              _barTile(
                  const Icon(Icons.groups_rounded,
                      color: Color(0xFFE5E7EB), size: 24),
                  'Clubs',
                  () => _soon(context, 'Clubs')),
              divider(),
              Expanded(flex: 5, child: _profileCell(p)),
              divider(),
              Expanded(flex: 4, child: _cuesCell(p)),
              divider(),
              _barTile(const Text('🪙', style: TextStyle(fontSize: 22)),
                  'Free Rewards', () => _open(const DailyRewardScreen())),
              divider(),
              _barTile(
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFFACC15), size: 24),
                  'Leaderboards',
                  () => _open(const ProfileScreen())),
              divider(),
              _barTile(
                  const Icon(Icons.shopping_basket_rounded,
                      color: Color(0xFF4ADE80), size: 24),
                  'Shop',
                  () => _open(const CollectionScreen(initialTab: 0))),
              divider(),
              Expanded(flex: 5, child: _coinCell()),
            ],
          );
        },
      ),
    );
  }

  Widget _barTile(Widget icon, String label, VoidCallback onTap) {
    return Expanded(
      flex: 3,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 24, child: FittedBox(child: icon)),
            const SizedBox(height: 2),
            FittedBox(
                fit: BoxFit.scaleDown, child: Text(label, style: _kBarLabel)),
          ],
        ),
      ),
    );
  }

  Widget _profileCell(ProfileStore p) {
    final ai = p.avatar % kAvatars.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(const ProfileScreen()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            _Framed(
              border: p.border,
              size: 30,
              child: Container(
                color: kAvatarColors[ai],
                child: _AvatarPic(index: ai, size: 30),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _LevelStar(level: p.level),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(p.isNew ? 'Pemain' : p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  _XpBar(
                    value: p.levelProgress,
                    label:
                        '${p.xp % ProfileStore.xpPerLevel}/${ProfileStore.xpPerLevel}',
                    color: const Color(0xFFFACC15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cuesCell(ProfileStore p) {
    final total = kCues.length;
    final own = p.owned.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(const CollectionScreen(initialTab: 0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                children: [
                  Center(
                    child: CustomPaint(
                        size: const Size(28, 28),
                        painter: _CueIconPainter(p.cue)),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text('$own',
                          style: const TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cues',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  _XpBar(
                    value: total == 0 ? 0 : own / total,
                    label: '$own/$total',
                    color: const Color(0xFF22C55E),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coinCell() {
    return Row(
      children: [
        const Expanded(child: _CoinCell()),
        _PressScale(
          scale: 0.9,
          onTap: () {
            if (Wallet.coins.value < kVenues.first.fee) {
              Sfx.coins();
              Wallet.add(500000);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                    duration: Duration(milliseconds: 1200),
                    content: Text('Bonus Rp 500.000 masuk')));
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(
                    duration: Duration(milliseconds: 1200),
                    content: Text('Uang kamu masih cukup')));
            }
          },
          child: Container(
            width: 30,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF22C55E), Color(0xFF15803D)]),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  // ---------------- tombol utama ----------------
  Widget _playContent(String a, String b, List<int> balls) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 0.38,
          child: CustomPaint(painter: _BallDecorPainter(balls)),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(a, style: _tileStyle(26)),
                  Text(b, style: _tileStyle(22)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _osakaContent() {
    final v = _osaka;
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PetalFall(),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ARENA BARU',
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFDE68A))),
                  Text('OSAKA', style: _tileStyle(28)),
                  Text('🇯🇵 ${rp(v.fee)}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 5,
          left: 5,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.12).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('NEW',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: _stagger(
              1,
              _BigButton(
                colors: const [Color(0xFFEC4899), Color(0xFF4A0E3A)],
                border: const Color(0xFFFACC15),
                glow: _pulse,
                glowColor: const Color(0xFFF472B6),
                shine: _shine,
                phase: 0.0,
                onTap: () => _startVenue(context, _osaka),
                child: _osakaContent(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: _stagger(
              2,
              _BigButton(
                colors: const [Color(0xFF86E02B), Color(0xFF2E8B0F)],
                border: const Color(0xFF1B5E0A),
                shine: _shine,
                phase: 0.15,
                onTap: () => _open(const ArenaScreen()),
                child: _playContent('Play', '1 on 1', const [8, 15]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: _stagger(
              3,
              _BigButton(
                colors: const [Color(0xFF3B94EE), Color(0xFF123F9E)],
                border: const Color(0xFF0B2A6E),
                shine: _shine,
                phase: 0.3,
                onTap: _special,
                child: _playContent('Play', 'Special', const [8]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: _stagger(
              4,
              _BigButton(
                colors: const [Color(0xFF34D3C8), Color(0xFF0E7C86)],
                border: const Color(0xFF0A5560),
                shine: _shine,
                phase: 0.45,
                onTap: () => _open(const MinigamesScreen()),
                child: _playContent('Play', 'Minigames', const [3, 11]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: _stagger(
              5,
              _BigButton(
                colors: const [Color(0xFFFFBA4A), Color(0xFFE67700)],
                border: const Color(0xFF92400E),
                shine: _shine,
                phase: 0.6,
                onTap: () => _soon(context, 'Play With Friends'),
                child: _playContent('Play', 'With Friends', const [1, 2]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- baris bawah ----------------
  Widget _roundBtn(Widget icon, List<Color> colors, VoidCallback onTap) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors),
          border: Border.all(color: Colors.white30, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }

  Widget _badge(Widget child, Listenable l, int Function() count) {
    return AnimatedBuilder(
      animation: l,
      child: child,
      builder: (_, c) {
        final n = count();
        return Stack(
          clipBehavior: Clip.none,
          children: [
            c!,
            if (n > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text('$n',
                      style: const TextStyle(
                          fontSize: 10.5, fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _bottomRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _stagger(
            5,
            _roundBtn(
              const Icon(Icons.settings_rounded,
                  color: Colors.white, size: 28),
              const [Color(0xFF6B7280), Color(0xFF374151)],
              () => _open(const SettingsScreen()),
            ),
            from: const Offset(-1, 0),
          ),
          const SizedBox(width: 8),
          _stagger(
            6,
            _badge(
              _roundBtn(
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, c) => Transform.rotate(
                      angle: (_pulse.value - 0.5) * 0.28, child: c),
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: Colors.white, size: 28),
                ),
                const [Color(0xFFFFC53D), Color(0xFFEA8A00)],
                () => _open(const DailyRewardScreen()),
              ),
              DailyStore.i,
              () => DailyStore.i.canClaim ? 1 : 0,
            ),
            from: const Offset(-1, 0),
          ),
          const SizedBox(width: 8),
          _stagger(
            7,
            _badge(
              _roundBtn(
                const Icon(Icons.flag_rounded, color: Colors.white, size: 28),
                const [Color(0xFF38BDF8), Color(0xFF0369A1)],
                () => _open(const MissionsScreen()),
              ),
              Listenable.merge([MissionStore.i, ProfileStore.i]),
              () => MissionStore.i.claimable,
            ),
            from: const Offset(-1, 0),
          ),
          const SizedBox(width: 8),
          _stagger(
            7,
            _roundBtn(
              const Icon(Icons.people_alt_rounded,
                  color: Colors.white, size: 28),
              const [Color(0xFFFFC53D), Color(0xFFEA8A00)],
              () => _soon(context, 'Teman'),
            ),
            from: const Offset(-1, 0),
          ),
          const Spacer(),
          _stagger(7, _cueBanner(), from: const Offset(1, 0)),
        ],
      ),
    );
  }

  Widget _cueBanner() {
    return AnimatedBuilder(
      animation: ProfileStore.i,
      builder: (_, __) {
        final p = ProfileStore.i;
        return _PressScale(
          onTap: () => _open(const CollectionScreen(initialTab: 0)),
          child: Container(
            width: 210,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B3C6E), Color(0xFF06223F)]),
              border: Border.all(color: const Color(0xFF67E8F9), width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        CustomPaint(
                            size: const Size(40, 40),
                            painter: _CueIconPainter(p.cue)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Koleksi Cue',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFA5F3FC))),
                              Text(p.cue.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Gloss(shine: _shine, phase: 0.8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// WIDGET LOBI
// ----------------------------------------------------------------------
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  const _PressScale(
      {required this.child, required this.onTap, this.scale = 0.93});
  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _Gloss extends StatelessWidget {
  final Animation<double> shine;
  final double phase;
  const _Gloss({required this.shine, required this.phase});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: shine,
          builder: (_, __) {
            final t = (shine.value + phase) % 1.0;
            return Align(
              alignment: Alignment(-2.0 + 4.0 * t, 0),
              child: Transform(
                transform: Matrix4.skewX(-0.35),
                child: Container(
                  width: 26,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Color(0x00FFFFFF),
                      Color(0x55FFFFFF),
                      Color(0x00FFFFFF)
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final List<Color> colors;
  final Color border;
  final VoidCallback onTap;
  final Animation<double> shine;
  final double phase;
  final Widget child;
  final Animation<double>? glow;
  final Color glowColor;
  const _BigButton({
    required this.colors,
    required this.border,
    required this.onTap,
    required this.shine,
    required this.phase,
    required this.child,
    this.glow,
    this.glowColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: glow ?? const AlwaysStoppedAnimation<double>(0.0),
        builder: (_, __) {
          final g = glow == null ? 0.0 : glow!.value;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors),
              border: Border.all(color: border, width: 2.5),
              boxShadow: [
                const BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 4)),
                if (glow != null)
                  BoxShadow(
                      color: glowColor.withAlpha((90 + 100 * g).round()),
                      blurRadius: 8 + 14 * g),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  _Gloss(shine: shine, phase: phase),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelStar extends StatelessWidget {
  final int level;
  const _LevelStar({required this.level});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFA855F7), size: 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$level',
                style:
                    const TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  const _XpBar({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black54),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                    widthFactor: v, child: Container(color: color)),
              ),
            ),
            Center(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// Saldo koin: koin berputar, angka berubah warna, dan label +/- melayang.
class _CoinCell extends StatefulWidget {
  const _CoinCell();
  @override
  State<_CoinCell> createState() => _CoinCellState();
}

class _CoinCellState extends State<_CoinCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  int _prev = Wallet.coins.value;
  int _delta = 0;

  @override
  void initState() {
    super.initState();
    Wallet.coins.addListener(_on);
  }

  @override
  void dispose() {
    Wallet.coins.removeListener(_on);
    _c.dispose();
    super.dispose();
  }

  void _on() {
    final v = Wallet.coins.value;
    final d = v - _prev;
    _prev = v;
    if (d == 0 || !mounted) return;
    _delta = d;
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final live = t > 0 && t < 1;
        final tint = !live
            ? Colors.white
            : (_delta > 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171));
        final flip = Curves.easeOut.transform(t) * 2 * pi;
        final grow = 1.0 + 0.35 * sin(pi * t);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(flip)..scale(grow, grow),
                    child: const Text('🪙', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: Wallet.coins,
                      builder: (_, c, __) => TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: c.toDouble()),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(rp(v.round()),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: tint)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (live)
              Positioned(
                left: 30,
                top: 28 + 20 * t,
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Text(
                      '${_delta > 0 ? '+' : '-'}${rp(_delta.abs())}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: tint,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 3)
                          ])),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Hujan koin + teks hadiah saat menang.
class _CoinShower extends StatefulWidget {
  final int amount;
  const _CoinShower({required this.amount});
  @override
  State<_CoinShower> createState() => _CoinShowerState();
}

class _CoinShowerState extends State<_CoinShower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1900))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          final pop = Curves.elasticOut.transform((t * 3).clamp(0.0, 1.0));
          final fade = (1 - (t - 0.78) / 0.22).clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned.fill(
                  child: CustomPaint(painter: _CoinsPainter(t))),
              Center(
                child: Opacity(
                  opacity: fade,
                  child: Transform.scale(
                    scale: pop,
                    child: Text('+${rp(widget.amount)}',
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFACC15),
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 8),
                              Shadow(
                                  color: Color(0xFFB45309),
                                  offset: Offset(0, 3))
                            ])),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CoinsPainter extends CustomPainter {
  final double t; // 0..1
  _CoinsPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final rnd = Random(11);
    final fill = Paint()..color = const Color(0xFFFACC15);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFB45309);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFFDE68A);
    for (var i = 0; i < 32; i++) {
      final x = rnd.nextDouble() * s.width;
      final delay = rnd.nextDouble() * 0.45;
      final r = 9.0 + rnd.nextDouble() * 9.0;
      final spin = 2 + rnd.nextDouble() * 3;
      final tt = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (tt <= 0) continue;
      final y = -20 + (s.height + 40) * tt * tt;
      final sx = cos(tt * spin * 2 * pi).abs().clamp(0.18, 1.0);
      c.save();
      c.translate(x, y);
      c.scale(sx, 1);
      c.drawCircle(Offset.zero, r, fill);
      rim.strokeWidth = r * 0.18;
      c.drawCircle(Offset.zero, r, rim);
      inner.strokeWidth = r * 0.1;
      c.drawCircle(Offset.zero, r * 0.62, inner);
      c.drawRect(
          Rect.fromCenter(center: Offset.zero, width: r * 0.22, height: r * 0.7),
          Paint()..color = const Color(0xFFB45309));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CoinsPainter old) => old.t != t;
}

class _DefeatFx extends StatefulWidget {
  final int amount;
  const _DefeatFx({required this.amount});
  @override
  State<_DefeatFx> createState() => _DefeatFxState();
}

class _DefeatFxState extends State<_DefeatFx>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          final dim = (Curves.easeOut.transform((t * 4).clamp(0.0, 1.0)) *
                  (1 - ((t - 0.82) / 0.18).clamp(0.0, 1.0)))
              .clamp(0.0, 1.0);
          final drop = Curves.easeOutBack.transform((t * 2.6).clamp(0.0, 1.0));
          final shake = sin(t * 60) * 7 * (1 - (t * 3.5).clamp(0.0, 1.0));
          final fade = (1 - ((t - 0.8) / 0.2)).clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.0,
                      colors: [
                        Colors.black.withAlpha((70 * dim).round()),
                        const Color(0xFF3B0A12).withAlpha((190 * dim).round()),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _LostCoinsPainter(t))),
              Center(
                child: Opacity(
                  opacity: fade,
                  child: Transform.translate(
                    offset: Offset(shake, -50 * (1 - drop)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('KALAH',
                            style: TextStyle(
                                fontSize: 46,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFF87171),
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 10),
                                  Shadow(
                                      color: Color(0xFF7F1D1D),
                                      offset: Offset(0, 4))
                                ])),
                        const SizedBox(height: 4),
                        Text('-${rp(widget.amount)}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white70,
                                shadows: [
                                  Shadow(color: Colors.black87, blurRadius: 6)
                                ])),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Koin abu-abu yang melayang jatuh pelan (taruhan hangus)
class _LostCoinsPainter extends CustomPainter {
  final double t;
  _LostCoinsPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final rnd = Random(23);
    for (var i = 0; i < 16; i++) {
      final x0 = rnd.nextDouble() * s.width;
      final delay = rnd.nextDouble() * 0.35;
      final r = 8.0 + rnd.nextDouble() * 7.0;
      final sway = 8 + rnd.nextDouble() * 14;
      final ph = rnd.nextDouble() * 6.28;
      final tt = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (tt <= 0) continue;
      final x = x0 + sin(tt * 5 + ph) * sway;
      final y = -20 + (s.height + 40) * tt;
      final a = (170 * (1 - tt * 0.6)).round();
      final sx = cos(tt * 3 * pi + ph).abs().clamp(0.2, 1.0);
      c.save();
      c.translate(x, y);
      c.scale(sx, 1);
      c.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFF94A3B8).withAlpha(a));
      c.drawCircle(
          Offset.zero,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.16
            ..color = const Color(0xFF475569).withAlpha(a));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LostCoinsPainter old) => old.t != t;
}

// ----------------------------------------------------------------------
// PAINTER LOBI
// ----------------------------------------------------------------------
final Map<String, TextPainter> _ballNumCache = {};
TextPainter _ballNum(int n, double r) =>
    _ballNumCache.putIfAbsent('$n:${r.round()}', () {
      final t = TextPainter(
        text: TextSpan(
            text: '$n',
            style: TextStyle(
                color: Colors.black,
                fontSize: r * 0.62,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      );
      t.layout();
      return t;
    });

// Gambar bola bernomor (0 = putih, 1-8 solid, 9-15 strip).
void _drawBall(Canvas c, Offset o, double r, int n) {
  final col = kBallColors[n % 16];
  final rect = Rect.fromCircle(center: o, radius: r);
  c.drawCircle(
      o + Offset(r * 0.25, r * 0.4),
      r,
      Paint()
        ..color = Colors.black38
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3));
  c.save();
  c.clipPath(Path()..addOval(rect));
  c.drawRect(rect, Paint()..color = n > 8 ? Colors.white : col);
  if (n > 8) {
    c.drawRect(
        Rect.fromLTRB(o.dx - r, o.dy - r * 0.52, o.dx + r, o.dy + r * 0.52),
        Paint()..color = col);
  }
  if (n != 0) {
    c.drawCircle(o, r * 0.45, Paint()..color = Colors.white);
    final tp = _ballNum(n, r);
    tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
  }
  c.drawCircle(
      o,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          radius: 1.0,
          colors: [Color(0x66FFFFFF), Color(0x00FFFFFF), Color(0x66000000)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect));
  c.restore();
}

class _BallDecorPainter extends CustomPainter {
  final List<int> nums;
  _BallDecorPainter(this.nums);
  @override
  void paint(Canvas c, Size s) {
    final r = s.height * 0.3;
    for (var i = 0; i < nums.length; i++) {
      final f = nums.length == 1 ? 0.5 : i / (nums.length - 1);
      final o = Offset(s.width * (0.28 + 0.44 * f),
          s.height * 0.5 + (i.isEven ? -1 : 1) * s.height * 0.1);
      _drawBall(c, o, r, nums[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _BallDecorPainter old) => old.nums != nums;
}

// Latar oranye: sinar berputar pelan + kilau bintang berkedip.
class _LobbyBgPainter extends CustomPainter {
  final double t; // 0..1 (seamless)
  _LobbyBgPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final rect = Offset.zero & s;
    c.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFB02E), Color(0xFFF57C00), Color(0xFFC2410C)],
          ).createShader(rect));

    final center = Offset(s.width / 2, s.height * 0.34);
    final big = s.longestSide * 1.2;
    const n = 14;
    const step = 2 * pi / n;
    final base = t * step;
    final ray = Paint()..color = Colors.white.withAlpha(34);
    for (var i = 0; i < n; i++) {
      final a0 = base + i * step;
      final a1 = a0 + step / 2;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + big * cos(a0), center.dy + big * sin(a0))
        ..lineTo(center.dx + big * cos(a1), center.dy + big * sin(a1))
        ..close();
      c.drawPath(path, ray);
    }

    final glowR = s.height * 0.55;
    c.drawCircle(
        center,
        glowR,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withAlpha(90),
            Colors.white.withAlpha(0)
          ]).createShader(Rect.fromCircle(center: center, radius: glowR)));

    final rnd = Random(7);
    for (var i = 0; i < 16; i++) {
      final x = rnd.nextDouble() * s.width;
      final y = rnd.nextDouble() * s.height * 0.6;
      final ph = rnd.nextDouble();
      final k = 0.5 + 0.5 * sin((t * 2 + ph) * 2 * pi);
      _sparkle(c, Offset(x, y), 2 + 5 * k,
          Paint()..color = Colors.white.withAlpha((60 + 150 * k).round()));
    }
  }

  @override
  bool shouldRepaint(covariant _LobbyBgPainter old) => old.t != t;
}

// Meja biru di bagian bawah dengan bola-bola yang bergulir pelan.
class _LobbyTablePainter extends CustomPainter {
  final double t; // 0..1 (seamless)
  _LobbyTablePainter(this.t);

  static const List<int> _nums = [3, 14, 9, 1, 2, 6, 11];
  static const List<double> _lane = [0.12, 0.62, 0.30, 0.78, 0.45, 0.20, 0.88];

  @override
  void paint(Canvas c, Size s) {
    final top = s.height * 0.68;
    final rail = Rect.fromLTWH(0, top - 14, s.width, 16);
    c.drawRect(
        rail,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8A4B14), Color(0xFF4A2508)],
          ).createShader(rail));
    final felt = Rect.fromLTWH(0, top, s.width, s.height - top);
    c.drawRect(
        felt,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B9AE0), Color(0xFF0B5CA5), Color(0xFF083D75)],
          ).createShader(felt));

    final order = List<int>.generate(_nums.length, (i) => i)
      ..sort((a, b) => _lane[a].compareTo(_lane[b]));
    for (final i in order) {
      final lane = _lane[i];
      final r = s.height * (0.05 + 0.04 * lane);
      final k = 1 + (i % 2);
      var f = (t * k + i / _nums.length) % 1.0;
      if (i.isOdd) f = 1 - f;
      final x = f * (s.width + 4 * r) - 2 * r;
      final y = top + (s.height - top) * (0.22 + 0.6 * lane) +
          sin((t * 8 + i / _nums.length) * 2 * pi) * 1.5;
      _drawBall(c, Offset(x, y), r, _nums[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _LobbyTablePainter old) => old.t != t;
}

// ----------------------------------------------------------------------
// KELOPAK SAKURA (animasi arena Osaka)
// ----------------------------------------------------------------------
class _PetalFall extends StatefulWidget {
  const _PetalFall();
  @override
  State<_PetalFall> createState() => _PetalFallState();
}

class _PetalFallState extends State<_PetalFall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 9))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
              size: Size.infinite, painter: _PetalsPainter(_c.value)),
        ),
      ),
    );
  }
}

class _PetalsPainter extends CustomPainter {
  final double t; // 0..1 (seamless)
  _PetalsPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    if (s.isEmpty || !s.isFinite) return;
    final rnd = Random(3);
    for (var i = 0; i < 16; i++) {
      final x0 = rnd.nextDouble() * s.width;
      final ph = rnd.nextDouble();
      final sz = 3.0 + rnd.nextDouble() * 3.0;
      final sway = 6.0 + rnd.nextDouble() * 10.0;
      final spin = 1 + rnd.nextInt(3);
      final y = ((t + ph) % 1.0) * (s.height + 20) - 10;
      final x = x0 + sin((t * 2 + ph) * 2 * pi) * sway;
      final ang = (t * spin + ph) * 2 * pi;
      c.save();
      c.translate(x, y);
      c.rotate(ang);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: sz * 1.7, height: sz),
          Paint()..color = const Color(0xFFFBCFE8).withAlpha(215));
      c.drawOval(
          Rect.fromCenter(
              center: Offset(sz * 0.2, 0), width: sz * 0.8, height: sz * 0.45),
          Paint()..color = const Color(0xFFF472B6).withAlpha(150));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalsPainter old) => old.t != t;
}

class _PetalBox extends StatelessWidget {
  final bool show;
  final Widget child;
  const _PetalBox({required this.show, required this.child});
  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const _PetalFall(),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// LAYAR PILIH ARENA (Play 1 on 1)
// ======================================================================
class ArenaScreen extends StatelessWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF050B1A), Color(0xFF0A1F44)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    const Expanded(
                      child: Text('PILIH ARENA',
                          style: TextStyle(
                              letterSpacing: 3,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70)),
                    ),
                    const _CoinPill(),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: Wallet.coins,
                  builder: (_, coins, __) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    itemCount: kVenues.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (ctx, i) {
                      final v = kVenues[i];
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 380 + i * 110),
                        curve: Curves.easeOutCubic,
                        builder: (_, a, child) => Opacity(
                          opacity: a,
                          child: Transform.translate(
                              offset: Offset(80 * (1 - a), 0), child: child),
                        ),
                        child: _VenueCard(
                          venue: v,
                          enabled: coins >= v.fee,
                          onTap: () => _startVenue(ctx, v),
                        ),
                      );
                    },
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

class _VenueCard extends StatelessWidget {
  final Venue venue;
  final bool enabled;
  final VoidCallback onTap;
  const _VenueCard(
      {required this.venue, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = venue;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(v.felt, Colors.white, 0.1)!,
                Color.lerp(v.felt, Colors.black, 0.6)!
              ]),
          border: Border.all(color: v.accent, width: 2),
          boxShadow: [BoxShadow(color: v.accent.withAlpha(90), blurRadius: 14)],
        ),
        child: _PetalBox(
          show: v.skin.pattern == 6,
          child: Column(
            children: [
              Row(
                children: [
                  Text(v.flag, style: const TextStyle(fontSize: 26)),
                  const Spacer(),
                  const Text('vs Bot acak',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white70)),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(v.name.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CustomPaint(
                      size: Size.infinite, painter: _MiniTablePainter(v)),
                ),
              ),
              Text(v.skin.title,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: v.accent)),
              Text('Taruhan ${rp(v.fee)}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
              Text('Hadiah ${rp(v.fee * 2)}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: v.accent)),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: enabled ? onTap : null,
                  child: Text(enabled ? 'MAIN' : 'Uang kurang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// LAYAR PROFIL
// ======================================================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _stat(String label, String value, [Color? color]) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1A33),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color ?? Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07122A),
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFF050B1A),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: _CoinPill()),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: ProfileStore.i,
          builder: (ctx, _) {
            final p = ProfileStore.i;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _Panel(
                      child: Column(
                        children: [
                          _Avatar(index: p.avatar, size: 84, frame: p.borderId),
                          const SizedBox(height: 10),
                          Text(p.isNew ? 'Pemain' : p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('Level ${p.level}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFACC15))),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: p.levelProgress,
                              minHeight: 8,
                              backgroundColor: Colors.white12,
                              color: const Color(0xFFFACC15),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              '${p.xp % ProfileStore.xpPerLevel}/${ProfileStore.xpPerLevel} XP',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white60)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => showProfileEditor(ctx),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Ubah profil'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(ctx).push(
                                    MaterialPageRoute(
                                        builder: (_) => const CollectionScreen(
                                            initialTab: 2))),
                                icon: const Icon(Icons.crop_square_rounded,
                                    size: 16),
                                label: const Text('Border'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _stat('Menang', '${p.wins}',
                                const Color(0xFF4ADE80)),
                            const SizedBox(width: 8),
                            _stat('Kalah', '${p.losses}',
                                const Color(0xFFF87171)),
                            const SizedBox(width: 8),
                            _stat('Main', '${p.games}'),
                            const SizedBox(width: 8),
                            _stat('Win rate', '${p.winRate}%',
                                const Color(0xFFFACC15)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Panel(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cue dipakai',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white60)),
                                    Text(p.cue.name,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 30,
                                      child: _CueView(p.cue),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.tonal(
                                onPressed: () => Navigator.of(ctx).push(
                                    MaterialPageRoute(
                                        builder: (_) => const CollectionScreen(
                                            initialTab: 0))),
                                child: const Text('Ganti'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ======================================================================
// KOLEKSI: CUE & MEJA
// ======================================================================
class CollectionScreen extends StatelessWidget {
  final int initialTab;
  const CollectionScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: const Color(0xFF07122A),
        appBar: AppBar(
          title: const Text('Koleksi'),
          backgroundColor: const Color(0xFF050B1A),
          actions: const [
            Padding(padding: EdgeInsets.only(right: 12), child: _CoinPill()),
          ],
          bottom: const TabBar(
              tabs: [Tab(text: 'Cue'), Tab(text: 'Meja'), Tab(text: 'Border')]),
        ),
        body: const SafeArea(
          child: TabBarView(children: [_CueTab(), _TableTab(), _BorderTab()]),
        ),
      ),
    );
  }
}

class _CueTab extends StatelessWidget {
  const _CueTab();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ProfileStore.i,
      builder: (_, __) => ValueListenableBuilder<int>(
        valueListenable: Wallet.coins,
        builder: (ctx, coins, __) {
          final p = ProfileStore.i;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: kCues.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = kCues[i];
              final owned = p.owned.contains(c.id);
              final equipped = p.cueId == c.id;
              final locked = !owned && p.level < c.level;
              final Widget btn;
              if (equipped) {
                btn = FilledButton.tonal(
                    onPressed: null, child: const Text('Dipakai'));
              } else if (owned) {
                btn = FilledButton(
                    onPressed: () => p.equip(c.id), child: const Text('Pakai'));
              } else if (locked) {
                btn = FilledButton(
                    onPressed: null, child: Text('Level ${c.level}'));
              } else {
                btn = FilledButton(
                  onPressed: coins >= c.price ? () => p.buy(c) : null,
                  child: Text(rp(c.price)),
                );
              }
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1A33),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: equipped ? const Color(0xFFFACC15) : Colors.white12,
                      width: equipped ? 2 : 1),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 200,
                      height: 34,
                      child: _CueView(c),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800)),
                          Text(
                              locked
                                  ? 'Terbuka di Level ${c.level}'
                                  : c.desc,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white60)),
                          const SizedBox(height: 4),
                          _CueStats(c),
                        ],
                      ),
                    ),
                    btn,
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CueStats extends StatelessWidget {
  final CueSkin c;
  const _CueStats(this.c);

  Widget _bar(String label, double v, Color col) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9.5, color: Colors.white60)),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: v.clamp(0.05, 1.0),
                  minHeight: 5,
                  backgroundColor: Colors.white12,
                  color: col,
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _bar('Power +${((c.power - 1) * 100).round()}%',
            (c.power - 0.9) / 0.7, const Color(0xFFF97316)),
        _bar('Akurasi ${(c.acc * 100).round()}%', c.acc,
            const Color(0xFF22C55E)),
        _bar('Garis bidik x${c.aim.toStringAsFixed(1)}', (c.aim - 0.8) / 1.7,
            const Color(0xFF38BDF8)),
      ],
    );
  }
}

class _TableTab extends StatelessWidget {
  const _TableTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: kVenues.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
                'Skin meja otomatis menyesuaikan arena tempat kamu bermain.',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          );
        }
        final v = kVenues[i - 1];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1A33),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: v.accent.withAlpha(140)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 170,
                height: 94,
                child: CustomPaint(painter: _MiniTablePainter(v)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.skin.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('Arena ${v.name} ${v.flag}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: v.accent)),
                    Text('Motif kain: ${kPatternNames[v.skin.pattern]}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white60)),
                    Text('Taruhan ${rp(v.fee)}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white60)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================================================================
// ENGINE GAME
// ======================================================================
enum Phase { aiming, moving, placing, over }

class Ball {
  final int id;
  Offset p;
  Offset v = Offset.zero;
  bool pocketed = false;
  Ball(this.id, this.p);
  bool get stripe => id >= 9;

  // Orientasi bola (matriks rotasi 3x3, baris demi baris) supaya nomor &
  // garis ikut berputar saat bola menggelinding. x kanan, y atas, z ke penonton.
  List<double> rot = [1, 0, 0, 0, 1, 0, 0, 0, 1];

  // Menggelinding sejauh [d] (piksel layar) tanpa selip.
  void roll(Offset d) {
    final dist = d.distance;
    if (dist < 1e-6) return;
    final ang = dist / kR;
    // menggelinding tanpa selip: sumbu putar (y ke atas) = (-vy_fisik, vx, 0)
    final ax = d.dy / dist, ay = d.dx / dist;
    final c = cos(ang), sn = sin(ang), t = 1 - c;
    // Rodrigues untuk sumbu (ax, ay, 0)
    final r = [
      c + ax * ax * t, ax * ay * t, ay * sn, //
      ax * ay * t, c + ay * ay * t, -ax * sn,
      -ay * sn, ax * sn, c,
    ];
    final m = rot;
    final o = List<double>.filled(9, 0);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        o[i * 3 + j] = r[i * 3] * m[j] +
            r[i * 3 + 1] * m[3 + j] +
            r[i * 3 + 2] * m[6 + j];
      }
    }
    // jaga agar tetap ortonormal (hindari drift numerik): Gram-Schmidt
    var l = sqrt(o[0] * o[0] + o[1] * o[1] + o[2] * o[2]);
    o[0] /= l;
    o[1] /= l;
    o[2] /= l;
    final dt = o[3] * o[0] + o[4] * o[1] + o[5] * o[2];
    o[3] -= dt * o[0];
    o[4] -= dt * o[1];
    o[5] -= dt * o[2];
    l = sqrt(o[3] * o[3] + o[4] * o[4] + o[5] * o[5]);
    o[3] /= l;
    o[4] /= l;
    o[5] /= l;
    o[6] = o[1] * o[5] - o[2] * o[4];
    o[7] = o[2] * o[3] - o[0] * o[5];
    o[8] = o[0] * o[4] - o[1] * o[3];
    rot = o;
  }
}

bool ownBall(int id, int g) => g == 0 ? (id >= 1 && id <= 7) : id >= 9;

class Plan {
  final double angle, power, score;
  final int? pocket; // lubang tujuan (dipakai untuk bola 8)
  Plan(this.angle, this.power, this.score, [this.pocket]);
}

class Ray {
  final Offset end;
  final int? hit;
  final Offset? objDir;
  final Offset? cueDir;
  Ray(this.end, this.hit, this.objDir, this.cueDir);
}

class Game extends ChangeNotifier {
  // detak untuk menganimasikan efek cue saat membidik (bola diam)
  final ValueNotifier<int> fxTick = ValueNotifier<int>(0);
  final Venue venue;
  final void Function(int winner) onEnd;
  final Random rnd = Random();

  late List<Ball> balls;
  int turn = 0; // 0 = kamu, 1 = AI
  List<int?> group = [null, null]; // 0 = solid, 1 = stripe
  Phase phase = Phase.aiming;
  double angle = 0, power = 0;
  String message = '';
  bool breakShot = true;
  bool aiHand = false;
  int? firstHit;
  List<int> potted = [];
  bool cuePotted = false;
  int? winner;
  BotProfile bot = BotProfile.empty;
  String get botName => bot.name;
  bool frozen = false; // true saat animasi mencari lawan (bot autoplay menunggu)
  double botError = 0.02;
  Timer? _t;
  bool _disposed = false;
  Offset? _last;
  int? calledPocket; // lubang yang dipilih untuk bola 8 (giliran sekarang)
  int? shotCalled; // lubang yang dipilih saat tembakan terakhir
  int? eightPocket; // lubang tempat bola 8 jatuh pada tembakan terakhir

  Game(this.venue, this.onEnd) {
    Mod.i.addListener(_onMod);
    reset();
  }

  @override
  void dispose() {
    _disposed = true;
    Mod.i.removeListener(_onMod);
    _t?.cancel();
    fxTick.dispose();
    super.dispose();
  }

  // ---------------- setup ----------------
  void reset() {
    _t?.cancel();
    // bot acak tiap pertandingan: nama, avatar, dan ketelitian
    bot = makeBot(venue, rnd, avoidAvatar: ProfileStore.i.avatar);
    botError = venue.aiError * (0.8 + rnd.nextDouble() * 0.6);
    balls = [Ball(0, Offset(kW * 0.25, kH / 2))];
    final solids = <int>[1, 2, 3, 4, 5, 6, 7]..shuffle(rnd);
    final stripes = <int>[9, 10, 11, 12, 13, 14, 15]..shuffle(rnd);
    final slots = List<int>.filled(15, 0);
    slots[4] = 8;
    slots[10] = solids.removeLast();
    slots[14] = stripes.removeLast();
    final rest = <int>[...solids, ...stripes]..shuffle(rnd);
    var k = 0;
    for (var i = 0; i < 15; i++) {
      if (slots[i] == 0) slots[i] = rest[k++];
    }
    final apexX = kW * 0.72;
    final dx = kR * 2 * 0.866 + 0.3;
    final byId = <int, Ball>{};
    var idx = 0;
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c <= r; c++) {
        byId[slots[idx]] = Ball(slots[idx],
            Offset(apexX + r * dx, kH / 2 + (c - r / 2) * (kR * 2 + 0.3)));
        idx++;
      }
    }
    for (var id = 1; id <= 15; id++) {
      balls.add(byId[id]!);
    }
    turn = 0;
    group = [null, null];
    phase = Phase.aiming;
    angle = 0;
    power = 0;
    message = 'BREAK! Tarik power ke bawah lalu lepas';
    breakShot = true;
    aiHand = false;
    winner = null;
    firstHit = null;
    potted = [];
    cuePotted = false;
    calledPocket = null;
    shotCalled = null;
    eightPocket = null;
    if (Mod.i.autoplay) _scheduleAuto();
    notifyListeners();
  }

  // ---------------- kontrol manusia ----------------
  void setPower(double dp) {
    if (turn != 0 || phase != Phase.aiming) return;
    power = (power + dp).clamp(0.0, 1.0).toDouble();
    notifyListeners();
  }

  void releasePower() {
    if (turn != 0 || phase != Phase.aiming) return;
    if (power > 0.04) {
      if (onEight(0) && calledPocket == null) {
        power = 0;
        message = 'BOLA 8! Pilih lubang dulu (ketuk lubang)';
        notifyListeners();
        return;
      }
      shoot(angle, power, cue: ProfileStore.i.cue);
    } else {
      power = 0;
      notifyListeners();
    }
  }

  // geser bidikan halus (dipakai roda bidik)
  void nudgeAngle(double d) {
    if (turn != 0 || phase != Phase.aiming) return;
    angle += d;
    notifyListeners();
  }

  void panStart(Offset p) {
    _last = p;
    if (phase == Phase.placing && turn == 0) _place(p);
  }

  void panUpdate(Offset p) {
    if (turn != 0) return;
    if (phase == Phase.placing) {
      _place(p);
      return;
    }
    if (phase != Phase.aiming || _last == null) return;
    final c = balls[0].p;
    final v0 = _last! - c;
    final v1 = p - c;
    _last = p;
    if (v0.distance < 25 || v1.distance < 25) return;
    var d = atan2(v1.dy, v1.dx) - atan2(v0.dy, v0.dx);
    while (d > pi) {
      d -= 2 * pi;
    }
    while (d < -pi) {
      d += 2 * pi;
    }
    angle += d;
    notifyListeners();
  }

  void _place(Offset p) {
    final c = Offset(p.dx.clamp(kR, kW - kR).toDouble(),
        p.dy.clamp(kR, kH - kR).toDouble());
    if (_free(c, 0)) {
      balls[0].p = c;
      notifyListeners();
    }
  }

  void confirmPlace() {
    if (phase == Phase.placing) {
      phase = Phase.aiming;
      message = onEight(0) ? 'BOLA 8! Ketuk lubang tujuan' : '';
      notifyListeners();
    }
  }

  bool _free(Offset p, int skipId) {
    if (p.dx < kR || p.dx > kW - kR || p.dy < kR || p.dy > kH - kR) {
      return false;
    }
    for (final b in balls) {
      if (b.pocketed || b.id == skipId) continue;
      if ((b.p - p).distance < 2 * kR + 0.5) return false;
    }
    return true;
  }

  Offset _findFree(Offset s, int skipId) {
    var p = s;
    for (var i = 0; i < 60; i++) {
      if (_free(p, skipId)) return p;
      p = Offset(s.dx + (i + 1) * kR * 0.8,
          s.dy + ((i % 2 == 0) ? 1 : -1) * (i % 7) * kR * 0.5);
    }
    return s;
  }

  // ---------------- pilih lubang bola 8 ----------------
  // Sama seperti 8 Ball Pool: saat tinggal bola 8, lubang tujuan wajib dipilih.
  bool onEight(int who) {
    final g = group[who];
    if (g == null || balls[8].pocketed) return false;
    return !balls
        .any((b) => b.id != 0 && b.id != 8 && !b.pocketed && ownBall(b.id, g));
  }

  bool get canPick => turn == 0 && phase == Phase.aiming && onEight(0);
  bool get choosing => canPick && calledPocket == null;

  int? get markedPocket {
    if (phase == Phase.over || phase == Phase.placing) return null;
    return phase == Phase.moving ? shotCalled : calledPocket;
  }

  int _nearestPocket(Offset p) {
    var bi = 0;
    var bd = double.infinity;
    for (var i = 0; i < 6; i++) {
      final d = (p - kPockets[i]).distance;
      if (d < bd) {
        bd = d;
        bi = i;
      }
    }
    return bi;
  }

  void choosePocket(int i) {
    if (!canPick) return;
    calledPocket = i;
    message = 'Bola 8 -> lubang ${kPocketNames[i]}';
    notifyListeners();
  }

  void tapAt(Offset p) {
    if (!canPick) return;
    final i = _nearestPocket(p);
    if ((p - kPockets[i]).distance < pocketRadius(i) + 34) choosePocket(i);
  }

  // ---------------- tembak ----------------
  void shoot(double a, double p, {CueSkin? cue}) {
    Sfx.hit(0.45 + p * 0.55);
    shotCalled = onEight(turn) ? calledPocket : null;
    calledPocket = null;
    eightPocket = null;
    var mul = 1.0;
    if (cue != null) {
      // cue murah: pukulan lebih lemah & agak meleset; cue mahal: kuat & lurus
      mul = cue.power;
      final wobble = (1 - cue.acc) * 0.06 * (0.4 + 0.6 * p);
      a += (rnd.nextDouble() - 0.5) * 2 * wobble;
    }
    balls[0].v = Offset(cos(a), sin(a)) * ((150 + p * 1850) * mul);
    angle = a;
    power = 0;
    firstHit = null;
    potted = [];
    cuePotted = false;
    message = '';
    phase = Phase.moving;
    notifyListeners();
  }

  // ---------------- fisika ----------------
  void step(double dt) {
    if (phase != Phase.moving) {
      if (turn == 0 &&
          ProfileStore.i.cue.fx != CueFx.none &&
          GameSettings.i.effects) {
        fxTick.value++;
      }
      return;
    }
    const sub = 10;
    final h = dt / sub;
    for (var i = 0; i < sub; i++) {
      _sim(h);
    }
    if (!balls.any((b) => !b.pocketed && b.v != Offset.zero)) {
      _resolve();
    }
    notifyListeners();
  }

  void _cush(double sp) {
    if (sp > 120) Sfx.hit((sp / 1800).clamp(0.08, 0.5));
  }

  void _sim(double h) {
    for (final b in balls) {
      if (b.pocketed || b.v == Offset.zero) continue;
      b.roll(b.v * h);
      final p = b.p + b.v * h;
      var v = b.v;
      final sp = v.distance;
      final ns = sp * exp(-0.9 * h) - 25 * h;
      v = ns <= 6 ? Offset.zero : v * (ns / sp);

      var inPocket = false;
      for (var i = 0; i < 6; i++) {
        if ((p - kPockets[i]).distance < pocketRadius(i)) {
          b.pocketed = true;
          Sfx.hit(0.45);
          b.v = Offset.zero;
          b.p = kPockets[i];
          if (b.id == 0) {
            cuePotted = true;
          } else {
            potted.add(b.id);
            if (b.id == 8) eightPocket = i;
          }
          inPocket = true;
          break;
        }
      }
      if (inPocket) continue;

      var x = p.dx, y = p.dy, vx = v.dx, vy = v.dy;
      if (x < kR) {
        x = kR;
        vx = vx.abs() * 0.8;
        _cush(sp);
      } else if (x > kW - kR) {
        x = kW - kR;
        vx = -vx.abs() * 0.8;
        _cush(sp);
      }
      if (y < kR) {
        y = kR;
        vy = vy.abs() * 0.8;
        _cush(sp);
      } else if (y > kH - kR) {
        y = kH - kR;
        vy = -vy.abs() * 0.8;
        _cush(sp);
      }
      b.p = Offset(x, y);
      b.v = Offset(vx, vy);
    }

    for (var i = 0; i < balls.length; i++) {
      final a = balls[i];
      if (a.pocketed) continue;
      for (var j = i + 1; j < balls.length; j++) {
        final b = balls[j];
        if (b.pocketed) continue;
        final d = b.p - a.p;
        final dist = d.distance;
        if (dist >= 2 * kR || dist == 0) continue;
        final n = d / dist;
        final push = (2 * kR - dist) / 2;
        a.p -= n * push;
        b.p += n * push;
        final rvv = b.v - a.v;
        final rv = rvv.dx * n.dx + rvv.dy * n.dy;
        if (rv < 0) {
          final j2 = -(1 + 0.96) * rv / 2;
          a.v -= n * j2;
          b.v += n * j2;
          if (i == 0 && firstHit == null) firstHit = b.id;
          Sfx.hit((-rv / 1400).clamp(0.12, 1.0));
        }
      }
    }
  }

  // ---------------- aturan 8-ball ----------------
  void _resolve() {
    final me = turn, opp = 1 - turn;
    final g = group[me];

    // misi: hitung bola yang dimasukkan pemain
    if (me == 0) {
      final n = potted.where((id) => id != 8).length;
      if (n > 0) MissionStore.i.add('pot', n);
    }

    // bola 8 masuk saat break -> dikembalikan
    if (breakShot && potted.contains(8)) {
      potted.remove(8);
      final e = balls[8];
      e.pocketed = false;
      e.v = Offset.zero;
      e.p = _findFree(Offset(kW * 0.72, kH / 2), 8);
    }

    final remainingBefore = g == null
        ? 99
        : balls
            .where((b) =>
                b.id != 0 &&
                b.id != 8 &&
                ownBall(b.id, g) &&
                (!b.pocketed || potted.contains(b.id)))
            .length;
    final cleared = g != null && remainingBefore == 0;

    var foul = false;
    var reason = '';
    if (cuePotted) {
      foul = true;
      reason = 'Bola putih masuk';
    } else if (firstHit == null) {
      foul = true;
      reason = 'Tidak menyentuh bola';
    } else {
      final fh = firstHit!;
      if (g == null) {
        if (fh == 8) {
          foul = true;
          reason = 'Salah sasaran (bola 8)';
        }
      } else if (cleared) {
        if (fh != 8) {
          foul = true;
          reason = 'Harus kena bola 8';
        }
      } else if (!ownBall(fh, g)) {
        foul = true;
        reason = 'Salah sasaran';
      }
    }

    // bola 8 masuk
    if (potted.contains(8)) {
      // bola 8 harus masuk ke lubang yang dipilih
      final pocketOk = shotCalled == null || eightPocket == shotCalled;
      final wrongPocket = !foul && cleared && !pocketOk;
      winner = (!foul && cleared && pocketOk) ? me : opp;
      phase = Phase.over;
      message = winner == 0
          ? (me == 1 ? 'Lawan gagal di bola 8. Kamu menang!' : 'Kamu menang!')
          : (wrongPocket
              ? 'Bola 8 masuk lubang salah. Lawan menang'
              : 'Lawan menang');
      notifyListeners();
      onEnd(winner!);
      return;
    }

    // tentukan grup
    if (g == null && !foul) {
      for (final id in potted) {
        if (id != 8) {
          final grp = id <= 7 ? 0 : 1;
          group[me] = grp;
          group[opp] = 1 - grp;
          break;
        }
      }
    }
    final gg = group[me];
    final keep = !foul && gg != null && potted.any((id) => ownBall(id, gg));

    breakShot = false;
    aiHand = false;
    if (foul) {
      turn = opp;
      balls[0].v = Offset.zero;
      if (cuePotted) {
        balls[0].pocketed = false;
        balls[0].p = _findFree(Offset(kW * 0.25, kH / 2), 0);
      }
      if (turn == 0) {
        phase = Phase.placing;
      } else {
        phase = Phase.aiming;
        aiHand = true;
      }
    } else {
      if (!keep) turn = opp;
      phase = Phase.aiming;
    }
    // Mod: lawan dibekukan -> giliran selalu kembali ke kamu
    final frozenSkip = Mod.i.freezeOpp && turn == 1;
    if (frozenSkip) {
      turn = 0;
      aiHand = false;
      phase = Phase.aiming;
    }
    message = '${foul ? 'FOUL! $reason. ' : ''}'
        '${turn == 0 ? 'Giliranmu${phase == Phase.placing ? ' - letakkan bola putih' : ''}' : 'Giliran lawan'}';
    if (frozenSkip) message += ' - lawan dibekukan';
    if (turn == 0 && phase == Phase.aiming && onEight(0)) {
      message += ' - ketuk lubang bola 8';
    }
    power = 0;
    if (turn == 1) {
      _scheduleAI();
    } else if (Mod.i.autoplay) {
      _scheduleAuto();
    }
  }

  // ---------------- AI ----------------
  void _scheduleAI() {
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 1100), _aiPlay);
  }

  // Lawan dibekukan: lewati giliran bot, kembalikan ke kamu
  void _returnFrozenTurn() {
    _t?.cancel();
    turn = 0;
    aiHand = false;
    phase = Phase.aiming;
    power = 0;
    message = 'Lawan dibekukan - giliranmu';
    notifyListeners();
    if (Mod.i.autoplay) _scheduleAuto();
  }

  void _aiPlay() {
    if (_disposed || phase != Phase.aiming || turn != 1) return;
    if (Mod.i.freezeOpp) {
      _returnFrozenTurn();
      return;
    }
    if (aiHand) {
      _aiPlace();
      aiHand = false;
    }
    final plan = _plan(balls[0].p);
    angle = plan.angle;
    power = plan.power;
    calledPocket =
        onEight(1) ? (plan.pocket ?? _nearestPocket(balls[8].p)) : null;
    notifyListeners();
    _t = Timer(const Duration(milliseconds: 900), () {
      if (_disposed || phase != Phase.aiming || turn != 1) return;
      if (Mod.i.freezeOpp) {
        _returnFrozenTurn();
        return;
      }
      final a = angle + (rnd.nextDouble() - 0.5) * 2 * botError;
      final p = power;
      shoot(a, p);
    });
  }

  void _aiPlace([int who = 1]) {
    final cands = <Offset>[balls[0].p];
    for (var i = 0; i < 16; i++) {
      cands.add(Offset(kR + rnd.nextDouble() * (kW - 2 * kR),
          kR + rnd.nextDouble() * (kH - 2 * kR)));
    }
    var bs = double.infinity;
    var bp = balls[0].p;
    for (final c in cands) {
      if (!_free(c, 0)) continue;
      final s = _plan(c, who).score;
      if (s < bs) {
        bs = s;
        bp = c;
      }
    }
    balls[0].p = bp;
  }

  bool _segClear(Offset a, Offset b, Set<int> ignore) {
    for (final ball in balls) {
      if (ball.pocketed || ignore.contains(ball.id)) continue;
      if (_distSeg(ball.p, a, b) < 2 * kR - 1) return false;
    }
    return true;
  }

  double _distSeg(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final l2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (l2 == 0) return (p - a).distance;
    var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / l2;
    t = t.clamp(0.0, 1.0).toDouble();
    return (p - (a + ab * t)).distance;
  }

  Plan _plan(Offset cue, [int who = 1]) {
    final g = group[who];
    final cleared = g != null &&
        !balls.any((b) =>
            b.id != 0 && b.id != 8 && !b.pocketed && ownBall(b.id, g));
    bool legal(int id) =>
        g == null ? id != 8 : (cleared ? id == 8 : ownBall(id, g));
    final targets =
        balls.where((b) => b.id != 0 && !b.pocketed && legal(b.id)).toList();

    Plan? best;
    for (final t in targets) {
      for (var i = 0; i < 6; i++) {
        final pk = kPockets[i];
        final tp = pk - t.p;
        final tpd = tp.distance;
        if (tpd < 1) continue;
        final dirTP = tp / tpd;
        final ghost = t.p - dirTP * (2 * kR);
        if (ghost.dx < kR ||
            ghost.dx > kW - kR ||
            ghost.dy < kR ||
            ghost.dy > kH - kR) {
          continue;
        }
        final cg = ghost - cue;
        final cgd = cg.distance;
        if (cgd < 2) continue;
        final dirCG = cg / cgd;
        final cosCut = dirCG.dx * dirTP.dx + dirCG.dy * dirTP.dy;
        if (cosCut < 0.35) continue;
        if (!_segClear(cue, ghost, {0, t.id})) continue;
        if (!_segClear(t.p, pk, {0, t.id})) continue;
        final score = cgd + tpd * 1.2 + (1 - cosCut) * 400;
        if (best == null || score < best.score) {
          best = Plan(atan2(cg.dy, cg.dx),
              (0.3 + (cgd + tpd) / 900).clamp(0.3, 0.95).toDouble(), score, i);
        }
      }
    }
    if (who == 0 && Mod.i.autoBounce && best == null) {
      best = _bankPlan(cue, targets);
    }
    if (best != null) return best;

    Ball? near;
    var nd = double.infinity;
    for (final t in targets) {
      final d = (t.p - cue).distance;
      if (d < nd) {
        nd = d;
        near = t;
      }
    }
    if (near == null) return Plan(0, 0.5, 1e9);
    final v = near.p - cue;
    return Plan(atan2(v.dy, v.dx), 0.55, 1e6 + nd,
        cleared ? _nearestPocket(near.p) : null);
  }

  // ---------------- MOD: autoplay ----------------
  void _onMod() {
    if (_disposed) return;
    if (Mod.i.freezeOpp && turn == 1 && phase == Phase.aiming) {
      _returnFrozenTurn();
      return;
    }
    if (turn == 0 && (phase == Phase.aiming || phase == Phase.placing)) {
      if (Mod.i.autoplay) {
        _scheduleAuto();
      } else {
        _t?.cancel();
      }
    }
    notifyListeners();
  }

  void _scheduleAuto() {
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 900), _autoPlay);
  }

  void _autoPlay() {
    if (_disposed || !Mod.i.autoplay || turn != 0 || winner != null) return;
    if (frozen) {
      _scheduleAuto();
      return;
    }
    if (phase == Phase.placing) {
      _aiPlace(0);
      phase = Phase.aiming;
      message = '';
      notifyListeners();
    }
    if (phase != Phase.aiming) return;
    final Plan plan;
    if (breakShot) {
      final c = balls[0].p;
      final tgt = Offset(kW * 0.72, kH / 2) - c;
      plan = Plan(atan2(tgt.dy, tgt.dx), 1.0, 0);
    } else {
      plan = _plan(balls[0].p, 0);
    }
    angle = plan.angle;
    power = plan.power;
    calledPocket =
        onEight(0) ? (plan.pocket ?? _nearestPocket(balls[8].p)) : null;
    notifyListeners();
    _t = Timer(const Duration(milliseconds: 800), () {
      if (_disposed ||
          !Mod.i.autoplay ||
          turn != 0 ||
          phase != Phase.aiming) {
        return;
      }
      shoot(plan.angle, plan.power);
    });
  }

  // ---------------- MOD: bank shot (pantulan) ----------------
  bool _inb(Offset g) =>
      g.dx >= kR && g.dx <= kW - kR && g.dy >= kR && g.dy <= kH - kR;

  // cermin titik p terhadap dinding w (0 kiri, 1 kanan, 2 atas, 3 bawah)
  Offset _mirror(Offset p, int w) {
    switch (w) {
      case 0:
        return Offset(2 * kR - p.dx, p.dy);
      case 1:
        return Offset(2 * (kW - kR) - p.dx, p.dy);
      case 2:
        return Offset(p.dx, 2 * kR - p.dy);
      default:
        return Offset(p.dx, 2 * (kH - kR) - p.dy);
    }
  }

  // titik pantul garis a -> bm (bm sudah dicermin) di dinding w
  Offset? _wallHit(Offset a, Offset bm, int w) {
    final vertical = w < 2;
    final wall = w == 0
        ? kR
        : w == 1
            ? kW - kR
            : w == 2
                ? kR
                : kH - kR;
    final da = vertical ? bm.dx - a.dx : bm.dy - a.dy;
    if (da.abs() < 1e-6) return null;
    final t = (wall - (vertical ? a.dx : a.dy)) / da;
    if (t <= 0.02 || t >= 0.98) return null;
    final h = a + (bm - a) * t;
    if (vertical) {
      if (h.dy < kR || h.dy > kH - kR) return null;
    } else {
      if (h.dx < kR || h.dx > kW - kR) return null;
    }
    return h;
  }

  Plan? _bankPlan(Offset cue, List<Ball> targets) {
    Plan? best;
    for (final t in targets) {
      for (var i = 0; i < 6; i++) {
        final pk = kPockets[i];

        // 1) bola target memantul satu kali lalu masuk lubang
        for (var w = 0; w < 4; w++) {
          final h = _wallHit(t.p, _mirror(pk, w), w);
          if (h == null) continue;
          final th = h - t.p;
          final dirTP = th / th.distance;
          final ghost = t.p - dirTP * (2 * kR);
          if (!_inb(ghost)) continue;
          final cg = ghost - cue;
          final cgd = cg.distance;
          if (cgd < 2) continue;
          final cosCut = (cg.dx * dirTP.dx + cg.dy * dirTP.dy) / cgd;
          if (cosCut < 0.5) continue;
          if (!_segClear(cue, ghost, {0, t.id})) continue;
          if (!_segClear(t.p, h, {0, t.id})) continue;
          if (!_segClear(h, pk, {0, t.id})) continue;
          final path = th.distance + (pk - h).distance;
          final score = cgd + path * 1.5 + (1 - cosCut) * 400 + 150;
          if (best == null || score < best.score) {
            best = Plan(atan2(cg.dy, cg.dx),
                (0.45 + (cgd + path) / 800).clamp(0.45, 1.0).toDouble(), score, i);
          }
        }

        // 2) bola putih memantul dulu, baru kena target ke lubang
        final tp = pk - t.p;
        final tpd = tp.distance;
        if (tpd < 1) continue;
        final dirTP2 = tp / tpd;
        final ghost2 = t.p - dirTP2 * (2 * kR);
        if (!_inb(ghost2)) continue;
        if (!_segClear(t.p, pk, {0, t.id})) continue;
        for (var w = 0; w < 4; w++) {
          final gm = _mirror(ghost2, w);
          final h = _wallHit(cue, gm, w);
          if (h == null) continue;
          final last = ghost2 - h;
          final ld = last.distance;
          if (ld < 2) continue;
          final cosCut = (last.dx * dirTP2.dx + last.dy * dirTP2.dy) / ld;
          if (cosCut < 0.4) continue;
          if (!_segClear(cue, h, {0})) continue;
          if (!_segClear(h, ghost2, {0, t.id})) continue;
          final run = (h - cue).distance + ld;
          final score = run * 1.3 + tpd * 1.2 + (1 - cosCut) * 400 + 200;
          if (best == null || score < best.score) {
            best = Plan(atan2(gm.dy - cue.dy, gm.dx - cue.dx),
                (0.5 + (run + tpd) / 800).clamp(0.5, 1.0).toDouble(), score, i);
          }
        }
      }
    }
    return best;
  }

  // ---------------- garis bidik ----------------
  Ray rayCast() {
    final c = balls[0].p;
    final d = Offset(cos(angle), sin(angle));
    var tMin = double.infinity;
    int? hit;
    if (d.dx > 1e-9) {
      tMin = min(tMin, (kW - kR - c.dx) / d.dx);
    } else if (d.dx < -1e-9) {
      tMin = min(tMin, (kR - c.dx) / d.dx);
    }
    if (d.dy > 1e-9) {
      tMin = min(tMin, (kH - kR - c.dy) / d.dy);
    } else if (d.dy < -1e-9) {
      tMin = min(tMin, (kR - c.dy) / d.dy);
    }
    for (final b in balls) {
      if (b.id == 0 || b.pocketed) continue;
      final f = c - b.p;
      final bq = f.dx * d.dx + f.dy * d.dy;
      final cq = f.dx * f.dx + f.dy * f.dy - 4 * kR * kR;
      final disc = bq * bq - cq;
      if (disc < 0) continue;
      final t = -bq - sqrt(disc);
      if (t > 0 && t < tMin) {
        tMin = t;
        hit = b.id;
      }
    }
    final end = c + d * tMin;
    if (hit == null) return Ray(end, null, null, null);
    final n = balls[hit].p - end;
    final nn = n / n.distance;
    final dot = d.dx * nn.dx + d.dy * nn.dy;
    final cd = d - nn * dot;
    return Ray(end, hit, nn, cd.distance > 1e-6 ? cd : null);
  }
}

// ======================================================================
// PAINTER MEJA
// ======================================================================
class TableXf {
  final double s, ox, oy;
  const TableXf(this.s, this.ox, this.oy);
  factory TableXf.of(Size z) {
    final s = min(z.width / (kW + 2 * kRail), z.height / (kH + 2 * kRail));
    return TableXf(s, (z.width - (kW + 2 * kRail) * s) / 2,
        (z.height - (kH + 2 * kRail) * s) / 2);
  }
  Offset toTable(Offset l) =>
      Offset((l.dx - ox) / s - kRail, (l.dy - oy) / s - kRail);
}

// Gambar dasar meja (kayu, kain, motif, lubang) sesuai skin arena.
// Koordinat: titik (0,0) = pojok kiri-atas area main.
final Map<String, TextPainter> _watermarks = {};
TextPainter _watermark(Venue v) => _watermarks.putIfAbsent(v.name, () {
      final t = TextPainter(
        text: TextSpan(
            text: v.name.toUpperCase(),
            style: TextStyle(
                color: Colors.white.withAlpha(26),
                fontSize: 46,
                fontWeight: FontWeight.w900,
                letterSpacing: 8)),
        textDirection: TextDirection.ltr,
      );
      t.layout();
      return t;
    });

void _sparkle(Canvas c, Offset o, double r, Paint p) {
  final path = Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
    ..close();
  c.drawPath(path, p);
}

void _tablePattern(Canvas c, int pattern) {
  if (pattern == 0) return;
  final line = Paint()
    ..color = Colors.white.withAlpha(16)
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke;
  final fill = Paint()..color = Colors.white.withAlpha(22);
  switch (pattern) {
    case 1:
      for (var x = 20.0; x < kW; x += 40) {
        c.drawLine(Offset(x, 0), Offset(x, kH), line);
      }
      break;
    case 2:
      for (var k = -kH; k < kW; k += 50) {
        c.drawLine(Offset(k, 0), Offset(k + kH, kH), line);
        c.drawLine(Offset(k + kH, 0), Offset(k, kH), line);
      }
      break;
    case 3:
      for (var j = 0; j < 4; j++) {
        for (var i = 0; i < 7; i++) {
          final x = 60.0 + i * 120 + (j.isOdd ? 60 : 0);
          final y = 50.0 + j * 100;
          if (x > kW - 20) continue;
          _sparkle(c, Offset(x, y), 9, fill);
        }
      }
      break;
    case 4:
      for (var r = 60.0; r <= 300; r += 60) {
        c.drawCircle(Offset(kW / 2, kH / 2), r, line);
      }
      break;
    case 5:
      for (var k = -kH; k < kW; k += 36) {
        c.drawLine(Offset(k, kH), Offset(k + kH, 0), line);
      }
      break;
    case 6:
      final pink = Paint()..color = const Color(0xFFFBCFE8).withAlpha(34);
      for (var j = 0; j < 4; j++) {
        for (var i = 0; i < 7; i++) {
          final x = 60.0 + i * 120 + (j.isOdd ? 60 : 0);
          final y = 50.0 + j * 100;
          if (x > kW - 20) continue;
          _sakura(c, Offset(x, y), 13, (i + j * 2) * 0.7, pink);
        }
      }
      break;
    case 7: // Taegeuk: lingkaran berpasangan
      for (var j = 0; j < 2; j++) {
        for (var i = 0; i < 4; i++) {
          final o = Offset(100.0 + i * 200, 100.0 + j * 200);
          c.drawCircle(o, 34, line);
          c.drawArc(Rect.fromCircle(center: o, radius: 34), 0, pi, true, fill);
        }
      }
      break;
    case 8: // Arabesque: kisi berlian + titik
      for (var k = -kH; k < kW; k += 64) {
        c.drawLine(Offset(k, 0), Offset(k + kH, kH), line);
        c.drawLine(Offset(k + kH, 0), Offset(k, kH), line);
      }
      for (var y = 32.0; y < kH; y += 64) {
        for (var x = 32.0; x < kW; x += 64) {
          c.drawCircle(Offset(x, y), 3, fill);
        }
      }
      break;
    case 9: // Samba: zigzag
      for (var y = 40.0; y < kH; y += 60) {
        final path = Path()..moveTo(0, y);
        var up = true;
        for (var x = 0.0; x < kW; x += 25) {
          path.lineTo(x + 25, up ? y - 14 : y);
          up = !up;
        }
        c.drawPath(path, line);
      }
      break;
    case 10: // Piramida: segitiga berselang-seling
      for (var j = 0; j < 3; j++) {
        for (var i = 0; i < 7; i++) {
          final x = 70.0 + i * 110 + (j.isOdd ? 55 : 0);
          final y = 70.0 + j * 120;
          if (x > kW - 30) continue;
          c.drawPath(
              Path()
                ..moveTo(x, y - 24)
                ..lineTo(x + 28, y + 16)
                ..lineTo(x - 28, y + 16)
                ..close(),
              line);
          c.drawCircle(Offset(x, y + 2), 2.6, fill);
        }
      }
      break;
    case 11: // Fleur-de-lis
      for (var j = 0; j < 4; j++) {
        for (var i = 0; i < 7; i++) {
          final x = 60.0 + i * 120 + (j.isOdd ? 60 : 0);
          final y = 50.0 + j * 100;
          if (x > kW - 20) continue;
          _fleur(c, Offset(x, y), 15, fill);
        }
      }
      break;
    case 12: // Skyline kota
      final win = Paint()..color = Colors.white.withAlpha(30);
      for (var x = 14.0, k = 0; x < kW; x += 44, k++) {
        final h = 50 + 70 * (0.5 + 0.5 * sin(k * 1.7 + 0.6));
        c.drawRect(Rect.fromLTWH(x, kH - h, 32, h), fill);
        for (var wy = kH - h + 10; wy < kH - 8; wy += 16) {
          c.drawRect(Rect.fromLTWH(x + 6, wy, 5, 7), win);
          c.drawRect(Rect.fromLTWH(x + 19, wy, 5, 7), win);
        }
      }
      break;
    case 13: // Kasino: berlian & chip
      final neon = Paint()..color = const Color(0xFFF43F5E).withAlpha(34);
      for (var j = 0; j < 4; j++) {
        for (var i = 0; i < 8; i++) {
          final x = 50.0 + i * 100;
          final y = 50.0 + j * 100;
          if (x > kW - 20) continue;
          if ((i + j).isEven) {
            c.drawPath(
                Path()
                  ..moveTo(x, y - 14)
                  ..lineTo(x + 10, y)
                  ..lineTo(x, y + 14)
                  ..lineTo(x - 10, y)
                  ..close(),
                neon);
          } else {
            c.drawCircle(Offset(x, y), 9, line);
          }
        }
      }
      break;
  }
}

// Fleur-de-lis sederhana: tiga kelopak + pita.
void _fleur(Canvas c, Offset o, double r, Paint p) {
  c.drawOval(
      Rect.fromCenter(
          center: o + Offset(0, -r * 0.2), width: r * 0.55, height: r * 1.3),
      p);
  for (final sgn in [-1.0, 1.0]) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(sgn * 0.9);
    c.drawOval(
        Rect.fromCenter(
            center: Offset(0, -r * 0.45), width: r * 0.45, height: r),
        p);
    c.restore();
  }
  c.drawRect(
      Rect.fromCenter(
          center: o + Offset(0, r * 0.55), width: r * 1.0, height: r * 0.16),
      p);
}

// Bunga sakura 5 kelopak.
void _sakura(Canvas c, Offset o, double r, double rot, Paint p) {
  for (var k = 0; k < 5; k++) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(rot + k * 2 * pi / 5);
    c.drawOval(
        Rect.fromCenter(center: Offset(0, -r * 0.6), width: r * 0.7, height: r),
        p);
    c.restore();
  }
}

void drawTableBase(Canvas c, Venue v,
    {bool watermark = true, bool pattern = true, bool shadow = true}) {
  final sk = v.skin;

  // kayu
  final outer = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-kRail, -kRail, kW + 2 * kRail, kH + 2 * kRail),
      const Radius.circular(30));
  if (shadow) {
    c.drawRRect(
        outer.shift(const Offset(0, 6)),
        Paint()
          ..color = Colors.black54
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }
  c.drawRRect(
      outer,
      Paint()
        ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [sk.railTop, sk.railBottom]).createShader(outer.outerRect));
  c.drawRRect(
      outer.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = sk.trim.withAlpha(200));

  // titik bidik (diamond) di kayu
  final sightPaint = Paint()..color = sk.sight.withAlpha(215);
  void dia(Offset o) {
    const r = 3.4;
    c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - r)
          ..lineTo(o.dx + r, o.dy)
          ..lineTo(o.dx, o.dy + r)
          ..lineTo(o.dx - r, o.dy)
          ..close(),
        sightPaint);
  }

  for (var i = 1; i < 8; i++) {
    if (i == 4) continue;
    final x = kW * i / 8;
    dia(Offset(x, -kRail / 2));
    dia(Offset(x, kH + kRail / 2));
  }
  for (var i = 1; i < 4; i++) {
    final y = kH * i / 4;
    dia(Offset(-kRail / 2, y));
    dia(Offset(kW + kRail / 2, y));
  }

  // bantalan + kain
  c.drawRect(const Rect.fromLTWH(-14, -14, kW + 28, kH + 28),
      Paint()..color = Color.lerp(v.felt, Colors.black, 0.35)!);
  const feltRect = Rect.fromLTWH(0, 0, kW, kH);
  c.drawRect(
      feltRect,
      Paint()
        ..shader = RadialGradient(radius: 0.9, colors: [
          Color.lerp(v.felt, Colors.white, 0.14)!,
          v.felt,
          Color.lerp(v.felt, Colors.black, 0.25)!
        ]).createShader(feltRect));

  // motif kain + nama arena
  c.save();
  c.clipRect(feltRect);
  if (pattern) _tablePattern(c, sk.pattern);
  if (watermark) {
    final t = _watermark(v);
    t.paint(c, Offset((kW - t.width) / 2, (kH - t.height) / 2));
  }
  c.restore();

  // lubang
  for (var i = 0; i < 6; i++) {
    c.drawCircle(kPockets[i], pocketRadius(i) + 4,
        Paint()..color = Color.lerp(sk.railBottom, Colors.black, 0.6)!);
    c.drawCircle(
        kPockets[i], pocketRadius(i) - 1, Paint()..color = Colors.black);
  }

  // garis & titik
  final faint = Paint()
    ..color = Colors.white.withAlpha(45)
    ..strokeWidth = 1.2;
  c.drawLine(Offset(kW * 0.25, 6), Offset(kW * 0.25, kH - 6), faint);
  c.drawCircle(Offset(kW * 0.25, kH / 2), 2.5, faint);
  c.drawCircle(Offset(kW * 0.72, kH / 2), 2.5, faint);
}

// Pratinjau meja kecil (untuk lobi & koleksi).
class _MiniTablePainter extends CustomPainter {
  final Venue v;
  _MiniTablePainter(this.v);

  @override
  void paint(Canvas c, Size size) {
    final s = min(size.width / (kW + 2 * kRail), size.height / (kH + 2 * kRail));
    if (s <= 0) return;
    c.translate((size.width - (kW + 2 * kRail) * s) / 2,
        (size.height - (kH + 2 * kRail) * s) / 2);
    c.scale(s);
    c.translate(kRail, kRail);
    drawTableBase(c, v);
  }

  @override
  bool shouldRepaint(covariant _MiniTablePainter old) => old.v != v;
}

class TablePainter extends CustomPainter {
  final Game g;
  TablePainter(this.g) : super(repaint: Listenable.merge([g, g.fxTick]));

  static final Map<int, TextPainter> _tps = {};
  TextPainter _tp(int id) => _tps.putIfAbsent(id, () {
        final t = TextPainter(
          text: TextSpan(
              text: '$id',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: kR * 0.62,
                  fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr,
        );
        t.layout();
        return t;
      });

  @override
  void paint(Canvas c, Size size) {
    final xf = TableXf.of(size);
    c.save();
    c.translate(xf.ox, xf.oy);
    c.scale(xf.s);
    c.translate(kRail, kRail);
    final v = g.venue;

    drawTableBase(c, v,
        pattern: GameSettings.i.pattern, shadow: GameSettings.i.shadows);
    _pocketMarks(c);

    // garis bidik (di bawah bola)
    final aiming = g.phase == Phase.aiming;
    if (aiming && g.turn == 0) _guide(c);

    // bola
    for (final b in g.balls) {
      if (!b.pocketed && b.id != 0) _ball(c, b);
    }
    final cue = g.balls[0];
    if (!cue.pocketed) {
      _ball(c, cue);
      if (g.phase == Phase.placing) {
        c.drawCircle(
            cue.p,
            kR + 5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.white.withAlpha(220));
      }
    }

    if (aiming) _stick(c);
    c.restore();
  }

  static final TextPainter _eight = () {
    final t = TextPainter(
      text: const TextSpan(
          text: '8',
          style: TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    );
    t.layout();
    return t;
  }();

  // penanda lubang untuk bola 8 (pilih lubang ala 8 Ball Pool)
  void _pocketMarks(Canvas c) {
    if (g.phase == Phase.over) return;
    const gold = Color(0xFFFACC15);
    final mark = g.markedPocket;
    if (g.canPick) {
      for (var i = 0; i < 6; i++) {
        if (i == mark) continue;
        c.drawCircle(
            kPockets[i],
            pocketRadius(i) + 8,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = gold.withAlpha(150));
      }
    }
    if (mark != null) {
      final p = kPockets[mark];
      final r = pocketRadius(mark) + 10;
      c.drawCircle(p, r, Paint()..color = gold.withAlpha(60));
      c.drawCircle(
          p,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..color = gold);
      final dir = const Offset(kW / 2, kH / 2) - p;
      final b = p + dir / dir.distance * (pocketRadius(mark) + 34);
      c.drawCircle(b, 10, Paint()..color = Colors.black);
      c.drawCircle(
          b,
          10,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white);
      _eight.paint(c, b - Offset(_eight.width / 2, _eight.height / 2));
    }
  }

  // garis lurus yang memantul di bantalan
  void _trace(Canvas c, Offset s, Offset d, double len, Paint p, int bounces) {
    var pos = s;
    var dir = d;
    var left = len;
    for (var i = 0; i <= bounces && left > 0; i++) {
      final tx = dir.dx > 1e-9
          ? (kW - kR - pos.dx) / dir.dx
          : dir.dx < -1e-9
              ? (kR - pos.dx) / dir.dx
              : double.infinity;
      final ty = dir.dy > 1e-9
          ? (kH - kR - pos.dy) / dir.dy
          : dir.dy < -1e-9
              ? (kR - pos.dy) / dir.dy
              : double.infinity;
      final t = max(0.0, min(tx, ty));
      final seg = min(t, left);
      final end = pos + dir * seg;
      c.drawLine(pos, end, p);
      left -= seg;
      if (seg < t) break;
      dir = tx <= ty ? Offset(-dir.dx, dir.dy) : Offset(dir.dx, -dir.dy);
      pos = end;
    }
  }

  void _guide(Canvas c) {
    final r = g.rayCast();
    final cue = g.balls[0].p;
    final d = Offset(cos(g.angle), sin(g.angle));
    final long = Mod.i.longLine;
    final aimMul = g.turn == 0 ? ProfileStore.i.cue.aim : 1.0;
    final line = Paint()
      ..color = Colors.white.withAlpha(210)
      ..strokeWidth = 1.6;
    final soft = Paint()
      ..color = Colors.white.withAlpha(110)
      ..strokeWidth = 1.4;
    if (long && r.hit == null) {
      _trace(c, cue + d * kR, d, 1600, line, 3);
    } else {
      c.drawLine(cue + d * kR, r.end, line);
    }
    c.drawCircle(
        r.end,
        kR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white.withAlpha(220));
    if (r.hit != null) {
      final b = g.balls[r.hit!].p;
      if (long) {
        _trace(c, b, r.objDir!, 520, line, 2);
      } else {
        c.drawLine(b, b + r.objDir! * (70 * aimMul), line);
      }
      final cd = r.cueDir;
      if (cd != null) {
        if (long) {
          _trace(c, r.end, cd / cd.distance, 300, soft, 1);
        } else {
          c.drawLine(r.end, r.end + cd * (55 * aimMul), soft);
        }
      }
    }
  }

  void _stick(Canvas c) {
    final cue = g.balls[0].p;
    final dir = Offset(cos(g.angle), sin(g.angle));
    final pull = 14 + g.power * 90;
    final tip = cue - dir * (kR + pull);
    drawCue(c, g.turn == 0 ? ProfileStore.i.cue : g.bot.cueSkin, tip, dir);
  }

  void _ball(Canvas c, Ball b) {
    final p = b.p;
    final rect = Rect.fromCircle(center: p, radius: kR);
    final color = kBallColors[b.id];
    if (GameSettings.i.shadows) {
      c.drawCircle(p + const Offset(2, 3), kR,
          Paint()..color = Colors.black.withAlpha(90));
    }

    final light = Color.lerp(color, Colors.white, 0.55)!;
    final dark = Color.lerp(color, Colors.black, 0.5)!;
    final m = b.rot;
    if (b.stripe) {
      c.drawCircle(
          p,
          kR,
          Paint()
            ..shader = const RadialGradient(
                center: Alignment(-0.35, -0.4),
                radius: 1,
                colors: [
                  Colors.white,
                  Color(0xFFE6E6E6),
                  Color(0xFF9A9A9A)
                ],
                stops: [0, 0.55, 1]).createShader(rect));
      c.save();
      c.clipPath(Path()..addOval(rect));
      _band(c, p, m, Paint()
        ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.2),
            radius: 1.2,
            colors: [light, color, dark]).createShader(rect));
      c.restore();
    } else {
      c.drawCircle(
          p,
          kR,
          Paint()
            ..shader = RadialGradient(
                center: const Alignment(-0.35, -0.4),
                radius: 1,
                colors: [light, color, dark],
                stops: const [0, 0.55, 1]).createShader(rect));
    }
    if (b.id != 0) {
      c.save();
      c.clipPath(Path()..addOval(rect));
      // dua nomor di sisi berlawanan bola; tampil bila menghadap penonton
      _spot(c, p, m, b.id, false);
      _spot(c, p, m, b.id, true);
      c.restore();
    }
    if (GameSettings.i.shine) {
      c.drawCircle(p + Offset(-kR * 0.35, -kR * 0.4), kR * 0.2,
          Paint()..color = Colors.white.withAlpha(150));
    }
  }

  // Cakram putih + nomor yang ikut berputar (proyeksi ortografis).
  void _spot(Canvas c, Offset p, List<double> m, int id, bool back) {
    // normal cakram di ruang dunia = kolom ke-3 matriks (atau kebalikannya)
    final sg = back ? -1.0 : 1.0;
    final nz = m[8] * sg;
    if (nz <= 0.02) return;
    final nx = m[2] * sg, ny = m[5] * sg;
    // sumbu lokal cakram: u -> sumbu x badan, v -> kebalikan sumbu y badan
    final ux = m[0] * sg, uy = m[3] * sg; // sisi belakang: x dibalik
    final c0 = p + Offset(nx, -ny) * kR;
    c.save();
    c.translate(c0.dx, c0.dy);
    c.transform(Float64List.fromList([
      ux, -uy, 0, 0, //
      -m[1], m[4], 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]));
    c.drawCircle(Offset.zero, kR * 0.46, Paint()..color = Colors.white);
    final t = _tp(id);
    t.paint(c, Offset(-t.width / 2, -t.height / 2));
    c.restore();
  }

  // Garis warna bola belang: jaring bola pada |y badan| < 0.58 diproyeksikan.
  void _band(Canvas c, Offset p, List<double> m, Paint paint) {
    const nLon = 28, nLat = 4;
    const hh = 0.58;
    final xs = Float32List((nLon + 1) * (nLat + 1) * 2);
    final zs = List<double>.filled((nLon + 1) * (nLat + 1), 0);
    var k = 0;
    for (var i = 0; i <= nLon; i++) {
      final phi = i * 2 * pi / nLon;
      for (var j = 0; j <= nLat; j++) {
        final sy = -hh + 2 * hh * j / nLat;
        final rho = sqrt(1 - sy * sy);
        final bx = rho * cos(phi), by = sy, bz = rho * sin(phi);
        final wx = m[0] * bx + m[1] * by + m[2] * bz;
        final wy = m[3] * bx + m[4] * by + m[5] * bz;
        final wz = m[6] * bx + m[7] * by + m[8] * bz;
        xs[k * 2] = (p.dx + wx * kR).toDouble();
        xs[k * 2 + 1] = (p.dy - wy * kR).toDouble();
        zs[k] = wz;
        k++;
      }
    }
    final tri = <double>[];
    for (var i = 0; i < nLon; i++) {
      for (var j = 0; j < nLat; j++) {
        final a = i * (nLat + 1) + j;
        final b = (i + 1) * (nLat + 1) + j;
        final cI = a + 1, dI = b + 1;
        if (max(max(zs[a], zs[b]), max(zs[cI], zs[dI])) <= 0) continue;
        for (final q in [a, b, cI, b, dI, cI]) {
          tri.add(xs[q * 2]);
          tri.add(xs[q * 2 + 1]);
        }
      }
    }
    if (tri.isEmpty) return;
    final v = ui.Vertices.raw(ui.VertexMode.triangles, Float32List.fromList(tri));
    c.drawVertices(v, BlendMode.srcOver, paint);
    v.dispose();
  }

  @override
  bool shouldRepaint(covariant TablePainter old) => true;
}

// ======================================================================
// POWER SLIDER
// ======================================================================
class PowerBar extends StatelessWidget {
  final double value;
  final bool enabled;
  final Color accent;
  final ValueChanged<double> onDelta;
  final VoidCallback onRelease;
  const PowerBar(
      {super.key,
      required this.value,
      required this.enabled,
      required this.accent,
      required this.onDelta,
      required this.onRelease});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final h = box.maxHeight;
      return Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate:
              enabled ? (d) => onDelta(d.delta.dy / (h - 30)) : null,
          onVerticalDragEnd: enabled ? (_) => onRelease() : null,
          onVerticalDragCancel: enabled ? onRelease : null,
          child: CustomPaint(
              size: Size(box.maxWidth, h),
              painter: _PowerPainter(value, accent)),
        ),
      );
    });
  }
}

class _PowerPainter extends CustomPainter {
  final double v;
  final Color accent;
  _PowerPainter(this.v, this.accent);

  @override
  void paint(Canvas c, Size s) {
    final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width / 2 - 11, 0, 22, s.height),
        const Radius.circular(11));
    c.drawRRect(track, Paint()..color = Colors.black54);
    c.save();
    c.clipRRect(track);
    final fillH = 15 + v * (s.height - 30);
    c.drawRect(
        Rect.fromLTWH(s.width / 2 - 11, 0, 22, fillH),
        Paint()
          ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Color(0xFF22C55E),
                Color(0xFFFACC15),
                Color(0xFFEF4444)
              ]).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));
    c.restore();
    c.drawRRect(
        track,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white30);
    final hy = 15 + v * (s.height - 30);
    c.drawCircle(Offset(s.width / 2, hy), 14, Paint()..color = Colors.white);
    c.drawCircle(
        Offset(s.width / 2, hy),
        14,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = accent);
  }

  @override
  bool shouldRepaint(covariant _PowerPainter o) => o.v != v;
}

// ======================================================================
// LAYAR GAME
// ======================================================================
class GameScreen extends StatefulWidget {
  final Venue venue;
  const GameScreen({super.key, required this.venue});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  bool _coinFx = false;
  bool _loseFx = false;
  int _loseAmt = 0;
  bool _matching = true; // animasi mencari lawan
  int _matchSeq = 0;
  int _coinAmt = 0;
  late final Game game;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    game = Game(widget.venue, _onEnd);
    game.frozen = true;
    Sfx.arena(); // sfx saat masuk arena
    _ticker = createTicker((e) {
      final dt = (e - _last).inMicroseconds / 1e6;
      if (GameSettings.i.fps30 && dt < 0.03) return; // batasi 30 FPS
      _last = e;
      game.step(dt.clamp(0.0, 1 / 30).toDouble());
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    game.dispose();
    super.dispose();
  }

  void _beginMatch() {
    if (!mounted) return;
    game.frozen = true;
    setState(() {
      _matching = true;
      _matchSeq++;
    });
  }

  Future<void> _onEnd(int w) async {
    final fee = widget.venue.fee;
    if (w == 0) Wallet.add(fee * 2);
    final up = await ProfileStore.i.record(w == 0);
    MissionStore.i.onMatch(w == 0, widget.venue.name);
    if (!mounted) return;
    if (w == 0) {
      Sfx.coins();
      setState(() {
        _coinFx = true;
        _coinAmt = fee * 2;
      });
      await Future.delayed(const Duration(milliseconds: 1900));
      if (!mounted) return;
      setState(() => _coinFx = false);
    } else {
      Sfx.lose();
      setState(() {
        _loseFx = true;
        _loseAmt = fee;
      });
      await Future.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
      setState(() => _loseFx = false);
    }
    final xpGain = w == 0 ? ProfileStore.xpWin : ProfileStore.xpLose;
    final lvl = up ? '\nNaik ke Level ${ProfileStore.i.level}! 🎉' : '';
    if (Mod.i.autoQueue && Wallet.coins.value >= fee) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1400),
        content: Text(
            '${w == 0 ? 'Menang' : 'Kalah'} - queue otomatis... Saldo ${rp(Wallet.coins.value)}'),
      ));
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      if (Mod.i.autoQueue && Wallet.coins.value >= fee) {
        await Wallet.add(-fee);
        Sfx.arena();
        game.reset();
        _beginMatch();
        return;
      }
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1A33),
        title: Text(w == 0 ? 'MENANG! 🏆' : 'KALAH 😢',
            textAlign: TextAlign.center),
        content: Text(
          w == 0
              ? 'Hadiah ${rp(fee * 2)}\n(untung ${rp(fee)})\n\nSaldo: ${rp(Wallet.coins.value)}\n+$xpGain XP$lvl'
              : 'Taruhan ${rp(fee)} hangus.\n\nSaldo: ${rp(Wallet.coins.value)}\n+$xpGain XP$lvl',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              Navigator.pop(context);
            },
            child: const Text('Lobi'),
          ),
          FilledButton(
            onPressed: Wallet.coins.value >= fee
                ? () async {
                    Navigator.pop(dctx);
                    await Wallet.add(-fee);
                    Sfx.arena();
                    game.reset();
                    _beginMatch();
                  }
                : null,
            child: Text('Main lagi (${rp(fee)})'),
          ),
        ],
      ),
    );
  }

  void _confirmExit() {
    if (game.phase == Phase.over) {
      Navigator.pop(context);
      return;
    }
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1A33),
        title: const Text('Keluar dari meja?'),
        content: Text('Taruhan ${rp(widget.venue.fee)} akan hangus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Lanjut main')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dctx);
              Navigator.pop(context);
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Widget _balls(int? grp) {
    if (grp == null) {
      return const Text('Meja terbuka',
          style: TextStyle(fontSize: 12, color: Colors.white60));
    }
    final ids = grp == 0
        ? <int>[1, 2, 3, 4, 5, 6, 7]
        : <int>[9, 10, 11, 12, 13, 14, 15];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final id in [...ids, 8])
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: _BallIcon(id, 24, dim: game.balls[id].pocketed),
          ),
      ],
    );
  }

  Widget _chip(int idx) {
    final v = widget.venue;
    final active = game.turn == idx && game.phase != Phase.over;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      decoration: BoxDecoration(
        color: active ? Colors.black54 : Colors.black38,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
            color: active ? v.accent : Colors.white24, width: active ? 3 : 1.5),
        boxShadow: active
            ? [BoxShadow(color: v.accent.withAlpha(140), blurRadius: 16)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (idx == 0)
            _Avatar(
                index: ProfileStore.i.avatar,
                size: 42,
                frame: ProfileStore.i.borderId)
          else
            _Avatar(
                index: game.bot.avatar, size: 42, frame: game.bot.border),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                    idx == 0
                        ? (ProfileStore.i.isNew ? 'Kamu' : ProfileStore.i.name)
                        : (Mod.i.freezeOpp ? '❄ ${game.botName}' : game.botName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 2),
              _balls(game.group[idx]),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.venue;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.2,
              colors: [
                Color.lerp(v.felt, Colors.black, 0.75)!,
                const Color(0xFF03060F)
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: game,
              builder: (ctx, _) {
                final canAim = game.turn == 0 && game.phase == Phase.aiming;
                return Stack(
                  children: [
                    // meja
                    Positioned(
                      left: 76,
                      right: GameSettings.i.aimWheel ? 112 : 8,
                      top: 74,
                      bottom: 4,
                      child: LayoutBuilder(builder: (c, box) {
                        final size = box.biggest;
                        final xf = TableXf.of(size);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (d) =>
                              game.panStart(xf.toTable(d.localPosition)),
                          onPanUpdate: (d) =>
                              game.panUpdate(xf.toTable(d.localPosition)),
                          onTapUp: (d) =>
                              game.tapAt(xf.toTable(d.localPosition)),
                          child: CustomPaint(
                              size: size, painter: TablePainter(game)),
                        );
                      }),
                    ),
                    // kelopak sakura jatuh (arena Osaka)
                    if (v.skin.pattern == 6 && GameSettings.i.effects)
                      const Positioned.fill(child: _PetalFall()),
                    // power slider
                    Positioned(
                      left: 10,
                      top: 78,
                      bottom: 10,
                      width: 56,
                      child: PowerBar(
                        value: game.power,
                        enabled: canAim,
                        accent: v.accent,
                        onDelta: game.setPower,
                        onRelease: game.releasePower,
                      ),
                    ),
                    // roda bidik (geser bidikan dengan halus)
                    if (GameSettings.i.aimWheel)
                      Positioned(
                        right: 10,
                        bottom: 14,
                        width: 92,
                        height: 92,
                        child: AimWheel(
                            game: game, enabled: canAim, accent: v.accent),
                      ),
                    // top bar
                    Positioned(
                      top: 2,
                      left: 4,
                      right: 8,
                      height: 68,
                      child: Row(
                        children: [
                          IconButton(
                              onPressed: _confirmExit,
                              icon: const Icon(Icons.arrow_back_ios_new)),
                          Flexible(
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: _chip(0))),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${v.flag} ${v.name.toUpperCase()}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        letterSpacing: 2,
                                        color: Colors.white70)),
                                Text(rp(v.fee * 2),
                                    style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFACC15))),
                              ],
                            ),
                          ),
                          Flexible(
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: _chip(1))),
                        ],
                      ),
                    ),
                    // pesan
                    if (game.message.isNotEmpty)
                      Positioned(
                        top: 76,
                        left: 80,
                        right: 12,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(170),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: v.accent.withAlpha(180)),
                            ),
                            child: Text(game.message,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    // tombol letakkan bola
                    if (game.phase == Phase.placing && game.turn == 0)
                      Positioned(
                        right: 20,
                        bottom: 14,
                        child: FilledButton.icon(
                          onPressed: game.confirmPlace,
                          icon: const Icon(Icons.check),
                          label: const Text('Letakkan bola'),
                        ),
                      ),
                    // animasi koin saat menang
                    if (_coinFx)
                      Positioned.fill(child: _CoinShower(amount: _coinAmt)),
                    if (_loseFx)
                      Positioned.fill(child: _DefeatFx(amount: _loseAmt)),
                    // animasi mencari lawan (bot & taruhan diacak)
                    if (_matching)
                      Positioned.fill(
                        child: _MatchOverlay(
                          key: ValueKey(_matchSeq),
                          venue: v,
                          bot: game.bot,
                          quick: Mod.i.autoQueue || Mod.i.autoplay,
                          onDone: () {
                            game.frozen = false;
                            if (mounted) setState(() => _matching = false);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}


// ======================================================================
// IKON BOLA BERNOMOR (HUD) + ANIMASI MENCARI LAWAN
// ======================================================================
class _BallIcon extends StatelessWidget {
  final int n;
  final double size;
  final bool dim;
  const _BallIcon(this.n, this.size, {this.dim = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: dim ? 0.78 : 1.0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: dim ? 0.28 : 1.0,
        duration: const Duration(milliseconds: 260),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _BallIconPainter(n)),
        ),
      ),
    );
  }
}

class _BallIconPainter extends CustomPainter {
  final int n;
  _BallIconPainter(this.n);

  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final r = s.width * 0.46;
    _drawBall(c, o, r, n);
    if (n == 0) return;
    // lingkaran putih + nomor lebih besar supaya terbaca di ukuran kecil
    c.drawCircle(o, r * 0.58, Paint()..color = Colors.white);
    final tp = TextPainter(
      text: TextSpan(
          text: '$n',
          style: TextStyle(
              color: Colors.black,
              fontSize: r * 0.86,
              fontWeight: FontWeight.w900,
              height: 1.0)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BallIconPainter old) => old.n != n;
}

const List<int> _kPotFlicker = [
  10000, 25000, 50000, 100000, 200000, 500000, 1000000, 2000000, 5000000
];

/// Layar pembuka pertandingan: lawan (bot) dan taruhan diacak seperti
/// mesin slot, lalu terkunci ke lawan & taruhan yang sebenarnya.
class _MatchOverlay extends StatefulWidget {
  final Venue venue;
  final BotProfile bot;
  final bool quick;
  final VoidCallback onDone;
  const _MatchOverlay({
    super.key,
    required this.venue,
    required this.bot,
    required this.onDone,
    this.quick = false,
  });

  @override
  State<_MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends State<_MatchOverlay>
    with SingleTickerProviderStateMixin {
  static const double _lockPot = 0.46, _lockBot = 0.62;
  late final AnimationController _c;
  bool _coinSfx = false, _done = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.quick ? 1500 : 3800))
      ..addListener(() {
        if (!_coinSfx && _c.value >= _lockPot) {
          _coinSfx = true;
          Sfx.coins();
        }
      })
      ..addStatusListener((st) {
        if (st == AnimationStatus.completed && !_done) {
          _done = true;
          widget.onDone();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _p(double t, double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0).toDouble());

  Widget _card(Widget avatar, String name, Color border) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 2.5),
        boxShadow: [BoxShadow(color: border.withAlpha(90), blurRadius: 18)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(height: 8),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.venue;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!_done) {
          _c.animateTo(1.0, duration: const Duration(milliseconds: 180));
        }
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (ctx, _) {
          final t = _c.value;
          final fade = t > 0.92
              ? (1 - (t - 0.92) / 0.08).clamp(0.0, 1.0).toDouble()
              : 1.0;
          final tick = (t * (widget.quick ? 20 : 46)).floor();
          final botLocked = t >= _lockBot;
          final potLocked = t >= _lockPot;
          final rb = Random(tick * 7919 + 13);
          final shown = botLocked ? widget.bot : flickerBot(rb);
          final name = shown.name;
          final pot = potLocked
              ? v.fee * 2
              : _kPotFlicker[Random(tick * 104729 + 5)
                  .nextInt(_kPotFlicker.length)];
          final inL = _p(t, 0.0, 0.18);
          final inR = _p(t, 0.05, 0.23);
          final inC = _p(t, 0.1, 0.28, Curves.easeOutBack);
          final double botPop = botLocked
              ? 1 + 0.2 * sin(((t - _lockBot) / 0.1).clamp(0.0, 1.0) * pi)
              : 1.0;
          final double potPop = potLocked
              ? 1 + 0.18 * sin(((t - _lockPot) / 0.1).clamp(0.0, 1.0) * pi)
              : 1.0;
          final shake = botLocked ? 0.0 : (rb.nextDouble() - 0.5) * 6;

          final botAvatarW = _Avatar(
              index: shown.avatar,
              size: 68,
              frame: botLocked ? widget.bot.border : null);

          return Opacity(
            opacity: fade,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Color.lerp(v.felt, Colors.black, 0.6)!,
                    const Color(0xFF03060F)
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _p(t, 0, 0.1),
                          child: Column(children: [
                            Text('${v.flag} ${v.name.toUpperCase()}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(
                                botLocked
                                    ? 'LAWAN DITEMUKAN!'
                                    : 'MENCARI LAWAN...',
                                style: TextStyle(
                                    fontSize: 22,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        botLocked ? v.accent : Colors.white)),
                          ]),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.translate(
                              offset: Offset(-120 * (1 - inL), 0),
                              child: Opacity(
                                opacity: inL,
                                child: _card(
                                  _Avatar(
                                      index: ProfileStore.i.avatar,
                                      size: 68,
                                      frame: ProfileStore.i.borderId),
                                  ProfileStore.i.isNew
                                      ? 'Kamu'
                                      : ProfileStore.i.name,
                                  v.accent,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 190,
                              child: Opacity(
                                opacity: inC.clamp(0.0, 1.0).toDouble(),
                                child: Transform.scale(
                                  scale: inC.clamp(0.0, 1.3).toDouble(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('VS',
                                          style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.w900,
                                              fontStyle: FontStyle.italic,
                                              color: v.accent)),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          for (var i = 0; i < 3; i++)
                                            Transform.translate(
                                              offset: Offset(
                                                  0,
                                                  -(potLocked ? 8 : 4) *
                                                      sin(t * pi * 10 + i)),
                                              child: const Text('🪙',
                                                  style:
                                                      TextStyle(fontSize: 22)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Transform.scale(
                                        scale: potPop,
                                        child: Text(rp(pot),
                                            style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: potLocked
                                                    ? const Color(0xFFFACC15)
                                                    : Colors.white54)),
                                      ),
                                      const Text('TARUHAN',
                                          style: TextStyle(
                                              fontSize: 10,
                                              letterSpacing: 2,
                                              color: Colors.white54)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(120 * (1 - inR) + shake, 0),
                              child: Opacity(
                                opacity: inR,
                                child: Transform.scale(
                                  scale: botPop,
                                  child: _card(botAvatarW, name,
                                      botLocked ? v.accent : Colors.white38),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 1; i <= 15; i++)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Transform.translate(
                                  offset: Offset(
                                      0, -6 * max(0.0, sin(t * 16 - i * 0.6))),
                                  child: Transform.scale(
                                    scale: _p(t, 0.12 + i * 0.02,
                                            0.28 + i * 0.02, Curves.easeOutBack)
                                        .clamp(0.0, 1.3)
                                        .toDouble(),
                                    child: _BallIcon(i, 26),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text('Ketuk untuk lewati',
                            style:
                                TextStyle(fontSize: 11, color: Colors.white38)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ======================================================================
// BINGKAI AVATAR + RODA BIDIK
// ======================================================================
class _Framed extends StatefulWidget {
  final AvatarBorder border;
  final double size;
  final bool square;
  final Widget child;
  const _Framed(
      {required this.border,
      required this.size,
      required this.child,
      this.square = false});

  @override
  State<_Framed> createState() => _FramedState();
}

class _FramedState extends State<_Framed> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));
    GameSettings.i.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(covariant _Framed old) {
    super.didUpdateWidget(old);
    _sync();
  }

  // Efek hanya bergerak bila border punya efek & grafik "efek" aktif.
  void _sync() {
    final want = widget.border.fx != BorderFx.none && GameSettings.i.effects;
    if (want) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      if (_c.isAnimating) _c.stop();
      _c.value = 0.35; // bingkai diam
    }
  }

  @override
  void dispose() {
    GameSettings.i.removeListener(_sync);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.border;
    final size = widget.size;
    final square = widget.square;
    final w = b.width;
    final inR = size * 0.22;
    final inner = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(inR) : null,
      ),
      child: widget.child,
    );
    Widget core = inner;
    if (b.twin) {
      core = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: square ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: square ? BorderRadius.circular(inR + 2) : null,
          color: const Color(0xFF07122A),
        ),
        child: inner,
      );
    }
    final glowColor =
        b.fx == BorderFx.fire ? b.fx3[1] : b.colors[b.colors.length > 1 ? 1 : 0];
    final ring = Container(
      padding: EdgeInsets.all(w),
      decoration: BoxDecoration(
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius:
            square ? BorderRadius.circular(inR + w + (b.twin ? 2 : 0)) : null,
        gradient: SweepGradient(colors: [...b.colors, b.colors.first]),
        boxShadow: (b.glow || b.fx == BorderFx.fire)
            ? [
                BoxShadow(
                    color: glowColor.withAlpha(150),
                    blurRadius: size * 0.25,
                    spreadRadius: 0.5)
              ]
            : null,
      ),
      child: core,
    );
    if (b.fx == BorderFx.none) return ring;

    final pad = size * 0.6;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // efek di belakang & di luar ring (api, listrik, bintang)
        Positioned(
          left: -pad,
          top: -pad,
          right: -pad,
          bottom: -pad,
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _FxPainter(
                    b: b, size: size, square: square, anim: _c),
              ),
            ),
          ),
        ),
        ring,
        // kilau yang berputar di atas ring
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter:
                  _ShinePainter(b: b, size: size, square: square, anim: _c),
            ),
          ),
        ),
      ],
    );
  }
}

double _fxHash(int i, int salt) {
  final x = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

class _FxPt {
  final Offset p, n, t; // posisi, normal keluar, tangen
  const _FxPt(this.p, this.n, this.t);
}

// Jalur melingkar (lingkaran / kotak tumpul) untuk menaruh efek di keliling ring.
class _RingGeo {
  final Offset c;
  late final Path path;
  late final ui.PathMetric _m;
  late final double len;
  _RingGeo(this.c, double half, double corner, bool square) {
    final r = Rect.fromCircle(center: c, radius: half);
    path = Path();
    if (square) {
      path.addRRect(RRect.fromRectAndRadius(r, Radius.circular(corner)));
    } else {
      path.addOval(r);
    }
    _m = path.computeMetrics().first;
    len = _m.length;
  }

  _FxPt at(double u) {
    final f = u - u.floorToDouble();
    final tg = _m.getTangentForOffset(f * len)!;
    var t = tg.vector;
    final d = t.distance;
    t = d == 0 ? const Offset(1, 0) : t / d;
    var n = Offset(t.dy, -t.dx);
    final out = (tg.position.dx - c.dx) * n.dx + (tg.position.dy - c.dy) * n.dy;
    if (out < 0) n = -n;
    return _FxPt(tg.position, n, t);
  }
}

class _FxPainter extends CustomPainter {
  final AvatarBorder b;
  final double size;
  final bool square;
  final Animation<double> anim;
  _FxPainter(
      {required this.b,
      required this.size,
      required this.square,
      required this.anim})
      : super(repaint: anim);

  _RingGeo? _g;

  @override
  void paint(Canvas canvas, Size sz) {
    final c = Offset(sz.width / 2, sz.height / 2);
    // titik pangkal efek: sedikit menyelip di bawah ring
    final half = size / 2 + (b.twin ? 2 : 0) + b.width * 0.4;
    final corner = size * 0.22 + (b.twin ? 2 : 0) + b.width * 0.4;
    final g = _g ??= _RingGeo(c, half, corner, square);
    final t = anim.value;
    switch (b.fx) {
      case BorderFx.fire:
        _fire(canvas, g, t);
        break;
      case BorderFx.electric:
        _electric(canvas, g, t);
        break;
      case BorderFx.sparkle:
        _sparkle(canvas, g, t);
        break;
      case BorderFx.shine:
      case BorderFx.none:
        break;
    }
  }

  // ---------------- API 2D ----------------
  void _fire(Canvas canvas, _RingGeo g, double t) {
    final cols = b.fx3;
    final n = (size / 2.8).round().clamp(12, 30).toInt();
    final wBase = g.len / n * 1.2;
    final maxH = size * 0.34 * b.fxPower;
    final paint = Paint()..style = PaintingStyle.fill;
    const hsL = [1.0, 0.68, 0.38];
    const wsL = [1.0, 0.72, 0.42];
    const alL = [205, 232, 248];
    for (var layer = 0; layer < 3; layer++) {
      paint.color = cols[layer].withAlpha(alL[layer]);
      for (var i = 0; i < n; i++) {
        final pt = g.at(i / n);
        final ph = _fxHash(i, 1);
        final k = 3 + (i * 7 + 2) % 5; // 3..7 kedipan per putaran
        final f1 = 0.5 + 0.5 * sin(2 * pi * (k * t + ph));
        final wave = 0.5 + 0.5 * sin(2 * pi * (3 * (i / n) - t));
        final h = maxH *
            (0.35 + 0.65 * (0.55 * f1 + 0.45 * wave)) *
            hsL[layer] *
            (0.8 + 0.4 * _fxHash(i, 2));
        final sway = sin(2 * pi * ((k - 1) * t + ph * 3)) * h * 0.28;
        final hw = wBase * wsL[layer] * 0.5;
        final bl = pt.p - pt.t * hw;
        final br = pt.p + pt.t * hw;
        final tip = pt.p + pt.n * h + pt.t * sway;
        final c1 = bl + pt.n * (h * 0.55) + pt.t * (sway * 0.2 - hw * 0.15);
        final c2 = br + pt.n * (h * 0.55) + pt.t * (sway * 0.2 + hw * 0.15);
        final path = Path()
          ..moveTo(bl.dx, bl.dy)
          ..quadraticBezierTo(c1.dx, c1.dy, tip.dx, tip.dy)
          ..quadraticBezierTo(c2.dx, c2.dy, br.dx, br.dy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
    // percikan bara yang naik & memudar
    final m = size >= 40 ? 9 : 4;
    for (var j = 0; j < m; j++) {
      final k = 1 + (j % 2);
      final life = (t * k + _fxHash(j, 3)) % 1.0;
      final pt = g.at(_fxHash(j, 4));
      final dist = life * maxH * 1.4;
      final drift = sin(2 * pi * (life + _fxHash(j, 5))) * size * 0.05;
      final pos = pt.p + pt.n * dist + pt.t * drift;
      final r = (1 - life) * size * 0.035 + 0.5;
      final a = pow(1 - life, 1.2).toDouble();
      paint.color = Color.lerp(cols[2], cols[0], life)!
          .withAlpha((255 * a).round().clamp(0, 255).toInt());
      canvas.drawCircle(pos, r, paint);
    }
  }

  // ---------------- LISTRIK 2D ----------------
  void _electric(Canvas canvas, _RingGeo g, double t) {
    final cols = b.fx3;
    final step = (t * 24).floor();
    final pulse = 0.5 + 0.5 * sin(2 * pi * 2 * t);
    // denyut cahaya tipis di sekeliling ring
    canvas.drawPath(
        g.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.09
          ..color = cols[0].withAlpha((40 + 60 * pulse).round()));
    final glowP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = max(2.0, size * 0.08)
      ..color = cols[0].withAlpha(110);
    if (size >= 36) {
      glowP.maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.04);
    }
    final midP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = max(1.2, size * 0.04)
      ..color = cols[1].withAlpha(210);
    final coreP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = max(0.8, size * 0.02)
      ..color = cols[2];
    for (var a = 0; a < 4; a++) {
      final r = Random(step * 17 + a * 101);
      if (r.nextDouble() < 0.25) continue; // kadang padam = berkedip
      final start = r.nextDouble();
      final span = 0.12 + r.nextDouble() * 0.16;
      const seg = 9;
      final path = Path();
      for (var s = 0; s <= seg; s++) {
        final pt = g.at(start + span * s / seg);
        final off =
            (s == 0 || s == seg) ? 0.0 : (0.02 + r.nextDouble() * 0.16) * size;
        final side = (r.nextDouble() - 0.5) * size * 0.06;
        final p = pt.p + pt.n * off + pt.t * side;
        if (s == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, glowP);
      canvas.drawPath(path, midP);
      canvas.drawPath(path, coreP);
    }
  }

  // ---------------- BINTANG BERKILAU 2D ----------------
  void _sparkle(Canvas canvas, _RingGeo g, double t) {
    final cols = b.fx3;
    final m = size >= 40 ? 7 : 4;
    final fill = Paint()..style = PaintingStyle.fill;
    for (var j = 0; j < m; j++) {
      final k = 1 + (j % 2);
      final life = (t * k + _fxHash(j, 7)) % 1.0;
      final s = pow(sin(pi * life), 2).toDouble();
      if (s < 0.02) continue;
      final pt = g.at(_fxHash(j, 8));
      final pos = pt.p + pt.n * (size * (0.02 + 0.12 * _fxHash(j, 9)));
      final l = size * (0.10 + 0.08 * _fxHash(j, 10)) * s;
      fill.color = cols[1].withAlpha(150);
      canvas.drawPath(_star(pos, l * 1.35), fill);
      fill.color = cols[2];
      canvas.drawPath(_star(pos, l), fill);
    }
  }

  Path _star(Offset c, double l) {
    final i = l * 0.22;
    return Path()
      ..moveTo(c.dx, c.dy - l)
      ..lineTo(c.dx + i, c.dy - i)
      ..lineTo(c.dx + l, c.dy)
      ..lineTo(c.dx + i, c.dy + i)
      ..lineTo(c.dx, c.dy + l)
      ..lineTo(c.dx - i, c.dy + i)
      ..lineTo(c.dx - l, c.dy)
      ..lineTo(c.dx - i, c.dy - i)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _FxPainter old) =>
      old.b.id != b.id || old.size != size || old.square != square;
}

// Kilau putih yang berputar di atas ring border.
class _ShinePainter extends CustomPainter {
  final AvatarBorder b;
  final double size;
  final bool square;
  final Animation<double> anim;
  _ShinePainter(
      {required this.b,
      required this.size,
      required this.square,
      required this.anim})
      : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size sz) {
    final c = Offset(sz.width / 2, sz.height / 2);
    final tw = b.twin ? 2.0 : 0.0;
    final half = size / 2 + tw + b.width / 2;
    final corner = size * 0.22 + tw + b.width / 2;
    final r = Rect.fromCircle(center: c, radius: half);
    final path = Path();
    if (square) {
      path.addRRect(RRect.fromRectAndRadius(r, Radius.circular(corner)));
    } else {
      path.addOval(r);
    }
    final a1 = b.fx == BorderFx.shine ? 235 : 150;
    final shader = SweepGradient(
      colors: [
        const Color(0x00FFFFFF),
        Color.fromARGB(a1, 255, 255, 255),
        const Color(0x00FFFFFF),
        const Color(0x00FFFFFF),
      ],
      stops: const [0.0, 0.07, 0.15, 1.0],
      transform: GradientRotation(2 * pi * anim.value),
    ).createShader(Rect.fromCircle(center: c, radius: half + b.width));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = b.width
          ..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _ShinePainter old) =>
      old.b.id != b.id || old.size != size || old.square != square;
}

class AimWheel extends StatefulWidget {
  final Game game;
  final bool enabled;
  final Color accent;
  const AimWheel(
      {super.key,
      required this.game,
      required this.enabled,
      required this.accent});
  @override
  State<AimWheel> createState() => _AimWheelState();
}

class _AimWheelState extends State<AimWheel> {
  double _rot = 0;
  Offset? _last;

  double _ang(Offset p, double size) =>
      atan2(p.dy - size / 2, p.dx - size / 2);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      final s = box.biggest.shortestSide;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _last = d.localPosition,
        onPanUpdate: (d) {
          final l = _last;
          _last = d.localPosition;
          if (l == null || !widget.enabled) return;
          var da = _ang(d.localPosition, s) - _ang(l, s);
          while (da > pi) {
            da -= 2 * pi;
          }
          while (da < -pi) {
            da += 2 * pi;
          }
          setState(() => _rot += da);
          widget.game.nudgeAngle(da * GameSettings.i.wheelSens * 0.1);
        },
        onPanEnd: (_) => _last = null,
        child: CustomPaint(
            size: Size(s, s),
            painter: _WheelPainter(_rot, widget.accent, widget.enabled)),
      );
    });
  }
}

class _WheelPainter extends CustomPainter {
  final double rot;
  final Color accent;
  final bool on;
  _WheelPainter(this.rot, this.accent, this.on);

  @override
  void paint(Canvas c, Size s) {
    final r = s.shortestSide / 2;
    final o = Offset(s.width / 2, s.height / 2);
    c.drawCircle(
        o,
        r,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0xFF223052), Color(0xFF0A1022)])
              .createShader(Rect.fromCircle(center: o, radius: r)));
    c.drawCircle(
        o,
        r - 1.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = on ? accent : Colors.white24);
    final soft = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = Colors.white.withAlpha(on ? 190 : 70);
    final strong = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = on ? accent : Colors.white38;
    for (var i = 0; i < 24; i++) {
      final a = rot + i * 2 * pi / 24;
      final long = i % 6 == 0;
      final d = Offset(cos(a), sin(a));
      c.drawLine(o + d * (r - 9), o + d * (r - (long ? 24 : 16)),
          long ? strong : soft);
    }
    // penunjuk tetap di atas
    c.drawPath(
        Path()
          ..moveTo(o.dx, 4)
          ..lineTo(o.dx - 6, -4 + 14)
          ..lineTo(o.dx + 6, -4 + 14)
          ..close(),
        Paint()..color = on ? accent : Colors.white38);
    final t = TextPainter(
      text: TextSpan(
          text: 'BIDIK',
          style: TextStyle(
              color: Colors.white.withAlpha(on ? 220 : 90),
              fontSize: r * 0.22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, o - Offset(t.width / 2, t.height / 2));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) =>
      old.rot != rot || old.on != on || old.accent != accent;
}

// ======================================================================
// SETELAN
// ======================================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _sec(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFACC15))),
      );

  Widget _sw(String title, String sub, bool v, ValueChanged<bool> on) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(sub,
          style: const TextStyle(fontSize: 11, color: Colors.white60)),
      value: v,
      onChanged: on,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
      backgroundColor: const Color(0xFF07122A),
      appBar: AppBar(
          title: const Text('Setelan'),
          backgroundColor: const Color(0xFF050B1A),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFACC15),
            labelColor: Color(0xFFFACC15),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'Setelan'),
              Tab(text: 'History update'),
              Tab(text: 'Kontak CS'),
            ],
          )),
      body: TabBarView(children: [
        SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([GameSettings.i, ProfileStore.i]),
          builder: (ctx, _) {
            final s = GameSettings.i;
            final p = ProfileStore.i;
            final q = s.quality;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _Panel(
                          child: Row(
                            children: [
                              _Avatar(
                                  index: p.avatar,
                                  size: 44,
                                  frame: p.borderId),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.isNew ? 'Pemain' : p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900)),
                                    Text('Level ${p.level}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white60)),
                                  ],
                                ),
                              ),
                              FilledButton.tonal(
                                  onPressed: () => showProfileEditor(ctx),
                                  child: const Text('Ubah profil')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sec('RODA BIDIK'),
                              _sw(
                                  'Tampilkan roda bidik',
                                  'Putar roda di sisi kanan layar untuk menggeser bidikan dengan halus.',
                                  s.aimWheel,
                                  (v) => s.update(aimWheel: v)),
                              Row(
                                children: [
                                  const Text('Halus',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white60)),
                                  Expanded(
                                    child: Slider(
                                      value: s.wheelSens,
                                      min: 0.1,
                                      max: 1.0,
                                      divisions: 9,
                                      label: s.wheelSens.toStringAsFixed(1),
                                      onChanged: s.aimWheel
                                          ? (v) => s.update(wheelSens: v)
                                          : null,
                                    ),
                                  ),
                                  const Text('Cepat',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white60)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sec('GRAFIK'),
                          SegmentedButton<int>(
                            showSelectedIcon: false,
                            emptySelectionAllowed: true,
                            segments: const [
                              ButtonSegment(value: 0, label: Text('Rendah')),
                              ButtonSegment(value: 1, label: Text('Sedang')),
                              ButtonSegment(value: 2, label: Text('Tinggi')),
                            ],
                            selected: q >= 0 ? {q} : <int>{},
                            onSelectionChanged: (v) {
                              if (v.isNotEmpty) s.setQuality(v.first);
                            },
                          ),
                          if (q < 0)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text('Pengaturan kustom',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white60)),
                            ),
                          const SizedBox(height: 6),
                          _sw('Motif kain meja', 'Pola dan nama arena di meja',
                              s.pattern, (v) => s.update(pattern: v)),
                          _sw('Bayangan', 'Bayangan bola dan bingkai meja',
                              s.shadows, (v) => s.update(shadows: v)),
                          _sw('Kilau bola', 'Titik cahaya pada bola',
                              s.shine, (v) => s.update(shine: v)),
                          _sw('Efek partikel', 'Contoh: sakura jatuh di Osaka',
                              s.effects, (v) => s.update(effects: v)),
                          _sw('Batasi 30 FPS', 'Hemat baterai, HP tidak cepat panas',
                              s.fps30, (v) => s.update(fps30: v)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
        const _HistoryTab(),
        const _ContactTab(),
      ]),
    ));
  }
}

class _HistEntry {
  final String version, date;
  final List<String> items;
  const _HistEntry(this.version, this.date, this.items);
}

const List<_HistEntry> kHistory = [
  _HistEntry('2.5.2', '17 Okt 2026', [
    'Mesin render dibuat lebih kompatibel agar tidak macet di logo pada HP tertentu',
  ]),
  _HistEntry('2.5.1', '17 Okt 2026', [
    'Startup lebih tahan error: tiap langkah awal diberi batas waktu',
    'Masalah saat membuka game ditampilkan kecil di layar logo',
  ]),
  _HistEntry('2.5.0', '17 Okt 2026', [
    'Cue lawan sekarang punya skin, makin mahal arena makin keren cue-nya',
    'Animasi dan suara saat kalah dibuat lebih halus',
    'Tab History update dan Kontak CS di Setelan',
  ]),
  _HistEntry('2.4.0', '17 Okt 2026', [
    'Mod Upgrade Level dan Freeze Lawan lewat Bloader',
    'Mod hanya berjalan saat Bloader diaktifkan, tidak lagi menyala sendiri',
  ]),
  _HistEntry('2.3.0', '16 Okt 2026', [
    'Pemain bot makin mahal arena makin bagus border dan foto profilnya',
    'Nama bot lebih wajar dan berbeda tiap pertandingan',
    'Layar tidak mati saat game ditinggal',
  ]),
  _HistEntry('2.2.0 dan sebelumnya', '', [
    '14 arena dengan taruhan berbeda',
    'Hadiah harian dan misi',
    '10 avatar dan border api 2D',
    'Roda bidik untuk geser bidikan halus',
  ]),
];

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final h in kHistory) ...[
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('v${h.version}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFACC15))),
                    const Spacer(),
                    if (h.date.isNotEmpty)
                      Text(h.date,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white60)),
                  ],
                ),
                const SizedBox(height: 8),
                for (final it in h.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ',
                            style: TextStyle(color: Colors.white60)),
                        Expanded(
                            child: Text(it,
                                style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ContactTab extends StatelessWidget {
  const _ContactTab();

  void _copy(BuildContext ctx, String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1400), content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const handle = '@villiard8pool.off';
    const link = 'https://www.tiktok.com/@villiard8pool.off';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('KONTAK CS',
                  style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFACC15))),
              const SizedBox(height: 10),
              const Text(
                  'Ada kendala atau pertanyaan? Hubungi CS Villiard lewat TikTok.',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1B3C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1D2C52)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TikTok',
                        style: TextStyle(fontSize: 12, color: Colors.white60)),
                    SizedBox(height: 2),
                    SelectableText(handle,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _copy(context, handle, 'Username disalin'),
                      child: const Text('Salin username'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _copy(context, link, 'Link TikTok disalin'),
                      child: const Text('Salin link'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// HADIAH HARIAN (layar)
// ======================================================================
class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({super.key});
  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen> {
  bool _busy = false;

  Future<void> _claim() async {
    if (_busy) return;
    setState(() => _busy = true);
    final amt = await DailyStore.i.claim();
    if (!mounted) return;
    setState(() => _busy = false);
    if (amt > 0) {
      Sfx.coins();
      _toast(context, 'Hadiah harian diterima: +${rp(amt)}');
    }
  }

  Widget _card(int day, int done, int next) {
    final claimed = day <= done;
    final today = day == next;
    final big = day == 7;
    final amt = DailyStore.rewards[day - 1];
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: today
                ? [const Color(0xFFFFC53D), const Color(0xFFEA8A00)]
                : claimed
                    ? [const Color(0xFF14532D), const Color(0xFF052E16)]
                    : [const Color(0xFF16233F), const Color(0xFF0B1427)],
          ),
          border: Border.all(
              color: today ? Colors.white : Colors.white12,
              width: today ? 2.5 : 1),
          boxShadow: today
              ? [
                  BoxShadow(
                      color: const Color(0xFFFFC53D).withAlpha(120),
                      blurRadius: 14)
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hari $day',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: today ? Colors.black87 : Colors.white70)),
            const SizedBox(height: 8),
            Text(claimed ? '✅' : (big ? '🎁' : '🪙'),
                style: TextStyle(fontSize: big ? 34 : 28)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(rp(amt),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: today ? Colors.black87 : const Color(0xFFFACC15))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07122A),
      appBar: AppBar(
        title: const Text('Hadiah Harian'),
        backgroundColor: const Color(0xFF050B1A),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 12), child: _CoinPill()),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: DailyStore.i,
          builder: (ctx, _) {
            final d = DailyStore.i;
            final can = d.canClaim;
            final done = d.doneInCycle;
            final next = d.nextDay;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                      can
                          ? 'Ambil hadiah hari ke-$next!'
                          : 'Hadiah hari ini sudah diambil',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text(
                      'Masuk setiap hari tanpa putus supaya hadiahnya makin besar. Hari ke-7 paling besar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white60)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var day = 1; day <= 7; day++)
                        _card(day, done, next),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: can && !_busy ? _claim : null,
                    icon: const Icon(Icons.card_giftcard_rounded),
                    label: Text(can
                        ? 'Ambil ${rp(DailyStore.rewards[next - 1])}'
                        : 'Kembali besok'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ======================================================================
// MISI (layar)
// ======================================================================
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF07122A),
        appBar: AppBar(
          title: const Text('Misi'),
          backgroundColor: const Color(0xFF050B1A),
          actions: const [
            Padding(padding: EdgeInsets.only(right: 12), child: _CoinPill()),
          ],
          bottom: const TabBar(
              tabs: [Tab(text: 'Harian'), Tab(text: 'Utama')]),
        ),
        body: const SafeArea(
          child: TabBarView(children: [
            _MissionList(daily: true),
            _MissionList(daily: false),
          ]),
        ),
      ),
    );
  }
}

class _MissionList extends StatelessWidget {
  final bool daily;
  const _MissionList({required this.daily});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([MissionStore.i, ProfileStore.i]),
      builder: (ctx, _) {
        final list = kMissions.where((m) => m.daily == daily).toList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (daily)
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 2),
                child: Text('Misi harian direset setiap hari.',
                    style: TextStyle(fontSize: 12, color: Colors.white60)),
              ),
            for (final m in list) _MissionCard(m: m),
          ],
        );
      },
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission m;
  const _MissionCard({required this.m});

  @override
  Widget build(BuildContext context) {
    final st = MissionStore.i;
    final prog = st.progress(m);
    final done = prog >= m.target;
    final claimed = st.claimed(m);
    final shown = prog > m.target ? m.target : prog;
    final b = m.border == null ? null : borderById(m.border!);
    final hot = done && !claimed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: hot ? const Color(0xFFFACC15) : Colors.white12,
            width: hot ? 2 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900)),
                Text(m.desc,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: shown / m.target,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    color: done ? const Color(0xFF4ADE80) : const Color(0xFFFACC15),
                  ),
                ),
                const SizedBox(height: 2),
                Text('$shown/${m.target}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('🪙 ${rp(m.reward)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFACC15))),
              if (b != null)
                Text('🖼 Border ${b.name}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFA5F3FC))),
              const SizedBox(height: 6),
              if (claimed)
                const Text('Selesai ✓',
                    style: TextStyle(
                        color: Color(0xFF4ADE80), fontWeight: FontWeight.w800))
              else
                FilledButton(
                  onPressed: done
                      ? () async {
                          final ok = await st.claim(m);
                          if (ok && context.mounted) {
                            Sfx.coins();
                            _toast(
                                context,
                                'Misi selesai! +${rp(m.reward)}'
                                '${b != null ? ' + border ${b.name}' : ''}');
                          }
                        }
                      : null,
                  child: const Text('Ambil'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// KOLEKSI: BORDER AVATAR
// ======================================================================
class _BorderTab extends StatelessWidget {
  const _BorderTab();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ProfileStore.i, Wallet.coins]),
      builder: (ctx, _) {
        final p = ProfileStore.i;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 190,
              mainAxisExtent: 208,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10),
          itemCount: kBorders.length,
          itemBuilder: (_, i) => _card(ctx, p, kBorders[i]),
        );
      },
    );
  }

  Widget _card(BuildContext ctx, ProfileStore p, AvatarBorder b) {
    final owned = p.ownedBorders.contains(b.id);
    final on = p.borderId == b.id;
    Mission? ms;
    if (b.mission != null) {
      ms = kMissions.where((m) => m.id == b.mission).first;
    }

    Widget action;
    if (on) {
      action = const Text('Dipakai ✓',
          style: TextStyle(
              color: Color(0xFF4ADE80), fontWeight: FontWeight.w800));
    } else if (owned) {
      action = OutlinedButton(
          onPressed: () => p.equipBorder(b.id), child: const Text('Pakai'));
    } else if (b.price > 0) {
      final lvlOk = p.level >= b.minLevel;
      final can = lvlOk && Wallet.coins.value >= b.price;
      action = FilledButton(
        onPressed: can
            ? () async {
                final ok = await p.buyBorder(b);
                if (ctx.mounted) {
                  _toast(ctx,
                      ok ? 'Border ${b.name} dibeli' : 'Belum bisa dibeli');
                }
              }
            : null,
        child: FittedBox(
            child: Text(lvlOk ? rp(b.price) : 'Butuh level ${b.minLevel}')),
      );
    } else {
      action = OutlinedButton(
          onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const MissionsScreen())),
          child: const Text('Lihat misi'));
    }

    String caption = '';
    if (!owned) {
      if (ms != null) {
        caption = b.price > 0
            ? 'atau misi: ${ms.title}'
            : 'Misi: ${ms.title}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: on ? const Color(0xFF4ADE80) : Colors.white12,
            width: on ? 2 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
              height: 84,
              child: Center(
                  child: _Avatar(index: p.avatar, size: 52, frame: b.id))),
          Text(b.name,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          SizedBox(
            height: 28,
            child: Text(caption,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: Colors.white60)),
          ),
          SizedBox(width: double.infinity, child: Center(child: action)),
        ],
      ),
    );
  }
}

// ======================================================================
// MINIGAMES (v1.7)
// ======================================================================
const List<int> kTickets = [20000, 100000, 500000];

Widget _ticketChips(int ticket, bool enabled, ValueChanged<int> onChange) {
  return Wrap(
    spacing: 6,
    children: [
      for (final t in kTickets)
        ChoiceChip(
          label: Text(rp(t), style: const TextStyle(fontSize: 11)),
          selected: ticket == t,
          onSelected: enabled ? (_) => onChange(t) : null,
        ),
    ],
  );
}

void _toast(BuildContext context, String m) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1400), content: Text(m)));
}

class MinigamesScreen extends StatelessWidget {
  const MinigamesScreen({super.key});

  Widget _card(BuildContext ctx, String emoji, String title, String desc,
      List<Color> colors, Widget page) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.of(ctx).push(_fadeSlide<void>(page)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors),
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 54)),
              const SizedBox(height: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 10),
              const FilledButton(onPressed: null, child: Text('MAIN')),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF050B1A), Color(0xFF0A1F44)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    const Expanded(
                      child: Text('MINIGAMES',
                          style: TextStyle(
                              letterSpacing: 3,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70)),
                    ),
                    const _CoinPill(),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: Row(
                    children: [
                      _card(
                          context,
                          '🍀',
                          'LUCKY SHOOT',
                          'Tembak bola putih ke lubang. Hadiah tersembunyi di tiap lubang, sampai x5!',
                          const [Color(0xFF34D3C8), Color(0xFF0E7C86)],
                          const LuckyShootScreen()),
                      const SizedBox(width: 14),
                      _card(
                          context,
                          '🎯',
                          'POWER TIMING',
                          'Hentikan bar tepat di zona hijau. Makin tepat, makin besar hadiahnya.',
                          const [Color(0xFFFFBA4A), Color(0xFFE67700)],
                          const PowerTimingScreen()),
                    ],
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

// ---------------------------------------------------------------- LUCKY SHOOT
class LuckyShootScreen extends StatefulWidget {
  const LuckyShootScreen({super.key});
  @override
  State<LuckyShootScreen> createState() => _LuckyShootScreenState();
}

class _LuckyShootScreenState extends State<LuckyShootScreen>
    with SingleTickerProviderStateMixin {
  static const List<double> _mults = [0, 0, 0.5, 1, 2, 5];
  late final Ticker _tk;
  Duration? _last;
  final Random _rnd = Random();

  int ticket = kTickets.first;
  late List<double> prizes;
  Offset pos = const Offset(kW * 0.25, kH / 2);
  Offset vel = Offset.zero;
  bool moving = false, shot = false, revealed = false;
  int? hitPocket;
  int win = 0;
  Offset? dragFrom, dragTo;

  @override
  void initState() {
    super.initState();
    _newRound();
    _tk = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _tk.dispose();
    super.dispose();
  }

  void _newRound() {
    prizes = List<double>.from(_mults)..shuffle(_rnd);
    pos = const Offset(kW * 0.25, kH / 2);
    vel = Offset.zero;
    moving = false;
    shot = false;
    revealed = false;
    hitPocket = null;
    win = 0;
    dragFrom = null;
    dragTo = null;
  }

  double get _power {
    if (dragFrom == null || dragTo == null) return 0;
    return (min((dragFrom! - dragTo!).distance, 160) / 160).toDouble();
  }

  void _fire() {
    if (Wallet.coins.value < ticket) {
      _toast(context, 'Uang kurang untuk tiket ${rp(ticket)}');
      return;
    }
    final dir = dragFrom! - dragTo!;
    final pw = _power;
    if (pw < 0.08) return;
    Wallet.add(-ticket);
    final n = dir / dir.distance;
    vel = n * (200 + pw * 1300);
    moving = true;
    shot = true;
    Sfx.hit(0.3 + pw * 0.7);
  }

  void _tick(Duration t) {
    final dt = _last == null
        ? 0.016
        : ((t - _last!).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = t;
    if (!moving) return;
    final sp0 = vel.distance;
    final n = max(1, (sp0 * dt / 4).ceil());
    final h = dt / n;
    for (var k = 0; k < n && moving; k++) {
      pos = pos + vel * h;
      for (var i = 0; i < 6; i++) {
        if ((pos - kPockets[i]).distance < pocketRadius(i)) {
          _finish(i);
          break;
        }
      }
      if (!moving) break;
      var vx = vel.dx, vy = vel.dy, px = pos.dx, py = pos.dy;
      if (px < kR) {
        px = kR;
        vx = -vx * 0.9;
        Sfx.hit(0.35);
      } else if (px > kW - kR) {
        px = kW - kR;
        vx = -vx * 0.9;
        Sfx.hit(0.35);
      }
      if (py < kR) {
        py = kR;
        vy = -vy * 0.9;
        Sfx.hit(0.35);
      } else if (py > kH - kR) {
        py = kH - kR;
        vy = -vy * 0.9;
        Sfx.hit(0.35);
      }
      pos = Offset(px, py);
      vel = Offset(vx, vy);
      final sp = vel.distance;
      final ns = max(0.0, sp - 600 * h);
      vel = sp == 0 ? Offset.zero : vel * (ns / sp);
      if (ns < 8) {
        vel = Offset.zero;
        _finish(null);
      }
    }
    if (mounted) setState(() {});
  }

  void _finish(int? i) {
    moving = false;
    vel = Offset.zero;
    revealed = true;
    hitPocket = i;
    if (i != null) pos = kPockets[i];
    final m = i == null ? 0.0 : prizes[i];
    win = (ticket * m).round();
    if (win > 0) {
      Wallet.add(win);
      Sfx.coins();
    }
  }

  @override
  Widget build(BuildContext context) {
    final venue = kVenues[1];
    final String msg;
    if (!shot) {
      msg = 'Tarik ke belakang lalu lepas untuk menembak';
    } else if (moving) {
      msg = 'Bola meluncur...';
    } else if (hitPocket == null) {
      msg = 'Meleset! Bola berhenti di meja';
    } else if (win > 0) {
      msg = 'Menang ${rp(win)} (x${mx(prizes[hitPocket!])})';
    } else {
      msg = 'Zonk! Coba lagi';
    }
    return Scaffold(
      body: Container(
        color: const Color(0xFF050B1A),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    const Expanded(
                      child: Text('🍀 LUCKY SHOOT',
                          style: TextStyle(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70)),
                    ),
                    const _CoinPill(),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(builder: (ctx, cs) {
                  final xf = TableXf.of(Size(cs.maxWidth, cs.maxHeight));
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) {
                      if (shot) return;
                      dragFrom = xf.toTable(d.localPosition);
                      dragTo = dragFrom;
                      setState(() {});
                    },
                    onPanUpdate: (d) {
                      if (shot || dragFrom == null) return;
                      dragTo = xf.toTable(d.localPosition);
                      setState(() {});
                    },
                    onPanEnd: (_) {
                      if (shot || dragFrom == null) return;
                      _fire();
                      if (!shot) {
                        dragFrom = null;
                        dragTo = null;
                      }
                      setState(() {});
                    },
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _LuckyPainter(
                          venue: venue,
                          xf: xf,
                          pos: pos,
                          prizes: prizes,
                          revealed: revealed,
                          hit: hitPocket,
                          aim: (!shot && dragFrom != null)
                              ? (dragFrom! - dragTo!)
                              : null,
                          power: _power),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                child: Row(
                  children: [
                    _ticketChips(ticket, !shot, (t) => setState(() => ticket = t)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(msg,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: win > 0
                                  ? const Color(0xFFFACC15)
                                  : Colors.white70)),
                    ),
                    FilledButton(
                      onPressed:
                          revealed ? () => setState(_newRound) : null,
                      child: const Text('Main Lagi'),
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

void _drawLabel(Canvas c, String s, Offset center, double size, Color col) {
  final tp = TextPainter(
    text: TextSpan(
        text: s,
        style: TextStyle(
            color: col,
            fontSize: size,
            fontWeight: FontWeight.w900,
            shadows: const [Shadow(color: Colors.black, blurRadius: 3)])),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

class _LuckyPainter extends CustomPainter {
  final Venue venue;
  final TableXf xf;
  final Offset pos;
  final List<double> prizes;
  final bool revealed;
  final int? hit;
  final Offset? aim;
  final double power;
  _LuckyPainter(
      {required this.venue,
      required this.xf,
      required this.pos,
      required this.prizes,
      required this.revealed,
      required this.hit,
      required this.aim,
      required this.power});

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.translate(xf.ox, xf.oy);
    c.scale(xf.s);
    c.translate(kRail, kRail);
    drawTableBase(c, venue, watermark: false);

    // label hadiah di tiap lubang
    for (var i = 0; i < 6; i++) {
      final p = kPockets[i];
      final inward = Offset(kW / 2 - p.dx, kH / 2 - p.dy);
      final d = inward / inward.distance;
      final at = p + d * 52;
      final m = prizes[i];
      final txt = revealed ? (m == 0 ? 'ZONK' : 'x${mx(m)}') : '?';
      final col = !revealed
          ? Colors.white
          : (m == 0
              ? Colors.redAccent
              : (m >= 5 ? const Color(0xFFFACC15) : Colors.greenAccent));
      if (hit == i) {
        c.drawCircle(p, pocketRadius(i) + 8,
            Paint()..color = const Color(0x66FACC15));
      }
      _drawLabel(c, txt, at, hit == i ? 30 : 22, col);
    }

    // garis bidik
    if (aim != null && aim!.distance > 4) {
      final n = aim! / aim!.distance;
      final len = 60 + power * 240;
      final lp = Paint()
        ..color = Color.lerp(Colors.greenAccent, Colors.redAccent, power)!
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var d = 14.0; d < len; d += 18) {
        c.drawLine(pos + n * d, pos + n * (d + 9), lp);
      }
    }

    // bola putih
    if (hit == null) {
      c.drawCircle(pos + const Offset(2, 3), kR,
          Paint()..color = Colors.black38);
      c.drawCircle(
          pos,
          kR,
          Paint()
            ..shader = const RadialGradient(
                    center: Alignment(-0.4, -0.4),
                    colors: [Colors.white, Color(0xFFBDBDBD)])
                .createShader(Rect.fromCircle(center: pos, radius: kR)));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _LuckyPainter old) => true;
}

// --------------------------------------------------------------- POWER TIMING
class PowerTimingScreen extends StatefulWidget {
  const PowerTimingScreen({super.key});
  @override
  State<PowerTimingScreen> createState() => _PowerTimingScreenState();
}

class _PowerTimingScreenState extends State<PowerTimingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));
  int ticket = kTickets.first;
  bool running = false;
  String result = 'Tekan MULAI lalu STOP di zona hijau';
  int win = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _start() {
    if (Wallet.coins.value < ticket) {
      _toast(context, 'Uang kurang untuk tiket ${rp(ticket)}');
      return;
    }
    Wallet.add(-ticket);
    win = 0;
    result = 'STOP sekarang!';
    running = true;
    _c.repeat(reverse: true);
    setState(() {});
  }

  void _stop() {
    _c.stop();
    final d = (_c.value - 0.5).abs();
    double m;
    String label;
    if (d < 0.03) {
      m = 8;
      label = 'PERFECT!';
    } else if (d < 0.08) {
      m = 3;
      label = 'Bagus!';
    } else if (d < 0.15) {
      m = 1.5;
      label = 'Lumayan';
    } else {
      m = 0;
      label = 'Meleset';
    }
    win = (ticket * m).round();
    if (win > 0) {
      Wallet.add(win);
      Sfx.coins();
      result = '$label  +${rp(win)} (x${mx(m)})';
    } else {
      result = '$label  Coba lagi';
    }
    running = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF050B1A), Color(0xFF0A1F44)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    const Expanded(
                      child: Text('🎯 POWER TIMING',
                          style: TextStyle(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70)),
                    ),
                    const _CoinPill(),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(result,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: win > 0
                                    ? const Color(0xFFFACC15)
                                    : Colors.white)),
                        const SizedBox(height: 18),
                        LayoutBuilder(builder: (ctx, cs) {
                          final w = cs.maxWidth;
                          return SizedBox(
                            height: 44,
                            child: AnimatedBuilder(
                              animation: _c,
                              builder: (_, __) => Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFFB91C1C),
                                        Color(0xFFF59E0B),
                                        Color(0xFF16A34A),
                                        Color(0xFFF59E0B),
                                        Color(0xFFB91C1C)
                                      ]),
                                      border: Border.all(
                                          color: Colors.white54, width: 2),
                                    ),
                                  ),
                                  Positioned(
                                    left: (w - 8) * _c.value,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                        width: 8,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4))),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 18),
                        _ticketChips(ticket, !running,
                            (t) => setState(() => ticket = t)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 220,
                          height: 48,
                          child: FilledButton(
                            onPressed: running ? _stop : _start,
                            child: Text(running ? 'STOP' : 'MULAI',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
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
