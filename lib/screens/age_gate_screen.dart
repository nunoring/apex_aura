import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgeGateScreen extends StatefulWidget {
  final VoidCallback onPassed;
  const AgeGateScreen({super.key, required this.onPassed});

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  DateTime? _selectedDate;
  bool _showError = false;
  bool _showBlock = false;

  Future<void> _pickDate() async {
    DateTime temp = _selectedDate ?? DateTime(2000, 1, 1);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('생년월일 선택',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, temp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8D5B7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('완료',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              SizedBox(
                height: 216,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle:
                          TextStyle(color: Colors.white, fontSize: 19),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: temp,
                    minimumDate: DateTime(1920),
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (d) => temp = d,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _showError = false;
        _showBlock = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_selectedDate == null) {
      setState(() => _showError = true);
      return;
    }

    final age = _calcAge(_selectedDate!);

    if (age < 14) {
      setState(() => _showBlock = true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('birth_date', _selectedDate!.toIso8601String());
    await prefs.setInt('user_age', age);
    await prefs.setBool('age_passed', true);
    widget.onPassed();
  }

  int _calcAge(DateTime birth) {
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    if (_showBlock) return _buildBlockScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text('생년월일을\n입력해주세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  )),
              const SizedBox(height: 12),
              const Text('만 14세 이상부터 이용 가능해요',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showError
                          ? Colors.redAccent
                          : const Color(0xFFE8D5B7).withAlpha(77),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFFE8D5B7), size: 18),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? '날짜를 선택해주세요'
                            : '${_selectedDate!.year}년 '
                                '${_selectedDate!.month}월 '
                                '${_selectedDate!.day}일',
                        style: TextStyle(
                          color: _selectedDate == null
                              ? Colors.white38
                              : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showError) ...[
                const SizedBox(height: 8),
                const Text('생년월일을 선택해주세요',
                    style:
                        TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8D5B7),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('확인',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 24),
              const Text(
                '만 14세 이상부터\n이용 가능해요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '본인 사진을 다시\n확인해주세요',
                style: TextStyle(
                    color: Colors.white54, fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () => setState(() {
                  _showBlock = false;
                  _selectedDate = null;
                }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('다시 입력하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
