import 'package:flutter/material.dart';

void main() {
  runApp(const TestNavigationApp());
}

class TestNavigationApp extends StatelessWidget {
  const TestNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '導航測試',
      home: const TestMainFrame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum TestPage {
  home,
  food,
  camera,
  exercise,
  analysis,
}

class TestMainFrame extends StatefulWidget {
  const TestMainFrame({super.key});

  @override
  State<TestMainFrame> createState() => _TestMainFrameState();
}

class _TestMainFrameState extends State<TestMainFrame> {
  TestPage _currentPage = TestPage.home;

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case TestPage.home:
        return const Center(child: Text('首頁', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
      case TestPage.food:
        return const Center(child: Text('飲食記錄', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
      case TestPage.camera:
        return const Center(child: Text('拍照辨識', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
      case TestPage.exercise:
        return const Center(child: Text('運動', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
      case TestPage.analysis:
        return const Center(child: Text('分析', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('當前頁面: ${_currentPage.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentPage.index,
        onTap: (index) {
          print('點擊索引: $index, 當前頁面: ${_currentPage.index}');
          setState(() {
            _currentPage = TestPage.values[index];
          });
          print('切換後頁面: ${_currentPage.index}');
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: '飲食記錄',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: '拍照辨識',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '運動',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '分析',
          ),
        ],
      ),
    );
  }
}