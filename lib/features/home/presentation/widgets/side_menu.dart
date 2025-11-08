import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/presentation/pages/login_page.dart';

/// 側邊選單
class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 處理選單項目點擊
  void _handleMenuItemTap(String itemName, BuildContext context) {
    print('📱 點擊選單項目: $itemName');

    // 根據不同的選單項目導航到對應頁面
    switch (itemName) {
      case '健康問卷':
        Navigator.pop(context);
        _showComingSoonDialog(context, '健康問卷');
        break;
      case '食譜':
        Navigator.pop(context);
        _showComingSoonDialog(context, '食譜');
        break;
      case '營養師諮詢':
        Navigator.pop(context);
        _showComingSoonDialog(context, '營養師諮詢');
        break;
      case '訂閱方案':
        Navigator.pop(context);
        _showComingSoonDialog(context, '訂閱方案');
        break;
      case '登出':
        _showLogoutDialog(context);
        break;
    }
  }

  // 顯示「開發中」對話框
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature 功能'),
        content: const Text('此功能開發中，敬請期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  // 顯示登出確認對話框
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認登出'),
          content: const Text('您確定要登出嗎?'),
          actions: [
            TextButton(
              onPressed: () {
                print('📱 取消登出');
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                print('📱 確認登出');
                Navigator.pop(context); // 關閉對話框
                Navigator.pop(context); // 關閉側邊選單
                await _performLogout();
              },
              child: const Text(
                '登出',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // 執行登出
  Future<void> _performLogout() async {
    try {
      print('🚪 用戶登出系統');

      // Firebase 登出
      await _auth.signOut();

      // 導航到登入頁面
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('💥 登出失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登出失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 用戶資訊標題
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 35, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? '使用者',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 選單項目列表
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(Icons.assignment, '健康問卷'),
                _buildMenuItem(Icons.restaurant_menu, '食譜'),
                _buildMenuItem(Icons.chat, '營養師諮詢'),
                _buildMenuItem(Icons.card_membership, '訂閱方案'),
              ],
            ),
          ),

          // 登出按鈕 (固定在底部)
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleMenuItemTap('登出', context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      '登出',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 建立選單項目
  Widget _buildMenuItem(IconData icon, String title) {
    return InkWell(
      onTap: () => _handleMenuItemTap(title, context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700], size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
