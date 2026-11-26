import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/features/account/presentation/account_screen.dart';
import 'package:warenbestand/features/auth/presentation/forgot_password_screen.dart';
import 'package:warenbestand/features/auth/presentation/login_screen.dart';
import 'package:warenbestand/features/auth/presentation/onboarding_screen.dart';
import 'package:warenbestand/features/auth/presentation/session_controller.dart';
import 'package:warenbestand/features/company/presentation/company_screen.dart';
import 'package:warenbestand/features/delivery_notes/presentation/delivery_note_detail_screen.dart';
import 'package:warenbestand/features/delivery_notes/presentation/delivery_note_form_screen.dart';
import 'package:warenbestand/features/delivery_notes/presentation/delivery_note_sign_screen.dart';
import 'package:warenbestand/features/delivery_notes/presentation/delivery_notes_list_screen.dart';
import 'package:warenbestand/features/drivers/presentation/driver_form_screen.dart';
import 'package:warenbestand/features/drivers/presentation/drivers_list_screen.dart';
import 'package:warenbestand/features/help/presentation/help_screen.dart';
import 'package:warenbestand/features/home/presentation/home_screen.dart';
import 'package:warenbestand/features/home/presentation/more_screen.dart';
import 'package:warenbestand/features/invoices/presentation/invoice_detail_screen.dart';
import 'package:warenbestand/features/invoices/presentation/invoice_form_screen.dart';
import 'package:warenbestand/features/invoices/presentation/invoices_list_screen.dart';
import 'package:warenbestand/features/platform/presentation/platform_screen.dart';
import 'package:warenbestand/features/products/presentation/product_detail_screen.dart';
import 'package:warenbestand/features/products/presentation/product_form_screen.dart';
import 'package:warenbestand/features/products/presentation/products_list_screen.dart';
import 'package:warenbestand/features/receipts/presentation/expense_detail_screen.dart';
import 'package:warenbestand/features/receipts/presentation/expense_form_screen.dart';
import 'package:warenbestand/features/receipts/presentation/expenses_month_screen.dart';
import 'package:warenbestand/features/reports/domain/report_period.dart';
import 'package:warenbestand/features/reports/presentation/driver_stats_screen.dart';
import 'package:warenbestand/features/reports/presentation/reports_screen.dart';
import 'package:warenbestand/features/tours/presentation/goods_list_screen.dart';
import 'package:warenbestand/features/tours/presentation/tour_close_screen.dart';
import 'package:warenbestand/features/tours/presentation/tour_detail_screen.dart';
import 'package:warenbestand/features/tours/presentation/tour_plan_screen.dart';
import 'package:warenbestand/features/tours/presentation/tours_list_screen.dart';
import 'package:warenbestand/features/users/presentation/user_create_screen.dart';
import 'package:warenbestand/features/users/presentation/users_screen.dart';
import 'package:warenbestand/shared/presentation/app_shell.dart';
import 'package:warenbestand/shared/presentation/image_viewer_screen.dart';
import 'package:warenbestand/shared/presentation/pdf_preview_screen.dart';
import 'package:warenbestand/shared/widgets/layout/unsaved_changes_guard.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createRouter(
  SessionController session, {
  bool showOnboarding = false,
}) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: showOnboarding ? '/onboarding' : '/home',
  refreshListenable: session,
  redirect: (context, state) {
    final path = state.uri.path;
    final public =
        path == '/login' || path == '/forgot-password' || path == '/onboarding';
    if (!session.isAuthenticated && !public) {
      return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
    }
    if (session.isAuthenticated && path == '/login') {
      return state.uri.queryParameters['from'] ?? '/home';
    }
    if (session.profileLoaded &&
        !session.isSuperadmin &&
        path.startsWith('/platform')) {
      return '/more?notice=access';
    }
    if (session.profileLoaded &&
        !session.canManage &&
        (path == '/users' || path == '/company')) {
      return '/more?notice=access';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) => const ForgotPasswordScreen(),
    ),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    ShellRoute(
      builder: (_, _, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/tours', builder: (_, _) => const ToursListScreen()),
        GoRoute(
          path: '/products',
          builder: (_, _) => const ProductsListScreen(),
        ),
        GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
        GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
        GoRoute(
          path: '/tours/new',
          // Ohne Rückfrage beim Verlassen: der angefangene Stand wird auf dem
          // Gerät gemerkt (`DraftSaver`).
          builder: (_, _) => const TourPlanScreen(),
        ),
        GoRoute(
          path: '/delivery-notes',
          builder: (_, _) => const DeliveryNotesListScreen(),
        ),
        GoRoute(
          path: '/delivery-notes/new',
          builder: (_, _) => const DeliveryNoteFormScreen(),
        ),
        GoRoute(
          path: '/delivery-notes/:id/edit',
          builder: (_, state) => UnsavedChangesGuard(
            child: DeliveryNoteFormScreen(noteId: state.pathParameters['id']),
          ),
        ),
        GoRoute(
          path: '/delivery-notes/:id/sign',
          builder: (_, state) =>
              DeliveryNoteSignScreen(noteId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/delivery-notes/:id',
          builder: (_, state) =>
              DeliveryNoteDetailScreen(noteId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/expenses',
          builder: (_, _) => const ExpensesMonthScreen(),
        ),
        GoRoute(
          path: '/expenses/new',
          builder: (_, _) =>
              const UnsavedChangesGuard(child: ExpenseFormScreen()),
        ),
        GoRoute(
          path: '/expenses/:id/edit',
          builder: (_, state) => UnsavedChangesGuard(
            child: ExpenseFormScreen(expenseId: state.pathParameters['id']),
          ),
        ),
        GoRoute(
          path: '/expenses/:id',
          builder: (_, state) =>
              ExpenseDetailScreen(expenseId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/invoices',
          builder: (_, _) => const InvoicesListScreen(),
        ),
        GoRoute(
          path: '/invoices/new',
          builder: (_, _) => const InvoiceFormScreen(),
        ),
        GoRoute(
          path: '/invoices/:id/edit',
          builder: (_, state) => UnsavedChangesGuard(
            child: InvoiceFormScreen(invoiceId: state.pathParameters['id']),
          ),
        ),
        GoRoute(
          path: '/invoices/:id',
          builder: (_, state) =>
              InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/reports/drivers',
          builder: (_, state) =>
              DriverStatsScreen(period: state.extra as ReportPeriod?),
        ),
        GoRoute(
          path: '/tours/:id/load',
          builder: (_, state) => UnsavedChangesGuard(
            child: TourPlanScreen(tourId: state.pathParameters['id']),
          ),
        ),
        GoRoute(
          path: '/tours/:id/close',
          builder: (_, state) => UnsavedChangesGuard(
            child: TourCloseScreen(tourId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/tours/:id',
          builder: (_, state) =>
              TourDetailScreen(tourId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/products/new',
          builder: (_, _) =>
              const UnsavedChangesGuard(child: ProductFormScreen()),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (_, state) =>
              ProductDetailScreen(productId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/products/:id/edit',
          builder: (_, state) => UnsavedChangesGuard(
            child: ProductFormScreen(productId: state.pathParameters['id']),
          ),
        ),
        GoRoute(path: '/drivers', builder: (_, _) => const DriversListScreen()),
        GoRoute(
          path: '/drivers/new',
          builder: (_, _) =>
              const UnsavedChangesGuard(child: DriverFormScreen()),
        ),
        GoRoute(
          path: '/drivers/:id',
          builder: (_, state) => UnsavedChangesGuard(
            child: DriverFormScreen(driverId: state.pathParameters['id']),
          ),
        ),
        ..._featureRoutes,
      ],
    ),
    // Vollbild über der unteren Leiste. Muss neben der ShellRoute stehen, nicht
    // darin: go_router erlaubt in der Shell keinen anderen Navigator-Schlüssel.
    GoRoute(
      path: '/pdf-preview',
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          PdfPreviewScreen(args: state.extra! as PdfPreviewArgs),
    ),
    GoRoute(
      path: '/image-viewer',
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          ImageViewerScreen(args: state.extra! as ImageViewerArgs),
    ),
  ],
);

final _featureRoutes = <RouteBase>[
  GoRoute(
    path: '/tour-goods',
    builder: (_, state) => GoodsListScreen(args: state.extra! as GoodsListArgs),
  ),
  GoRoute(path: '/platform', builder: (_, _) => const PlatformScreen()),
  GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
  GoRoute(
    path: '/users/new',
    // `?company=1` wählt „Neue Firma“ vor (nur für den Superadmin wirksam).
    builder: (_, state) => UnsavedChangesGuard(
      child: UserCreateScreen(
        startWithNewCompany: state.uri.queryParameters['company'] == '1',
      ),
    ),
  ),
  GoRoute(path: '/company', builder: (_, _) => const CompanyScreen()),
  GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
  GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
];
