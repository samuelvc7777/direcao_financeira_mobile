import 'package:get/get.dart';
import '../presentation/modules/login/login_view.dart';
import '../presentation/modules/login/login_binding.dart';
import '../presentation/modules/reset_password/reset_password_binding.dart';
import '../presentation/modules/reset_password/reset_password_view.dart';
import '../presentation/modules/home/home_view.dart';
import '../presentation/modules/home/home_binding.dart';
import '../presentation/modules/register/register_view.dart';
import '../presentation/modules/register/register_binding.dart';
import '../presentation/modules/initial/initial_view.dart';
import '../presentation/modules/initial/initial_binding.dart';
import '../presentation/modules/settings/settings_binding.dart';
import '../presentation/modules/settings/settings_view.dart';
import '../presentation/modules/subscription/subscription_binding.dart';
import '../presentation/modules/subscription/subscription_view.dart';
import '../presentation/modules/categories/categories_binding.dart';
import '../presentation/modules/categories/categories_view.dart';

import '../presentation/modules/bank_accounts/bank_accounts_binding.dart';
import '../presentation/modules/bank_accounts/bank_accounts_view.dart';
import '../presentation/modules/credit_cards/credit_cards_binding.dart';
import '../presentation/modules/credit_cards/credit_cards_view.dart';
import '../presentation/modules/transactions/transactions_binding.dart';
import '../presentation/modules/transactions/views/transaction_form_view.dart';
import '../presentation/modules/transactions/views/credit_card_form_view.dart';
import '../presentation/modules/journey/journey_view.dart';
import '../presentation/modules/journey/journey_binding.dart';
import '../presentation/modules/journey/add_ride_binding.dart';
import '../presentation/modules/journey/add_ride_view.dart';
import '../presentation/modules/journey/import_ride_photo_binding.dart';
import '../presentation/modules/journey/import_ride_photo_view.dart';
import '../presentation/modules/journey/operational_metrics_view.dart';
import '../presentation/modules/journey/daily_statistics_view.dart';
import '../presentation/modules/journey/ride_details_view.dart';
import '../presentation/modules/journey/shift_route_binding.dart';
import '../presentation/modules/journey/shift_route_view.dart';
import '../presentation/modules/traffic_light_settings/traffic_light_settings_view.dart';
import '../presentation/modules/traffic_light_settings/traffic_light_settings_binding.dart';
import '../presentation/modules/recording_settings/recording_settings_view.dart';
import '../presentation/modules/recording_settings/recording_settings_binding.dart';
import '../presentation/modules/costs_gains_settings/costs_gains_settings_binding.dart';
import '../presentation/modules/costs_gains_settings/costs_gains_settings_view.dart';
import '../presentation/modules/costs_gains_wizard/costs_gains_wizard_binding.dart';
import '../presentation/modules/costs_gains_wizard/costs_gains_wizard_view.dart';
import '../presentation/modules/goals/goals_binding.dart';
import '../presentation/modules/goals/goals_view.dart';
import '../presentation/modules/help/help_binding.dart';
import '../presentation/modules/help/help_view.dart';
import '../domain/entities/transaction_entity.dart';

class AppRoutes {
  static const String login = '/login';
  static const String resetPassword = '/reset-password';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String initial = '/initial';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String categories = '/categories';
  static const String bankAccounts = '/bank-accounts';
  static const String creditCards = '/credit-cards';
  static const String transactionExpense = '/transactions/expense';
  static const String transactionIncome = '/transactions/income';
  static const String transactionCreditCard = '/transactions/credit-card';
  static const String journey = '/journey';
  static const String journeyMetrics = '/journey/metrics';
  static const String shiftMetrics = '/journey/shift-metrics';
  static const String shiftRoute = '/journey/shift-route';
  static const String journeyRideDetails = '/journey/ride-details';
  static const String journeyAddRide = '/journey/add-ride';
  static const String journeyImportRidePhoto = '/journey/import-ride-photo';
  static const String trafficLightSettings = '/traffic-light-settings';
  static const String recordingSettings = '/recording-settings';
  static const String costsGainsSettings = '/costs-gains-settings';
  static const String costsGainsWizard = '/costs-gains-wizard';
  static const String goals = '/goals';
  static const String help = '/help';
}

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.journey,
      page: () => const JourneyView(),
      binding: JourneyBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.journeyMetrics,
      page: () => const OperationalMetricsView(),
      binding: JourneyBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.shiftMetrics,
      page: () => const DailyStatisticsView(),
      binding: JourneyBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.shiftRoute,
      page: () => const ShiftRouteView(),
      binding: ShiftRouteBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.journeyRideDetails,
      page: () => const RideDetailsView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.journeyAddRide,
      page: () => const AddRideView(),
      binding: AddRideBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.journeyImportRidePhoto,
      page: () => const ImportRidePhotoView(),
      binding: ImportRidePhotoBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.initial,
      page: () => const InitialView(),
      binding: InitialBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.subscription,
      page: () => const SubscriptionView(),
      binding: SubscriptionBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesView(),
      binding: CategoriesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.bankAccounts,
      page: () => const BankAccountsView(),
      binding: BankAccountsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.creditCards,
      page: () => const CreditCardsView(),
      binding: CreditCardsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.transactionExpense,
      page: () => TransactionFormView(),
      binding: TransactionsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      arguments: TransactionType.expense,
    ),
    GetPage(
      name: AppRoutes.transactionIncome,
      page: () => TransactionFormView(),
      binding: TransactionsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      arguments: TransactionType.income,
    ),
    GetPage(
      name: AppRoutes.transactionCreditCard,
      page: () => CreditCardFormView(),
      binding: TransactionsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.trafficLightSettings,
      page: () => const TrafficLightSettingsView(),
      binding: TrafficLightSettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.recordingSettings,
      page: () => const RecordingSettingsView(),
      binding: RecordingSettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.costsGainsSettings,
      page: () => const CostsGainsSettingsView(),
      binding: CostsGainsSettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.costsGainsWizard,
      page: () => const CostsGainsWizardView(),
      binding: CostsGainsWizardBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.goals,
      page: () => const GoalsView(),
      binding: GoalsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.help,
      page: () => const HelpView(),
      binding: HelpBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
