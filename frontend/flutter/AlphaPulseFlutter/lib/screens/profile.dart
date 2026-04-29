import 'package:flutter/material.dart';
import 'package:alpha_pulse/services/api_service.dart';
import 'package:alpha_pulse/state/app_state.dart';
import 'package:alpha_pulse/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _stocks = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
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
      appBar: AppBar(
        title: const Text('Market Profile'),
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 30),
                        _buildStatsRow(),
                        const SizedBox(height: 30),
                        _buildSection(
                          'TRACKED SYMBOLS',
                          _stocks.map(_buildStockRow).toList(),
                        ),
                        const SizedBox(height: 30),
                        _buildSection(
                          'DATA SUMMARY',
                          [
                            _buildMenuItem(
                              Icons.query_stats,
                              'Positive Movers',
                              '${_positiveCount()} of ${_stocks.length} tracked symbols',
                            ),
                            _buildMenuItem(
                              Icons.analytics_outlined,
                              'Average RSI',
                              _averageRsi().toStringAsFixed(2),
                            ),
                            _buildMenuItem(
                              Icons.show_chart,
                              'Average Daily Move',
                              '${_averageMove().isNegative ? '' : '+'}${_averageMove().toStringAsFixed(2)}%',
                            ),
                            _buildSectionTitle('ACCOUNT'),
                            _buildSettingItem(Icons.person_outline, 'Edit Profile', ''),
                            _buildSettingItem(Icons.history, 'Transaction History', '', onAction: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
                            }),
                            _buildSettingItem(Icons.security, 'Security', ''),
                            _buildSettingItem(Icons.notifications_none, 'Notifications', ''),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.logout, color: AppColors.electricRed),
                              title: const Text('Logout', style: TextStyle(color: AppColors.electricRed, fontWeight: FontWeight.bold)),
                              onTap: () async {
                                await AuthService.logout();
                                if (mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.neonGreen, width: 3),
            color: AppColors.cardBackground,
          ),
          child: const Icon(Icons.insights, color: AppColors.neonGreen, size: 42),
        ),
        const SizedBox(height: 15),
        const Text(
          'Live Market Snapshot',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_stocks.length} symbols loaded from backend',
          style: const TextStyle(color: AppColors.mutedGrey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final trackedValue = _stocks.fold<double>(
      0,
      (sum, stock) => sum + ((stock['price'] as num?)?.toDouble() ?? 0),
    );
    final assets = _stocks.length;
    final avgMove = _averageMove();

    return Row(
      children: [
        Expanded(child: _buildStatItem('\$${trackedValue.toStringAsFixed(2)}', 'TRACKED VALUE')),
        _buildDivider(),
        Expanded(child: _buildStatItem('$assets', 'SYMBOLS')),
        _buildDivider(),
        Expanded(
          child: _buildStatItem(
            '${avgMove.isNegative ? '' : '+'}${avgMove.toStringAsFixed(2)}%',
            'AVG MOVE',
            isPositive: avgMove >= 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, {bool isPositive = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isPositive ? AppColors.neonGreen : Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedGrey,
            fontSize: 10,
            letterSpacing: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.white12);
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.mutedGrey,
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildStockRow(Map<String, dynamic> stock) {
    final symbol = stock['symbol']?.toString() ?? '';
    final price = (stock['price'] as num?)?.toDouble() ?? 0.0;
    final move = (stock['change_percent'] as num?)?.toDouble() ?? 0.0;
    final signal = stock['signal']?.toString() ?? 'NEUTRAL';

    return ListTile(
      leading: const Icon(Icons.show_chart, color: AppColors.neonGreen, size: 20),
      title: Text(
        symbol,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        'Signal: $signal',
        style: const TextStyle(color: AppColors.mutedGrey, fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            '${move >= 0 ? '+' : ''}${move.toStringAsFixed(2)}%',
            style: TextStyle(
              color: move >= 0 ? AppColors.neonGreen : AppColors.electricRed,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.neonGreen, size: 20),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.mutedGrey, fontSize: 12),
      ),
    );
  }

  int _positiveCount() {
    return _stocks.where((stock) => ((stock['change_percent'] as num?)?.toDouble() ?? 0) >= 0).length;
  }

  double _averageRsi() {
    if (_stocks.isEmpty) {
      return 0;
    }
    final total = _stocks.fold<double>(
      0,
      (sum, stock) => sum + ((stock['RSI'] as num?)?.toDouble() ?? 0),
    );
    return total / _stocks.length;
  }

  double _averageMove() {
    if (_stocks.isEmpty) {
      return 0;
    }
    final total = _stocks.fold<double>(
      0,
      (sum, stock) => sum + ((stock['change_percent'] as num?)?.toDouble() ?? 0),
    );
    return total / _stocks.length;
  }
}
