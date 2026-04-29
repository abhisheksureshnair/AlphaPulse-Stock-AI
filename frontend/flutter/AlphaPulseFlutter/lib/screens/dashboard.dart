import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alpha_pulse/services/api_service.dart';
import 'package:alpha_pulse/state/app_state.dart';
import 'package:alpha_pulse/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _stocks = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStocks();
  }

  Future<void> _fetchStocks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stocks = await ApiService.fetchStocks(AppState.trackedSymbols);
      if (!mounted) {
        return;
      }
      setState(() {
        _stocks = stocks;
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
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.neonGreen,
          onRefresh: _fetchStocks,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildPortfolioSection(),
                const SizedBox(height: 30),
                _buildSectionHeader('Top Market Picks', false),
                const SizedBox(height: 16),
                _buildTopPicksSection(),
                const SizedBox(height: 30),
                _buildSectionHeader('Tracked Stocks', true),
                const SizedBox(height: 15),
                if (_isLoading)
                  Column(
                    children: List.generate(5, (index) => const ShimmerStockCard()),
                  )
                else if (_error != null)
                  ErrorView(
                    message: _error!,
                    onRetry: _fetchStocks,
                  )
                else
                  _buildStockList(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchStocks,
        backgroundColor: AppColors.neonGreen,
        child: const Icon(Icons.refresh, color: Colors.black),
      ),
    );
  }

  Widget _buildHeader() {
    final positiveCount = _stocks.where((stock) => (stock['change'] ?? 0) >= 0).length;
    final totalCount = _stocks.isEmpty ? 1 : _stocks.length;
    final marketBreadth = ((positiveCount / totalCount) * 100).round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracked Market Breadth',
              style: TextStyle(color: AppColors.mutedGrey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '$marketBreadth%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$positiveCount/${_stocks.isEmpty ? AppState.trackedSymbols.length : _stocks.length} positive',
                    style: const TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.neonGreen, width: 2),
            color: AppColors.cardBackground,
          ),
          child: const Icon(
            Icons.show_chart,
            color: AppColors.neonGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection() {
    final totalValue = _stocks.fold<double>(
      0,
      (sum, stock) => sum + ((stock['price'] as num?)?.toDouble() ?? 0),
    );
    final totalChange = _stocks.fold<double>(
      0,
      (sum, stock) => sum + ((stock['change_percent'] as num?)?.toDouble() ?? 0),
    );

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _buildPortfolioSpots(),
                      isCurved: true,
                      color: AppColors.neonGreen,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonGreen.withOpacity(0.2),
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
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tracked Value',
                    style: TextStyle(color: AppColors.mutedGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${totalChange >= 0 ? '+' : ''}${totalChange.toStringAsFixed(2)}% combined move',
                    style: TextStyle(
                      color: totalChange >= 0 ? AppColors.neonGreen : AppColors.electricRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildPortfolioSpots() {
    if (_stocks.isEmpty) {
      return const [];
    }

    return _stocks.asMap().entries.map((entry) {
      final price = (entry.value['price'] as num?)?.toDouble() ?? 0;
      return FlSpot(entry.key.toDouble(), price);
    }).toList();
  }

  Widget _buildSectionHeader(String title, bool showEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (showEdit)
          const Text(
            'Tap a stock to sync tabs',
            style: TextStyle(color: AppColors.neonGreen, fontSize: 14),
          ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.electricRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unable to load market data',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchStocks,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGreen),
            child: const Text('Retry', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    final selectedTicker = context.watch<AppState>().selectedTicker;
    return Column(
      children: _stocks.map((stock) {
        return _buildStockItem(
          stock: stock,
          isSelected: selectedTicker == stock['symbol'],
        );
      }).toList(),
    );
  }

  Widget _buildStockItem({
    required Map<String, dynamic> stock,
    required bool isSelected,
  }) {
    final ticker = stock['symbol']?.toString() ?? '';
    final name = stock['name']?.toString() ?? ticker;
    final price = ((stock['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
    final changePercent = (stock['change_percent'] as num?)?.toDouble() ?? 0;
    final signal = stock['signal']?.toString() ?? 'NEUTRAL';
    final color = changePercent >= 0 ? AppColors.neonGreen : AppColors.electricRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.read<AppState>().selectTicker(ticker),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.neonGreen : Colors.white.withOpacity(0.05),
              width: isSelected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    ticker.isEmpty ? '?' : ticker[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ticker,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            signal,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      name,
                      style: TextStyle(color: AppColors.mutedGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$$price',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  Widget _buildTopPicksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOP AI PICKS TODAY',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.neonGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('LIVE SCAN', style: TextStyle(color: AppColors.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: ApiService.scanMarket(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: AppColors.neonGreen)));
            }
            if (!snapshot.hasData || snapshot.data!['top_picks'] == null) {
              return const Text('Failed to load picks', style: TextStyle(color: AppColors.mutedGrey));
            }
            final picks = snapshot.data!['top_picks'] as List;
            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: picks.length,
                itemBuilder: (context, index) {
                  final pick = picks[index];
                  final finalVerdict = pick['final'];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(finalVerdict['stock'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Icon(Icons.auto_graph, color: AppColors.neonGreen.withOpacity(0.5), size: 20),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(finalVerdict['final_decision'], style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${finalVerdict['confidence']}% Confidence',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(finalVerdict['agreement_score'] * 100).toInt()}% Consensus',
                          style: const TextStyle(color: AppColors.mutedGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
