import 'package:material_ui/material_ui.dart';
import 'features/events/event_picker_screen.dart';
import 'features/history/history_screen.dart';

void main() {
  runApp(const CcdRaffleApp());
}

class CcdRaffleApp extends StatelessWidget {
  const CcdRaffleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCD Raffle',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CCD Raffle')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.confirmation_number),
              label: const Text('New Sale'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const EventPickerScreen(),
                ));
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('History'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ));
              },
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
