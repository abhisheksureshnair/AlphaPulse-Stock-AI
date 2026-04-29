import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  Map<String, dynamic>? _portfolio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchPortfolio();
      setState(() {
        _portfolio = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.electricRed),
        );
      }
    }
  }

  @override
  Widget Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPortfolio,
          color: AppColors.neonGreen,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              if (_isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.neonGreen)))
              else if (_portfolio == null || (_portfolio!['holdings'] as List).isEmpty)
                _buildEmptyState()
              else
                _buildHoldingsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBuyModal(context),
        backgroundColor: AppColors.neonGreen,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildHeader() {
    final totalValue = _portfolio?['total_value'] ?? 0.0;
    final totalPL = _portfolio?['total_profit_loss'] ?? 0.0;
    final isPositive = totalPL >= 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MY PORTFOLIO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL BALANCE', style: TextStyle(color: AppColors.mutedGrey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalValue.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? AppColors.neonGreen : AppColors.electricRed,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isPositive ? '+' : ''}\$${totalPL.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isPositive ? AppColors.neonGreen : AppColors.electricRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Total Profit/Loss', style: TextStyle(color: AppColors.mutedGrey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet_outlined, size: 80, color: AppColors.neonGreen.withOpacity(0.5)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Start your journey',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your portfolio is currently empty.\nExplore AI recommendations to start building your wealth.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedGrey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _showBuyModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('ADD FIRST STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingsList() {
    final holdings = _portfolio!['holdings'] as List;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final holding = holdings[index];
            return _buildHoldingCard(holding);
          },
          childCount: holdings.length,
        ),
      ),
    );
  }

  Widget _buildHoldingCard(Map<String, dynamic> holding) {
    final pl = holding['profit_loss'] ?? 0.0;
    final isPositive = pl >= 0;

    return Container(
      margin: const EdgeInsets.bottom(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    holding['ticker'][0],
                    style: const TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding['ticker'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${holding['quantity']} Shares',
                    style: const TextStyle(color: AppColors.mutedGrey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${(holding['current_price'] * holding['quantity']).toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${isPositive ? '+' : ''}\$${pl.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPositive ? AppColors.neonGreen : AppColors.electricRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBuyModal(BuildContext context) {
    final tickerController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BUY STOCK', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildTextField(tickerController, 'TICKER (e.g. AAPL)', Icons.label_outline),
            const SizedBox(height: 16),
            _buildTextField(priceController, 'BUY PRICE', Icons.attach_money, isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(quantityController, 'QUANTITY', Icons.numbers, isNumber: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiService.buyStock(
                      tickerController.text.trim().toUpperCase(),
                      double.parse(priceController.text),
                      int.parse(quantityController.text),
                    );
                    Navigator.pop(context);
                    _loadPortfolio();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CONFIRM PURCHASE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.mutedGrey),
        prefixIcon: Icon(icon, color: AppColors.neonGreen, size: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.neonGreen)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
      ),
    );
  }
}
