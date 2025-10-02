// ----- [pages/auth/login_page.dart] 開始 -----
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// 登入頁面狀態管理類別 - 處理登入邏輯和使用者介面狀態
class _LoginPageState extends State<LoginPage> {
  // 文字輸入控制器：管理使用者名稱輸入框的文字內容
  final TextEditingController _usernameController = TextEditingController();

  // 文字輸入控制器：管理密碼輸入框的文字內容
  final TextEditingController _passwordController = TextEditingController();

  // 表單驗證鍵：用於觸發表單驗證和取得表單狀態
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 密碼可見性控制：true 表示密碼以明文顯示，false 表示以密碼符號顯示
  bool _isPasswordVisible = false;

  // 一般登入載入狀態：true 表示正在進行登入處理，顯示載入指示器
  bool _isLoading = false;

  // Google 登入載入狀態：true 表示正在進行 Google 登入處理
  bool _isGoogleLoading = false;

  // Google 登入配置物件 - 設定登入範圍和權限
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'], // 請求存取使用者的電子郵件和基本個人資料
  );

  /// 處理一般登入流程 - 驗證表單並執行登入邏輯
  void _handleLogin() async {
    // 驗證表單輸入：檢查所有必填欄位是否符合驗證規則
    if (!_formKey.currentState!.validate()) return;

    // 設定載入狀態為真：觸發 UI 重新渲染以顯示載入指示器
    setState(() {
      _isLoading = true;
    });

    // 模擬登入過程：在實際應用中這裡會呼叫 API 進行身分驗證
    await Future.delayed(const Duration(seconds: 1));

    // 關閉載入狀態：隱藏載入指示器
    setState(() {
      _isLoading = false;
    });

    // 檢查 Widget 是否仍在 Widget 樹中：防止在異步操作完成後對已銷毀的 Widget 進行操作
    if (!context.mounted) return;

    // 顯示登入成功的訊息給使用者
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('登入成功'), // 成功訊息內容
        backgroundColor: Colors.green, // 設定為綠色背景表示成功
      ),
    );

    // 導航到主框架頁面：使用 pushReplacement 替換當前頁面，防止使用者按返回鍵回到登入頁面
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainFrame()),
    );
  }

  /// Google 登入處理方法 - 執行 Google 第三方登入流程
  Future<void> _handleGoogleSignIn() async {
    // 設定 Google 登入載入狀態：顯示載入指示器表示正在處理 Google 登入
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      // 執行 Google 登入：開啟 Google 登入對話框讓使用者選擇帳戶
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      // 檢查是否成功取得使用者帳戶資訊
      if (account != null) {
        // 記錄成功登入的資訊到日誌系統
        await log('Google 登入成功: ${account.displayName} (${account.email})');

        // 檢查 Widget 是否仍在 Widget 樹中
        if (!context.mounted) return;

        // 顯示歡迎訊息：使用使用者的 Google 顯示名稱
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('歡迎 ${account.displayName}！'), // 個人化歡迎訊息
            backgroundColor: Colors.green, // 綠色背景表示成功
          ),
        );

        // 導航到主框架頁面：登入成功後進入應用程式主要功能
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainFrame()),
        );
      } else {
        // 使用者取消登入：記錄取消事件到日誌
        await log('Google 登入被取消');
      }
    } catch (error) {
      // 捕獲並記錄 Google 登入過程中的任何錯誤
      await log('Google 登入錯誤: $error');

      // 檢查 Widget 是否仍在 Widget 樹中
      if (!context.mounted) return;

      // 顯示錯誤訊息給使用者
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google 登入失敗: $error'), // 顯示具體錯誤訊息
          backgroundColor: Colors.red, // 紅色背景表示錯誤
        ),
      );
    } finally {
      // 無論成功或失敗都要執行的清理工作：關閉載入狀態
      if (mounted) {
        // 檢查 Widget 是否仍然存在
        setState(() {
          _isGoogleLoading = false; // 隱藏 Google 登入載入指示器
        });
      }
    }
  }

  /// 建構登入頁面的使用者介面
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 設定頁面背景為淺灰色
      body: SafeArea(
        // 確保內容不會被系統狀態列或導航列遮擋
        child: Center(
          // 將所有內容置中顯示
          child: SingleChildScrollView(
            // 允許頁面在內容過長時可以滾動
            padding: const EdgeInsets.all(32.0), // 設定頁面內邊距
            child: Form(
              // 表單容器，用於管理輸入驗證
              key: _formKey, // 綁定表單驗證鍵
              child: Column(
                // 垂直排列所有 UI 元件
                mainAxisAlignment: MainAxisAlignment.center, // 垂直置中對齊
                children: [
                  // 使用者頭像圓形容器
                  Container(
                    width: 120, // 設定寬度為 120 像素
                    height: 120, // 設定高度為 120 像素
                    decoration: BoxDecoration(
                      color: Colors.blue, // 設定背景顏色為藍色
                      borderRadius: BorderRadius.circular(60), // 設定圓角半徑使其成為圓形
                    ),
                    child: const Icon(
                      Icons.person, // 使用人物圖示
                      size: 60, // 設定圖示大小
                      color: Colors.white, // 設定圖示顏色為白色
                    ),
                  ),
                  const SizedBox(height: 32), // 垂直間距

                  // 主標題文字
                  const Text(
                    '歡迎回來',
                    style: TextStyle(
                      fontSize: 28, // 設定字體大小
                      fontWeight: FontWeight.bold, // 設定字體粗細為粗體
                      color: Colors.black87, // 設定字體顏色
                    ),
                  ),
                  const SizedBox(height: 8), // 垂直間距

                  // 副標題說明文字
                  const Text(
                    '請輸入您的帳號資訊',
                    style: TextStyle(fontSize: 16, color: Colors.grey), // 灰色副標題
                  ),
                  const SizedBox(height: 8), // 垂直間距

                  // 測試帳號資訊提示
                  const Text(
                    '測試帳號: test\n測試密碼: 123456',
                    style:
                        TextStyle(fontSize: 14, color: Colors.blue), // 藍色提示文字
                    textAlign: TextAlign.center, // 文字置中對齊
                  ),
                  const SizedBox(height: 32), // 垂直間距

                  // 帳號輸入欄位
                  TextFormField(
                    controller: _usernameController, // 綁定帳號輸入控制器
                    decoration: InputDecoration(
                      labelText: '帳號', // 輸入欄位標籤
                      hintText: '請輸入您的帳號', // 提示文字
                      prefixIcon: const Icon(Icons.person_outline), // 前置圖示
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), // 設定圓角邊框
                      ),
                      filled: true, // 啟用填充色
                      fillColor: Colors.white, // 設定填充顏色為白色
                    ),
                    // 輸入驗證函數
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入帳號'; // 空值驗證錯誤訊息
                      }
                      if (value.length < 3) {
                        return '帳號至少需要3個字元'; // 長度驗證錯誤訊息
                      }
                      return null; // 驗證通過回傳 null
                    },
                  ),
                  const SizedBox(height: 16), // 垂直間距

                  // 密碼輸入欄位
                  TextFormField(
                    controller: _passwordController, // 綁定密碼輸入控制器
                    obscureText: !_isPasswordVisible, // 根據可見性狀態決定是否隱藏密碼
                    decoration: InputDecoration(
                      labelText: '密碼', // 輸入欄位標籤
                      hintText: '請輸入您的密碼', // 提示文字
                      prefixIcon: const Icon(Icons.lock_outline), // 前置鎖定圖示
                      // 密碼可見性切換按鈕
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility // 顯示眼睛圖示（密碼可見）
                              : Icons.visibility_off, // 顯示關閉眼睛圖示（密碼隱藏）
                        ),
                        onPressed: () {
                          // 切換密碼可見性狀態
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), // 設定圓角邊框
                      ),
                      filled: true, // 啟用填充色
                      fillColor: Colors.white, // 設定填充顏色為白色
                    ),
                    // 密碼輸入驗證函數
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '請輸入密碼'; // 空值驗證錯誤訊息
                      }
                      if (value.length < 6) {
                        return '密碼至少需要6個字元'; // 長度驗證錯誤訊息
                      }
                      return null; // 驗證通過回傳 null
                    },
                  ),
                  const SizedBox(height: 32), // 垂直間距

                  // 登入按鈕容器
                  SizedBox(
                    width: double.infinity, // 設定按鈕寬度為父容器的全寬
                    height: 50, // 設定按鈕高度
                    child: ElevatedButton(
                      // 根據載入狀態決定是否啟用按鈕：載入中時禁用按鈕
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // 按鈕背景顏色
                        foregroundColor: Colors.white, // 按鈕文字顏色
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // 按鈕圓角
                        ),
                        elevation: 2, // 按鈕陰影高度
                      ),
                      // 按鈕內容：根據載入狀態顯示不同內容
                      child: _isLoading
                          ? const Row(
                              // 載入中顯示進度指示器和文字
                              mainAxisAlignment:
                                  MainAxisAlignment.center, // 水平置中
                              children: [
                                SizedBox(
                                  width: 20, // 進度指示器寬度
                                  height: 20, // 進度指示器高度
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, // 進度條線條寬度
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white), // 設定進度條顏色為白色
                                  ),
                                ),
                                SizedBox(width: 12), // 間距
                                Text('登入中...'), // 載入中文字
                              ],
                            )
                          : const Text(
                              // 正常狀態顯示登入文字
                              '登入',
                              style: TextStyle(
                                fontSize: 16, // 文字大小
                                fontWeight: FontWeight.bold, // 粗體文字
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16), // 垂直間距

                  // 分隔線區域：顯示「或」字樣的分隔線
                  Row(
                    children: [
                      // 左側分隔線：自動擴展填滿可用空間
                      Expanded(child: Divider(color: Colors.grey[400])),
                      // 中間「或」字文字
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16), // 水平內邊距
                        child: Text(
                          '或',
                          style: TextStyle(color: Colors.grey[600]), // 灰色文字
                        ),
                      ),
                      // 右側分隔線：自動擴展填滿可用空間
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),
                  const SizedBox(height: 16), // 垂直間距

                  // Google 登入按鈕容器
                  SizedBox(
                    width: double.infinity, // 設定按鈕寬度為父容器的全寬
                    height: 50, // 設定按鈕高度
                    child: OutlinedButton.icon(
                      // 帶圖示的外框按鈕
                      // 根據 Google 登入載入狀態決定是否啟用按鈕
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white, // 白色背景
                        foregroundColor: Colors.black87, // 深灰色文字
                        side: BorderSide(color: Colors.grey[300]!), // 淺灰色邊框
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // 圓角邊框
                        ),
                      ),
                      // 按鈕圖示：根據載入狀態顯示不同圖示
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              // 載入中顯示進度指示器
                              width: 20, // 指示器寬度
                              height: 20, // 指示器高度
                              child: CircularProgressIndicator(
                                strokeWidth: 2, // 進度條線條寬度
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue), // 藍色進度條
                              ),
                            )
                          : Image.network(
                              // 正常狀態顯示 Google Logo
                              'https://developers.google.com/identity/images/g-logo.png',
                              width: 20, // 圖片寬度
                              height: 20, // 圖片高度
                              // 圖片載入失敗時的備用方案
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.g_mobiledata,
                                    size: 20); // 顯示 G 圖示
                              },
                            ),
                      // 按鈕文字標籤：根據載入狀態顯示不同文字
                      label: Text(
                        _isGoogleLoading ? '登入中...' : '使用 Google 登入', // 動態文字內容
                        style: const TextStyle(
                          fontSize: 16, // 文字大小
                          fontWeight: FontWeight.w500, // 中等粗細文字
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24), // 垂直間距

                  // 註冊連結區域：引導使用者到註冊頁面
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // 水平置中對齊
                    children: [
                      const Text('還沒有帳號？'), // 提示文字
                      TextButton(
                        // 文字按鈕
                        onPressed: () {
                          // 導航到註冊頁面：使用 push 方式保留返回功能
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          '立即註冊', // 註冊按鈕文字
                          style: TextStyle(fontWeight: FontWeight.bold), // 粗體文字
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 資源清理方法 - 在 Widget 被銷毀時釋放資源
  @override
  void dispose() {
    // 釋放帳號輸入控制器：防止記憶體洩漏
    _usernameController.dispose();
    // 釋放密碼輸入控制器：防止記憶體洩漏
    _passwordController.dispose();
    // 呼叫父類別的 dispose 方法：執行標準清理流程
    super.dispose();
  }
}

// ====================================================================
// 註冊頁面 (Register Page)
// ====================================================================
/*
模組化建議：【頁面模組 - pages/auth/register_page.dart】
RegisterPage 和 _RegisterPageState 可以獨立成為註冊頁面模組。
與登入頁面相關，同樣適合放在 pages/auth/ 目錄下。
*/
// ----- [pages/auth/login_page.dart] 結束 -----