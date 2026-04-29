import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Brain, Sparkles } from 'lucide-react-native';
import { AppColors } from '../../theme/colors';
import { AuthService } from '../../services/api';

export const LoginScreen = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleDemoLogin = async () => {
    setIsLoading(true);
    try {
      const data = await AuthService.demoLogin();
      await AuthService.setToken(data.access_token);
    } catch (error) {
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      style={styles.container}
    >
      <View style={styles.content}>
        <View style={styles.logoContainer}>
          <View style={styles.logoGlow}>
            <Brain color={AppColors.neonGreen} size={80} />
          </View>
          <Text style={styles.title}>ALPHAPULSE</Text>
          <Text style={styles.subtitle}>AI STOCK ASSISTANT</Text>
        </View>

        <View style={styles.form}>
          <TextInput
            style={styles.input}
            placeholder="Username"
            placeholderTextColor={AppColors.mutedGrey}
            value={username}
            onChangeText={setUsername}
            autoCapitalize="none"
          />
          <TextInput
            style={styles.input}
            placeholder="Password"
            placeholderTextColor={AppColors.mutedGrey}
            value={password}
            onChangeText={setPassword}
            secureTextEntry
          />

          <TouchableOpacity style={styles.loginButton} disabled={isLoading}>
            {isLoading ? (
              <ActivityIndicator color="black" />
            ) : (
              <Text style={styles.loginButtonText}>Login</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity style={styles.demoButton} onPress={handleDemoLogin} disabled={isLoading}>
            <Sparkles color={AppColors.neonGreen} size={20} />
            <Text style={styles.demoButtonText}>Try Demo Mode</Text>
          </TouchableOpacity>
        </View>
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: AppColors.background,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    padding: 30,
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: 60,
  },
  logoGlow: {
    padding: 20,
    borderRadius: 60,
    backgroundColor: 'rgba(57, 255, 20, 0.05)',
    shadowColor: AppColors.neonGreen,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.2,
    shadowRadius: 40,
    elevation: 20,
  },
  title: {
    color: AppColors.white,
    fontSize: 32,
    fontWeight: 'bold',
    letterSpacing: 8,
    marginTop: 30,
  },
  subtitle: {
    color: 'rgba(57, 255, 20, 0.7)',
    fontSize: 12,
    fontWeight: '500',
    letterSpacing: 4,
    marginTop: 10,
  },
  form: {
    width: '100%',
  },
  input: {
    backgroundColor: AppColors.cardBackground,
    color: AppColors.white,
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
  },
  loginButton: {
    backgroundColor: AppColors.neonGreen,
    padding: 18,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 10,
  },
  loginButtonText: {
    color: 'black',
    fontWeight: 'bold',
    fontSize: 16,
  },
  demoButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
    borderRadius: 12,
    marginTop: 20,
    borderWidth: 1,
    borderColor: 'rgba(57, 255, 20, 0.3)',
  },
  demoButtonText: {
    color: AppColors.neonGreen,
    fontWeight: '600',
    marginLeft: 10,
  },
});
