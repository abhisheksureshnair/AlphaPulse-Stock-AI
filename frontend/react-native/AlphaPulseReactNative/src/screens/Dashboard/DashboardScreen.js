import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  RefreshControl,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import { LineChart } from 'react-native-chart-kit';
import { TrendingUp, RefreshCw } from 'lucide-react-native';
import { AppColors } from '../../theme/colors';
import { ApiService } from '../../services/api';
import { useApp } from '../../context/AppContext';

const { width } = Dimensions.get('window');

export const DashboardScreen = () => {
  const { trackedSymbols, selectedTicker, selectTicker } = useApp();
  const [stocks, setStocks] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchStocks = async () => {
    try {
      setIsLoading(true);
      const data = await ApiService.fetchStocks(trackedSymbols);
      setStocks(data);
    } catch (error) {
      console.error(error);
    } finally {
      setIsLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchStocks();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    fetchStocks();
  };

  const totalValue = stocks.reduce((sum, s) => sum + (s.price || 0), 0);
  const totalChange = stocks.reduce((sum, s) => sum + (s.change_percent || 0), 0) / (stocks.length || 1);

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={AppColors.neonGreen} />
      }
    >
      <View style={styles.content}>
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.headerLabel}>Market Breadth</Text>
            <View style={styles.breadthRow}>
              <Text style={styles.breadthValue}>{stocks.filter(s => s.change >= 0).length}/{stocks.length}</Text>
              <View style={styles.positiveBadge}>
                <Text style={styles.positiveText}>Positive</Text>
              </View>
            </View>
          </View>
          <View style={styles.headerIcon}>
            <TrendingUp color={AppColors.neonGreen} size={24} />
          </View>
        </View>

        {/* Portfolio Card */}
        <View style={styles.portfolioCard}>
          <View style={styles.chartContainer}>
            {stocks.length > 0 && (
              <LineChart
                data={{
                  labels: [],
                  datasets: [{ data: stocks.map(s => s.price || 0) }],
                }}
                width={width - 40}
                height={150}
                withDots={false}
                withInnerLines={false}
                withOuterLines={false}
                withVerticalLabels={false}
                withHorizontalLabels={false}
                chartConfig={{
                  backgroundGradientFrom: AppColors.cardBackground,
                  backgroundGradientTo: AppColors.cardBackground,
                  color: (opacity = 1) => `rgba(57, 255, 20, ${opacity})`,
                  strokeWidth: 3,
                }}
                bezier
                style={styles.chart}
              />
            )}
          </View>
          <View style={styles.portfolioInfo}>
            <Text style={styles.cardLabel}>Tracked Value</Text>
            <Text style={styles.cardValue}>${totalValue.toFixed(2)}</Text>
            <Text style={[styles.cardChange, { color: totalChange >= 0 ? AppColors.neonGreen : AppColors.electricRed }]}>
              {totalChange >= 0 ? '+' : ''}{totalChange.toFixed(2)}% combined move
            </Text>
          </View>
        </View>

        {/* Tracked Stocks */}
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Tracked Stocks</Text>
          <TouchableOpacity onPress={fetchStocks}>
            <RefreshCw color={AppColors.neonGreen} size={18} />
          </TouchableOpacity>
        </View>

        {stocks.map((stock) => (
          <TouchableOpacity
            key={stock.symbol}
            style={[styles.stockCard, selectedTicker === stock.symbol && styles.selectedCard]}
            onPress={() => selectTicker(stock.symbol)}
          >
            <View style={styles.stockInfo}>
              <View style={styles.symbolIcon}>
                <Text style={styles.symbolText}>{stock.symbol[0]}</Text>
              </View>
              <View style={styles.symbolDetails}>
                <View style={styles.symbolRow}>
                  <Text style={styles.symbolName}>{stock.symbol}</Text>
                  <View style={[styles.signalBadge, { backgroundColor: (stock.change_percent >= 0 ? AppColors.neonGreen : AppColors.electricRed) + '22' }]}>
                    <Text style={[styles.signalText, { color: stock.change_percent >= 0 ? AppColors.neonGreen : AppColors.electricRed }]}>
                      {stock.signal}
                    </Text>
                  </View>
                </View>
                <Text style={styles.companyName}>{stock.name}</Text>
              </View>
            </View>
            <View style={styles.stockPrice}>
              <Text style={styles.priceValue}>${stock.price?.toFixed(2)}</Text>
              <Text style={[styles.priceChange, { color: stock.change_percent >= 0 ? AppColors.neonGreen : AppColors.electricRed }]}>
                {stock.change_percent >= 0 ? '+' : ''}{stock.change_percent?.toFixed(2)}%
              </Text>
            </View>
          </TouchableOpacity>
        ))}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: AppColors.background,
  },
  content: {
    padding: 20,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 30,
  },
  headerLabel: {
    color: AppColors.mutedGrey,
    fontSize: 14,
  },
  breadthRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  breadthValue: {
    color: AppColors.white,
    fontSize: 24,
    fontWeight: 'bold',
  },
  positiveBadge: {
    backgroundColor: 'rgba(57, 255, 20, 0.1)',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    marginLeft: 10,
  },
  positiveText: {
    color: AppColors.neonGreen,
    fontSize: 12,
    fontWeight: 'bold',
  },
  headerIcon: {
    width: 45,
    height: 45,
    borderRadius: 22.5,
    borderWidth: 2,
    borderColor: AppColors.neonGreen,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: AppColors.cardBackground,
  },
  portfolioCard: {
    backgroundColor: AppColors.cardBackground,
    borderRadius: 24,
    height: 150,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
    overflow: 'hidden',
    marginBottom: 30,
  },
  chartContainer: {
    position: 'absolute',
    bottom: -10,
    left: 0,
    right: 0,
  },
  chart: {
    paddingRight: 0,
    paddingLeft: 0,
  },
  portfolioInfo: {
    padding: 20,
  },
  cardLabel: {
    color: AppColors.mutedGrey,
    fontSize: 14,
  },
  cardValue: {
    color: AppColors.white,
    fontSize: 28,
    fontWeight: 'bold',
    marginTop: 4,
  },
  cardChange: {
    fontSize: 12,
    fontWeight: 'bold',
    marginTop: 4,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  sectionTitle: {
    color: AppColors.white,
    fontSize: 18,
    fontWeight: 'bold',
  },
  stockCard: {
    backgroundColor: AppColors.cardBackground,
    padding: 16,
    borderRadius: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
  },
  selectedCard: {
    borderColor: AppColors.neonGreen,
  },
  stockInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  symbolIcon: {
    width: 40,
    height: 40,
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
  symbolText: {
    color: AppColors.white,
    fontWeight: 'bold',
  },
  symbolDetails: {
    marginLeft: 12,
  },
  symbolRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  symbolName: {
    color: AppColors.white,
    fontWeight: 'bold',
    fontSize: 16,
  },
  signalBadge: {
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 4,
    marginLeft: 6,
  },
  signalText: {
    fontSize: 10,
    fontWeight: 'bold',
  },
  companyName: {
    color: AppColors.mutedGrey,
    fontSize: 12,
  },
  stockPrice: {
    alignItems: 'flex-end',
  },
  priceValue: {
    color: AppColors.white,
    fontWeight: 'bold',
    fontSize: 16,
  },
  priceChange: {
    fontSize: 12,
    fontWeight: 'bold',
  },
});
