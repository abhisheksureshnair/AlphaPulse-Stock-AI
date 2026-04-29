import 'package:flutter/material.dart';
import 'package:alpha_pulse/services/api_service.dart';
import 'package:alpha_pulse/theme.dart';

class AIInvestorScreen extends StatefulWidget {
  const AIInvestorScreen({super.key});

  @override
  State<AIInvestorScreen> createState() => _AIInvestorScreenState();
}

class _AIInvestorScreenState extends State<AIInvestorScreen> {
  final TextEditingController _budgetController = TextEditingController();
  String _selectedStrategy = 'Aggressive';
  Map<String, dynamic>? _recommendation;
  bool _isLoading = false;
  bool _explainSimple = false;
  String? _error;

  final List<String> _strategies = ['Conservative', 'Aggressive', 'Long-term'];

  Future<void> _getRecommendation() async {
    final budget = double.tryParse(_budgetController.text);
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _recommendation = null;
    });

    try {
      final result = await ApiService.fetchRecommendation(
        budget, 
        strategy: _selectedStrategy.toLowerCase().replaceAll('-', '_'),
        explainSimple: _explainSimple,
      );
      setState(() {
        _recommendation = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Budget Investor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSection(),
            const SizedBox(height: 30),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
            else if (_error != null)
              ErrorView(
                message: _error!,
                onRetry: _getRecommendation,
              )
            else if (_recommendation != null)
              _buildRecommendationDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your investment budget',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: AppColors.neonGreen, fontSize: 24),
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonGreen)),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'SELECT STRATEGY',
            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BEGINNER MODE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Simple, jargon-free explanations', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              Switch(
                value: _explainSimple,
                onChanged: (val) => setState(() => _explainSimple = val),
                activeColor: AppColors.neonGreen,
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _getRecommendation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Get AI Recommendation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.electricRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.electricRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.electricRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.electricRed, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationDisplay() {
    final bullish = _recommendation!['bullish'] ?? {};
    final bearish = _recommendation!['bearish'] ?? {};
    final quant = _recommendation!['quant'] ?? {};
    final verdict = _recommendation!['final'] ?? {};

    final symbol = verdict['stock'] ?? 'N/A';
    final decision = verdict['final_decision'] ?? 'BUY';
    final quantity = verdict['quantity'] ?? 0;
    final price = verdict['price'] ?? 0.0;
    final finalReasoning = verdict['final_reasoning'] ?? '';
    final riskLevel = verdict['risk_level'] ?? 'MEDIUM';
    final confidence = verdict['confidence'] ?? 0;
    final agreementScore = verdict['agreement_score'] ?? 0.0;
    final warning = verdict['warning'];

    Color riskColor;
    switch (riskLevel.toUpperCase()) {
      case 'LOW': riskColor = AppColors.neonGreen; break;
      case 'HIGH': riskColor = AppColors.electricRed; break;
      default: riskColor = Colors.orangeAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.psychology, color: Colors.purpleAccent, size: 24),
            SizedBox(width: 10),
            Text(
              'PROFESSIONAL HEDGE FUND PROTOCOL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Analyst Debate Feed
        _buildDebateCard(
          title: 'BULLISH ANALYST',
          icon: Icons.trending_up,
          color: AppColors.neonGreen,
          decision: bullish['decision'] ?? 'BUY',
          confidence: bullish['confidence'] ?? 0,
          content: bullish['reasoning'] ?? '',
        ),
        const SizedBox(height: 12),
        _buildDebateCard(
          title: 'BEARISH ANALYST',
          icon: Icons.trending_down,
          color: AppColors.electricRed,
          decision: bearish['decision'] ?? 'SELL',
          confidence: bearish['confidence'] ?? 0,
          content: bearish['reasoning'] ?? '',
        ),
        const SizedBox(height: 12),
        _buildDebateCard(
          title: 'QUANTITATIVE ANALYST',
          icon: Icons.analytics,
          color: Colors.blueAccent,
          decision: quant['decision'] ?? 'HOLD',
          confidence: quant['confidence'] ?? 0,
          content: quant['reasoning'] ?? '',
        ),
        
        const SizedBox(height: 40),
        
        // Agreement Indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Text(
                'CONSENSUS SCORE: ${(agreementScore * 100).toInt()}%',
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: agreementScore,
                  backgroundColor: Colors.white10,
                  color: agreementScore > 0.6 ? AppColors.neonGreen : (agreementScore < 0.4 ? AppColors.electricRed : Colors.orangeAccent),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),

        // Final Verdict Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.neonGreen.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonGreen.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStrategyBadge(_selectedStrategy),
                  _buildRiskBadge(riskLevel, riskColor),
                ],
              ),
              const SizedBox(height: 20),
              if (warning != null && warning.isNotEmpty)
                _buildWarningBanner(warning),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EXECUTIVE VERDICT', style: TextStyle(color: AppColors.mutedGrey, fontSize: 10)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(symbol, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 12),
                          _buildActionBadge(decision),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatTile('QUANTITY', '$quantity Shares'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatTile('CONFIDENCE', '$confidence%', crossAxisAlignment: CrossAxisAlignment.end),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        child: LinearProgressIndicator(
                          value: confidence / 100,
                          backgroundColor: Colors.white10,
                          color: AppColors.neonGreen,
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Divider(color: Colors.white12),
              const SizedBox(height: 20),
              const Text('MANAGER\'S FINAL REASONING', style: TextStyle(color: AppColors.mutedGrey, fontSize: 10, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Text(
                finalReasoning,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 25),
              Text(
                'Layout: \$${(quantity * price).toStringAsFixed(2)} at \$${price.toStringAsFixed(2)}/share',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildWarningBanner(String warning) {
    return Container(
      margin: const EdgeInsets.bottom(20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.electricRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.electricRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.electricRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              warning,
              style: const TextStyle(color: AppColors.electricRed, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebateCard({
    required String title, 
    required IconData icon, 
    required Color color, 
    required String decision,
    required int confidence,
    required String content
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ],
              ),
              Text(
                '$decision ($confidence%)',
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBadge(String decision) {
    final isBuy = decision.contains('BUY');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isBuy ? AppColors.neonGreen.withOpacity(0.2) : AppColors.electricRed.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        decision,
        style: TextStyle(
          color: isBuy ? AppColors.neonGreen : AppColors.electricRed,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStrategyBadge(String strategy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        strategy.toUpperCase(),
        style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildRiskBadge(String risk, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        'RISK: $risk',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedGrey, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
