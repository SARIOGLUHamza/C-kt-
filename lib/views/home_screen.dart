import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:deneme/controllers/simple_controller.dart';
import 'package:deneme/views/course_list_screen.dart';
import 'package:deneme/views/favorite_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late SimpleController controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.put(SimpleController());
    print(
      'HomeScreen: SimpleController başlatıldı ve yaşam döngüsü gözlemcisi eklendi.',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    print('HomeScreen: Yaşam döngüsü gözlemcisi kaldırıldı.');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print('Uygulama duraklatıldı (paused)');
      // Artık manual save gerekmiyor - her işlem direkt veritabanına kaydediliyor
    }
    if (state == AppLifecycleState.resumed) {
      print(
        'Uygulama devam ettirildi (resumed). Veriler yeniden yükleniyor...',
      );
      controller.onInit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dijital Defter")),
      body: IndexedStack(
        index: _selectedIndex,
        children: [CourseListScreen(), const FavoriteScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Dersler'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Favoriler',
          ),
        ],
      ),
    );
  }
}
