import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  final List<String> _conditions = ['PRICE_ABOVE', 'PRICE_BELOW', 'RSI_BELOW'];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchAlerts();
      setState(() {
        _alerts = data;
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAlerts,
          color: AppColors.neonGreen,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              if (_isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.neonGreen)))
              else if (_alerts.isEmpty)
                _buildEmptyState()
              else
                _buildAlertsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAlertModal(context),
        backgroundColor: AppColors.neonGreen,
        child: const Icon(Icons.add_alert, color: Colors.black),
      ),
    );
  }

  Widget _buildHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRICE ALERTS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Get notified when stocks hit your targets.',
              style: TextStyle(color: AppColors.mutedGrey, fontSize: 14),
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
                  color: Colors.blueAccent.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active_outlined, size: 80, color: Colors.blueAccent.withOpacity(0.5)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Stay informed',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'You haven\'t set any price alerts yet.\nWe\'ll notify you the instant a stock hits your target.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedGrey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _showCreateAlertModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CREATE FIRST ALERT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final alert = _alerts[index];
            return _buildAlertCard(alert);
          },
          childCount: _alerts.length,
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isTriggered = alert['is_triggered'] == 1;
    final conditionText = alert['condition'].replaceAll('_', ' ');

    return Container(
      margin: const EdgeInsets.bottom(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(isTriggered ? 0.3 : 1.0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isTriggered ? Colors.white10 : AppColors.neonGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isTriggered ? Icons.check_circle_outline : Icons.notifications_active_outlined,
                color: isTriggered ? AppColors.mutedGrey : AppColors.neonGreen,
                size: 24,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert['ticker'],
                    style: TextStyle(
                      color: isTriggered ? AppColors.mutedGrey : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conditionText,
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
                '${alert['target_value']}',
                style: TextStyle(
                  color: isTriggered ? AppColors.mutedGrey : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isTriggered ? 'TRIGGERED' : 'ACTIVE',
                style: TextStyle(
                  color: isTriggered ? AppColors.mutedGrey : AppColors.neonGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateAlertModal(BuildContext context) {
    final tickerController = TextEditingController();
    final valueController = TextEditingController();
    String selectedCondition = _conditions.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SET NEW ALERT', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildTextField(tickerController, 'STOCK TICKER', Icons.label_outline),
              const SizedBox(height: 16),
              
              const Text('CONDITION', style: TextStyle(color: AppColors.mutedGrey, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCondition,
                    dropdownColor: AppColors.cardBackground,
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c.replaceAll('_', ' ')))).toList(),
                    onChanged: (val) => setModalState(() => selectedCondition = val!),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              _buildTextField(valueController, 'TARGET VALUE', Icons.track_changes, isNumber: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ApiService.createAlert(
                        tickerController.text.trim().toUpperCase(),
                        selectedCondition,
                        double.parse(valueController.text),
                      );
                      Navigator.pop(context);
                      _loadAlerts();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CREATE ALERT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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
