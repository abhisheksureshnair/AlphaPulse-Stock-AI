import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:alpha_pulse/services/api_service.dart';
import 'package:alpha_pulse/theme.dart';

class StockDetailScreen extends StatefulWidget {
  final String ticker;

  const StockDetailScreen({super.key, required this.ticker});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  Map<String, dynamic>? _stockData;
  Map<String, dynamic>? _optimisticAnalysis;
  Map<String, dynamic>? _pessimisticAnalysis;
  Map<String, dynamic>? _quantAnalysis;
  bool _isLoading = true;
  bool _isLoadingBullish = false;
  bool _isLoadingBearish = false;
  bool _isLoadingQuant = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant StockDetailScreen oldWidget) {
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

  Future<void> _fetchBullishCase() async {
    setState(() {
      _isLoadingBullish = true;
    });
    try {
      final analysis = await ApiService.fetchOptimisticAnalysis(widget.ticker);
      if (!mounted) return;
      setState(() {
        _optimisticAnalysis = analysis;
        _isLoadingBullish = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingBullish = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bullish case: $e')),
      );
    }
  }

  Future<void> _fetchBearishCase() async {
    setState(() {
      _isLoadingBearish = true;
    });
    try {
      final analysis = await ApiService.fetchPessimisticAnalysis(widget.ticker);
      if (!mounted) return;
      setState(() {
        _pessimisticAnalysis = analysis;
        _isLoadingBearish = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingBearish = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bear case: $e')),
      );
    }
  }

  Future<void> _fetchQuantCase() async {
    setState(() {
      _isLoadingQuant = true;
    });
    try {
      final analysis = await ApiService.fetchQuantAnalysis(widget.ticker);
      if (!mounted) return;
      setState(() {
        _quantAnalysis = analysis;
        _isLoadingQuant = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingQuant = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load quant case: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ticker,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonGreen))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceHeader(),
                      const SizedBox(height: 30),
                      _buildChart(),
                      const SizedBox(height: 20),
                      _buildTimeRangeSelector(),
                      const SizedBox(height: 30),
                      _buildAIAnalysisCard(),
                      const SizedBox(height: 30),
                      _buildBullishSection(),
                      const SizedBox(height: 15),
                      _buildBearishSection(),
                      const SizedBox(height: 15),
                      _buildQuantSection(),
                      const SizedBox(height: 30),
                      _buildTechnicalIndicators(),
                      const SizedBox(height: 40),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPriceHeader() {
    final price = (_stockData?['price'] as num?)?.toDouble() ?? 0.0;
    final change = (_stockData?['change'] as num?)?.toDouble() ?? 0.0;
    final changePercent = (_stockData?['change_percent'] as num?)?.toDouble() ?? 0.0;
    final changeColor = change >= 0 ? AppColors.neonGreen : AppColors.electricRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Row(
          children: [
            Text(
              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
              style: TextStyle(
                color: changeColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Latest daily close from backend',
              style: TextStyle(color: AppColors.mutedGrey, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart() {
    final history = (_stockData?['history'] as List?) ?? const [];
    final points = history.asMap().entries.map((entry) {
      final item = entry.value as Map<String, dynamic>;
      final close = (item['close'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), close);
    }).toList();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: points.isEmpty
                  ? const [FlSpot(0, 0), FlSpot(1, 0)]
                  : points,
              isCurved: true,
              color: AppColors.neonGreen,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonGreen.withOpacity(0.3),
                    AppColors.neonGreen.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    const ranges = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ranges.map((range) {
        const isSelectedRange = '1M';
        final isSelected = range == isSelectedRange;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            range,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.mutedGrey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAIAnalysisCard() {
    final rsi = (_stockData?['RSI'] as num?)?.toDouble() ?? 50.0;
    final signal = _stockData?['signal']?.toString() ?? 'NEUTRAL';
    final isBuy = signal.contains('BUY');
    final isSell = signal.contains('SELL');
    final recColor = isBuy
        ? AppColors.neonGreen
        : (isSell ? AppColors.electricRed : AppColors.mutedGrey);
    final confidence = (100 - (rsi - 50).abs() * 1.6).clamp(45.0, 92.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.neonGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'AI Analysis',
                    style: TextStyle(
                      color: AppColors.mutedGrey,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.help_outline, color: AppColors.mutedGrey, size: 16),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECOMMENDATION',
                    style: TextStyle(color: AppColors.mutedGrey, fontSize: 10),
                  ),
                  Text(
                    signal,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: recColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'CONFIDENCE',
                    style: TextStyle(color: AppColors.mutedGrey, fontSize: 10),
                  ),
                  Text(
                    '${confidence.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInsightBullet(
            'RSI is at ${rsi.toStringAsFixed(2)}, which keeps momentum in ${rsi < 30 ? 'oversold' : (rsi > 70 ? 'overbought' : 'neutral')} territory.',
          ),
          _buildInsightBullet(
            'MACD trend is currently ${((_stockData?['MACD'] as num?)?.toDouble() ?? 0) > 0 ? 'bullish' : 'bearish'}.',
          ),
          _buildInsightBullet(
            'Recommendation is generated from the backend using 3 months of price history.',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: AppColors.neonGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalIndicators() {
    final rsi = ((_stockData?['RSI'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2);
    final macd = ((_stockData?['MACD'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technical Indicators',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildIndicatorItem(
                'RSI (14)',
                rsi,
                double.parse(rsi) > 70
                    ? 'OVERBOUGHT'
                    : (double.parse(rsi) < 30 ? 'OVERSOLD' : 'NEUTRAL'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildIndicatorItem(
                'MACD',
                macd,
                double.parse(macd) > 0 ? 'BULLISH' : 'BEARISH',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicatorItem(String name, String value, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            status,
            style: const TextStyle(color: AppColors.mutedGrey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(18),
              side: const BorderSide(color: Colors.white12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Sell',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: AppColors.neonGreen.withOpacity(0.5),
              elevation: 10,
            ),
            child: Text(
              'Buy ${widget.ticker}',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  Widget _buildBullishSection() {
    if (_optimisticAnalysis == null && !_isLoadingBullish) {
      return Center(
        child: TextButton.icon(
          onPressed: _fetchBullishCase,
          icon: const Icon(Icons.trending_up, color: AppColors.neonGreen),
          label: const Text(
            'See Bullish AI Argument',
            style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_isLoadingBullish) {
      return const Center(child: CircularProgressIndicator(color: AppColors.neonGreen));
    }

    final reasoning = _optimisticAnalysis!['reasoning'] ?? '';
    final confidence = _optimisticAnalysis!['confidence'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.rocket_launch, color: AppColors.neonGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'OPTIMISTIC BULL CASE',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$confidence% Confident',
                  style: const TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            reasoning,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildBearishSection() {
    if (_pessimisticAnalysis == null && !_isLoadingBearish) {
      return Center(
        child: TextButton.icon(
          onPressed: _fetchBearishCase,
          icon: const Icon(Icons.trending_down, color: AppColors.electricRed),
          label: const Text(
            'See Bearish AI Risk Report',
            style: TextStyle(color: AppColors.electricRed, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_isLoadingBearish) {
      return const Center(child: CircularProgressIndicator(color: AppColors.electricRed));
    }

    final reasoning = _pessimisticAnalysis!['reasoning'] ?? '';
    final confidence = _pessimisticAnalysis!['confidence'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.electricRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.electricRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.electricRed, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'PESSIMISTIC BEAR CASE',
                    style: TextStyle(
                      color: AppColors.electricRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$confidence% Confident',
                  style: const TextStyle(color: AppColors.electricRed, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            reasoning,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantSection() {
    if (_quantAnalysis == null && !_isLoadingQuant) {
      return Center(
        child: TextButton.icon(
          onPressed: _fetchQuantCase,
          icon: const Icon(Icons.analytics_outlined, color: Colors.blueAccent),
          label: const Text(
            'See Neutral Quant Report',
            style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_isLoadingQuant) {
      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
    }

    final reasoning = _quantAnalysis!['reasoning'] ?? '';
    final confidence = _quantAnalysis!['confidence'] ?? 0;
    final decision = _quantAnalysis!['decision'] ?? 'HOLD';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.rule, color: Colors.blueAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'NEUTRAL QUANT CASE',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$decision ($confidence%)',
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            reasoning,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
