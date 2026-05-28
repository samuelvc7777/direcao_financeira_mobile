import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Nova Paleta Vibrante Sólida
  static const Color deepNavy = Color(0xFF141518);     // Background Principal (Preto mais claro)
  static const Color midnight = Color(0xFF101010);     // Surface / Cards (Preto um pouco mais suave)
  static const Color royalBlue = Color(0xFF1E40AF);    // Primary / Ações Principais (Azul mais forte e escuro)
  static const Color electricCyan = Color(0xFF06B6D4); // Contas Bancárias / Destaques
  static const Color violet = Color(0xFF8B5CF6);       // Cartões de Crédito
  static const Color emerald = Color(0xFF10B981);      // Sucesso / Entradas
  static const Color rose = Color(0xFFF43F5E);         // Erro / Saídas
  static const Color amber = Color(0xFFF59E0B);        // Alertas / Metas
  static const Color sky = Color(0xFF38BDF8);          // Gráficos / Info
  static const Color gold = Color(0xFFFBBF24);         // Premium
  static const Color lime = Color(0xFF84CC16);         // Progresso Positivo

  // Primary & Brand Mapping
  static const Color primary = royalBlue;
  static const Color secondary = electricCyan;
  static const Color accent = amber;

  // Neutral / Backgrounds
  static const Color background = Color(0xFFF8FAFC);   // Slate 50
  static const Color backgroundDark = deepNavy;
  static const Color surface = Colors.white;
  static const Color surfaceDark = midnight;

  // Semantic
  static const Color success = emerald;
  static const Color error = rose;
  static const Color warning = amber;
  static const Color info = sky;

  // Accent do App por Seção (Facilitar manutenção)
  static const Color accountsAccent = electricCyan;
  static const Color cardsAccent = violet;
  static const Color goalsAccent = amber;

  // Text
  static const Color textPrimary = Color(0xFF0F172A);  // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textLight = Color(0xFF94A3B8);    // Slate 400

  // Dark Mode Text
  static const Color textPrimaryDark = Color(0xFFF8FAFC); 
  static const Color textSecondaryDark = Color(0xFF94A3B8); 

  // Helpers de Antiguidade (Para não quebrar referências imediatas, mas devem ser migrados)
  static const Color petrol = deepNavy;
  static const Color teal = royalBlue;
  static const Color aqua = electricCyan;
  static const Color sand = amber;
  static const Color rust = rose;
}
