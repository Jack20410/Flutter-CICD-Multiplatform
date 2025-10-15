import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'providers/note_provider.dart';
import 'screens/notes_list_screen.dart';
import 'services/semantic_search_service.dart';
import 'services/auth_service.dart'; // Add this import
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize database factory for desktop platforms
  await SemanticSearchService.initializeDatabaseFactory();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Changed from ChangeNotifierProvider to MultiProvider
      providers: [
        ChangeNotifierProvider(create: (context) => NoteProvider()),
        ChangeNotifierProvider(
            create: (context) => AuthService()), // Add AuthService
      ],
      child: const CupertinoApp(
        title: 'Flutter Notes',
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
          scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        ),
        debugShowCheckedModeBanner: false,
        home: NotesListScreen(),
      ),
    );
  }
}
