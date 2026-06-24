import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  runApp(const AgeCalculatorApp());
}

class AgeCalculatorApp extends StatelessWidget {
  const AgeCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'محاسبه‌گر سن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AgeCalculatorScreen(),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────
class AgeResult {
  final int years;
  final int months;
  final int days;
  const AgeResult(this.years, this.months, this.days);
}

// ─── Logic ────────────────────────────────────────────────────
class AgeCalculator {
  /// تبدیل تقریبی قمری به میلادی (Kuwaiti Algorithm)
  static DateTime hijriToGregorian(int y, int m, int d) {
    int jd = (11 * y + 3) ~/ 30 +
        354 * y +
        30 * m -
        (m - 1) ~/ 2 +
        d +
        1948440 -
        385;
    int l = jd + 68569;
    int n = (4 * l) ~/ 146097;
    l = l - (146097 * n + 3) ~/ 4;
    int i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    int j = (80 * l) ~/ 2447;
    int day = l - (2447 * j) ~/ 80;
    l = j ~/ 11;
    int month = j + 2 - 12 * l;
    int year = 100 * (n - 49) + i + l;
    return DateTime(year, month, day);
  }

  /// محاسبه سن از تاریخ میلادی
  static AgeResult fromGregorian(DateTime birth) {
    final now = DateTime.now();
    int years = now.year - birth.year;
    int months = now.month - birth.month;
    int days = now.day - birth.day;

    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    return AgeResult(years, months, days);
  }

  static AgeResult fromShamsi(int y, int m, int d) {
    final g = Jalali(y, m, d).toGregorian();
    return fromGregorian(DateTime(g.year, g.month, g.day));
  }

  static AgeResult fromHijri(int y, int m, int d) {
    return fromGregorian(hijriToGregorian(y, m, d));
  }

  /// تبدیل میلادی به شمسی
  static Jalali toShamsi(DateTime dt) =>
      Jalali.fromDateTime(dt);

  /// تبدیل تقریبی میلادی به قمری (سال)
  static int toHijriYear(DateTime dt) {
    double jd = 367 * dt.year -
        (7 * (dt.year + (dt.month + 9) ~/ 12)) ~/ 4 +
        (275 * dt.month) ~/ 9 +
        dt.day +
        1721013.5;
    return ((jd - 1948438.5) / 354.367).floor();
  }
}

// ─── UI ───────────────────────────────────────────────────────
class AgeCalculatorScreen extends StatefulWidget {
  const AgeCalculatorScreen({super.key});

  @override
  State<AgeCalculatorScreen> createState() => _AgeCalculatorScreenState();
}

class _AgeCalculatorScreenState extends State<AgeCalculatorScreen> {
  int _calType = 0; // 0=شمسی  1=میلادی  2=قمری
  final _yearCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();

  AgeResult? _result;
  DateTime? _birthGregorian;
  String? _error;

  void _calculate() {
    setState(() {
      _error = null;
      _result = null;
      _birthGregorian = null;
    });

    final y = int.tryParse(_yearCtrl.text.trim());
    final m = int.tryParse(_monthCtrl.text.trim());
    final d = int.tryParse(_dayCtrl.text.trim());

    if (y == null || m == null || d == null) {
      setState(() => _error = 'لطفاً سال، ماه و روز را به درستی وارد کنید.');
      return;
    }

    try {
      late AgeResult result;
      late DateTime birthG;

      if (_calType == 0) {
        final g = Jalali(y, m, d).toGregorian();
        birthG = DateTime(g.year, g.month, g.day);
        result = AgeCalculator.fromGregorian(birthG);
      } else if (_calType == 1) {
        birthG = DateTime(y, m, d);
        result = AgeCalculator.fromGregorian(birthG);
      } else {
        birthG = AgeCalculator.hijriToGregorian(y, m, d);
        result = AgeCalculator.fromGregorian(birthG);
      }

      setState(() {
        _result = result;
        _birthGregorian = birthG;
      });
    } catch (e) {
      setState(() => _error = 'تاریخ وارد شده معتبر نیست.');
    }
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: const Text(
            'محاسبه‌گر سن',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── انتخاب نوع تقویم
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('نوع تقویم تاریخ تولد:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final e in [
                            (0, 'شمسی'),
                            (1, 'میلادی'),
                            (2, 'قمری'),
                          ])
                            ChoiceChip(
                              label: Text(e.$2),
                              selected: _calType == e.$1,
                              onSelected: (_) =>
                                  setState(() => _calType = e.$1),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── ورودی تاریخ
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تاریخ تولد:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _field(_yearCtrl, 'سال', 4),
                          const SizedBox(width: 8),
                          _field(_monthCtrl, 'ماه', 2),
                          const SizedBox(width: 8),
                          _field(_dayCtrl, 'روز', 2),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── دکمه محاسبه
              FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text('محاسبه سن',
                    style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              // ── خطا
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: Colors.red.shade700)),
                ),
              ],

              // ── نتیجه
              if (_result != null && _birthGregorian != null) ...[
                const SizedBox(height: 20),
                _ResultCard(
                    result: _result!, birthGregorian: _birthGregorian!),
              ],

              const SizedBox(height: 32),

              // ── درباره
              Center(
                child: Text(
                  'First App by GolshanSoft',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, int maxLen) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        maxLength: maxLen,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
      ),
    );
  }
}

// ─── Result Card ──────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final AgeResult result;
  final DateTime birthGregorian;

  const _ResultCard({required this.result, required this.birthGregorian});

  @override
  Widget build(BuildContext context) {
    final shamsi = AgeCalculator.toShamsi(birthGregorian);
    final hijriYear = AgeCalculator.toHijriYear(birthGregorian);
    final hijriAge =
        result.years + (result.months >= 6 ? 1 : 0);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'نتیجه',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 24),
            _row('سن شمسی', '${result.years} سال و ${result.months} ماه و ${result.days} روز'),
            _row('سن میلادی', '${result.years} سال و ${result.months} ماه و ${result.days} روز'),
            _row('سن قمری (تقریبی)', '$hijriAge سال'),
            const Divider(height: 24),
            _row('تولد شمسی', '${shamsi.year}/${shamsi.month}/${shamsi.day}'),
            _row('تولد میلادی',
                '${birthGregorian.year}/${birthGregorian.month}/${birthGregorian.day}'),
            _row('تولد قمری (سال تقریبی)', '$hijriYear'),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}
