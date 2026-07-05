import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/items/data/medical_item_repository.dart';
import 'features/items/presentation/items_bloc.dart';
import 'features/request/data/request_repository.dart';
import 'features/request/presentation/request_bloc.dart';
import 'features/history/presentation/history_bloc.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/import/presentation/import_screen.dart';
import 'features/items/presentation/items_screen.dart';
import 'features/request/presentation/request_screen.dart';
import 'features/history/presentation/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();

  final itemRepository = MedicalItemRepository(dbHelper: dbHelper);
  final requestRepository = RequestRepository(dbHelper: dbHelper);

  runApp(MedicalRequestApp(
    itemRepository: itemRepository,
    requestRepository: requestRepository,
  ));
}

class MedicalRequestApp extends StatelessWidget {
  final MedicalItemRepository itemRepository;
  final RequestRepository requestRepository;

  const MedicalRequestApp({
    super.key,
    required this.itemRepository,
    required this.requestRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ItemsBloc>(
          create: (_) => ItemsBloc(repository: itemRepository)..add(LoadItems()),
        ),
        BlocProvider<RequestBloc>(
          create: (_) => RequestBloc(repository: requestRepository),
        ),
        BlocProvider<HistoryBloc>(
          create: (_) => HistoryBloc(repository: requestRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Medical Request',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('ar', ''),
        ],
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeScreen(),
          '/import': (_) => const ImportScreen(),
          '/items': (_) => const ItemsScreen(),
          '/request': (_) => const RequestScreen(),
          '/history': (_) => const HistoryScreen(),
        },
      ),
    );
  }
}
