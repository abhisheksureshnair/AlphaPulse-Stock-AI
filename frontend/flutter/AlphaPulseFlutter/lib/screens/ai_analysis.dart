import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:alpha_pulse/services/api_service.dart';
import 'package:alpha_pulse/theme.dart';

class AIAnalysisScreen extends StatefulWidget {
  final String ticker;

  const AIAnalysisScreen({super.key, required this.ticker});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  Map<String, dynamic>? _stockData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant AIAnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticker != widget.ticker) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchStockData(widget.ticker);
      if (!mounted) {
        return;
      }
      setState(() {
        _stockData = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.ticker} AI Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildSentimentGauge(),
                      const SizedBox(height: 30),
                      _buildInfoCards(),
                      const SizedBox(height: 30),
                      _buildMarketSummary(),
                      const SizedBox(height: 30),
                      _buildModelIntelligence(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSentimentGauge() {
    final rsi = (_stockData?['RSI'] as num?)?.toDouble() ?? 50.0;
    final percentage = 1.0 - ((rsi - 20) / 60).clamp(0.0, 1.0);
    final signal = _stockData?['signal']?.toString() ?? 'NEUTRAL';
    final signalColor = percentage > 0.7
        ? AppColors.neonGreen
        : (percentage < 0.3 ? AppColors.electricRed : AppColors.mutedGrey);

    return Column(
      children: [
        Text(
          '${widget.ticker} Analysis',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          width: 250,
          child: CustomPaint(
            painter: GaugePainter(percentage: percentage),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${(percentage * 100).toInt()}% Bullish',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: signalColor,
                      shadows: [
                        Shadow(color: signalColor, blurRadius: 10),
                      ],
                    ),
                  ),
                  Text(
                    signal,
                    style: const TextStyle(color: AppColors.mutedGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    final macd = (_stockData?['MACD'] as num?)?.toDouble() ?? 0.0;
    final price = (_stockData?['price'] as num?)?.toDouble() ?? 0.0;
    final changePercent = (_stockData?['change_percent'] as num?)?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'MACD VALUE',
            macd.toStringAsFixed(2),
            macd > 0 ? 'Bullish Trend' : 'Bearish Trend',
            macd > 0 ? AppColors.neonGreen : AppColors.electricRed,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildMetricCard(
            'PRICE',
            '\$${price.toStringAsFixed(2)}',
            '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
            changePercent >= 0 ? AppColors.neonGreen : AppColors.electricRed,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, String subLabel, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedGrey,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(subLabel, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMarketSummary() {
    final rsi = (_stockData?['RSI'] as num?)?.toDouble() ?? 50.0;
    final macd = (_stockData?['MACD'] as num?)?.toDouble() ?? 0.0;
    final signal = _stockData?['signal']?.toString() ?? 'NEUTRAL';

    String summary;
    if (rsi < 40) {
      summary =
          '${widget.ticker} is showing oversold conditions with an RSI of ${rsi.toStringAsFixed(2)}. The backend signal is $signal, which suggests a rebound setup if momentum keeps improving.';
    } else if (rsi > 60) {
      summary =
          '${widget.ticker} is approaching overbought territory with an RSI of ${rsi.toStringAsFixed(2)}. The backend currently rates it as $signal, so upside may be getting crowded.';
    } else {
      summary =
          '${widget.ticker} is trading in a neutral range. RSI is ${rsi.toStringAsFixed(2)} and MACD is ${macd > 0 ? 'bullish' : 'bearish'}, which keeps the model stance at $signal.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.neonGreen, size: 20),
            SizedBox(width: 8),
            Text(
              'Market Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Text(
            summary,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildModelIntelligence() {
    final macd = (_stockData?['MACD'] as num?)?.toDouble() ?? 0.0;
    final rsi = (_stockData?['RSI'] as num?)?.toDouble() ?? 50.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Model Intelligence Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        _buildIntelligenceItem(
          'Sentiment Alpha',
          macd > 0 ? 'Bullish' : 'Bearish',
          macd > 0 ? AppColors.neonGreen : AppColors.electricRed,
        ),
        _buildIntelligenceItem(
          'RSI Engine',
          rsi < 30 ? 'Oversold' : (rsi > 70 ? 'Overbought' : 'Neutral'),
          rsi < 30
              ? AppColors.neonGreen
              : (rsi > 70 ? AppColors.electricRed : AppColors.mutedGrey),
        ),
        _buildIntelligenceItem(
          'Trade Signal',
          _stockData?['signal']?.toString() ?? 'NEUTRAL',
          (_stockData?['signal']?.toString().contains('BUY') ?? false)
              ? AppColors.neonGreen
              : ((_stockData?['signal']?.toString().contains('SELL') ?? false)
                  ? AppColors.electricRed
                  : AppColors.mutedGrey),
        ),
      ],
    );
  }

  Widget _buildIntelligenceItem(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(color: Colors.white)),
            Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double percentage;

  GaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    const strokeWidth = 20.0;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.electricRed, Colors.orange, AppColors.neonGreen],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
