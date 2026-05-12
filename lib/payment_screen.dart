import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedPlan = 1;

  final List<Map<String, dynamic>> _plans = [
    {"period": "주간", "price": "3,900", "unit": "원 / 주", "badge": null},
    {"period": "월간", "price": "9,900", "unit": "원 / 월", "badge": "36% 절약"},
    {"period": "단건", "price": "4,900", "unit": "원 / 회", "badge": null},
  ];

  final List<String> _features = [
    "구체적 헤어컷 스타일 이름 추천",
    "시술 로드맵 (침습도 단계별)",
    "피부케어 루틴 + 제품 추천",
    "대안 추구미 + 전환 플랜",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              const Text("잠금 해제", style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
              const SizedBox(height: 4),
              const Text("맞춤 액션 플랜 전체 보기", style: TextStyle(fontSize: 18, color: Color(0xFFF0F0F0), fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),

              // 미리보기 블러
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF222222), width: 0.5),
                ),
                child: Column(
                  children: [
                    _buildPreviewRow(Icons.star, "헤어컷 추천 3가지", "투블록 레이어드 / 허쉬컷 / 울프컷"),
                    const SizedBox(height: 10),
                    _buildPreviewRow(Icons.medical_services_outlined, "시술 로드맵", "비침습 → 최소침습 → 수술 단계별"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF333333), width: 0.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: Color(0xFF888888)),
                          SizedBox(width: 6),
                          Text("프리미엄 전용 콘텐츠", style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 플랜 선택
              const Text("플랜 선택", style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_plans.length, (index) {
                  final plan = _plans[index];
                  final isSelected = _selectedPlan == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPlan = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E1900) : const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE8D5B7) : const Color(0xFF2A2A2A),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(plan["period"], style: TextStyle(fontSize: 11, color: isSelected ? const Color(0xFFA08060) : const Color(0xFF666666))),
                            const SizedBox(height: 4),
                            Text(plan["price"], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isSelected ? const Color(0xFFE8D5B7) : const Color(0xFFCCCCCC))),
                            Text(plan["unit"], style: TextStyle(fontSize: 10, color: isSelected ? const Color(0xFF7A6040) : const Color(0xFF444444))),
                            if (plan["badge"] != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFE8D5B7), borderRadius: BorderRadius.circular(4)),
                                child: Text(plan["badge"], style: const TextStyle(fontSize: 9, color: Color(0xFF1A0F00), fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // 기능 리스트
              Column(
                children: _features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 14, color: Color(0xFFE8A030)),
                      const SizedBox(width: 8),
                      Text(f, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),

              // 결제 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8D5B7),
                    foregroundColor: const Color(0xFF1A0F00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    "잠금 해제 — ${_plans[_selectedPlan]['period']} ${_plans[_selectedPlan]['price']}원",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text("7일 무료체험 · 언제든 해지 가능 · 자동 갱신", style: TextStyle(fontSize: 10, color: Color(0xFF333333))),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String title, String sub) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: const Color(0xFFE8D5B7), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: const Color(0xFF1A0F00)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC), fontWeight: FontWeight.w500)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
          ],
        ),
      ],
    );
  }
}