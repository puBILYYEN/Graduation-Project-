import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 會員大頭照管理服務
class ProfilePhotoService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 上傳使用者大頭照
  ///
  /// [imageData] 圖片檔案數據
  /// [userId] 使用者 ID（如果不提供則使用當前登入使用者）
  ///
  /// 返回：上傳成功的圖片 URL
  Future<String> uploadProfilePhoto(Uint8List imageData, {String? userId}) async {
    try {
      // 使用當前使用者 ID 或提供的 userId
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('使用者未登入');
      }

      print('📸 開始上傳使用者大頭照: $uid');

      // 建立 Storage 路徑
      final String fileName = 'profile-photo.jpg';
      final String storagePath = 'user-profiles/$uid/$fileName';

      // 上傳到 Firebase Storage
      final Reference storageRef = _storage.ref().child(storagePath);

      // 設定 metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // 執行上傳
      final UploadTask uploadTask = storageRef.putData(imageData, metadata);
      final TaskSnapshot snapshot = await uploadTask;

      // 取得下載 URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ 大頭照上傳成功: $downloadUrl');

      // 更新 Firestore 中的使用者資料
      await _updateUserProfilePhoto(uid, downloadUrl);

      return downloadUrl;

    } catch (e) {
      print('💥 大頭照上傳失敗: $e');
      throw Exception('大頭照上傳失敗: $e');
    }
  }

  /// 刪除使用者大頭照
  ///
  /// [userId] 使用者 ID（如果不提供則使用當前登入使用者）
  Future<void> deleteProfilePhoto({String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('使用者未登入');
      }

      print('🗑️ 開始刪除使用者大頭照: $uid');

      // 刪除 Storage 中的檔案
      final String storagePath = 'user-profiles/$uid/profile-photo.jpg';
      final Reference storageRef = _storage.ref().child(storagePath);

      await storageRef.delete();
      print('✅ Storage 中的大頭照已刪除');

      // 更新 Firestore 中的使用者資料
      await _firestore.collection('member').doc(uid).update({
        'profilePhotoUrl': '',
        'profilePhotoThumbUrl': '',
        'hasProfilePhoto': false,
      });

      print('✅ 使用者大頭照刪除完成');

    } catch (e) {
      print('💥 大頭照刪除失敗: $e');
      throw Exception('大頭照刪除失敗: $e');
    }
  }

  /// 取得使用者大頭照 URL
  ///
  /// [userId] 使用者 ID（如果不提供則使用當前登入使用者）
  ///
  /// 返回：大頭照 URL，如果沒有則返回空字串
  Future<String> getProfilePhotoUrl({String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return '';
      }

      final DocumentSnapshot doc = await _firestore.collection('member').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['profilePhotoUrl'] ?? '';
      }

      return '';

    } catch (e) {
      print('💥 取得大頭照 URL 失敗: $e');
      return '';
    }
  }

  /// 檢查使用者是否有設定大頭照
  ///
  /// [userId] 使用者 ID（如果不提供則使用當前登入使用者）
  ///
  /// 返回：true 如果有大頭照，false 如果沒有
  Future<bool> hasProfilePhoto({String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return false;
      }

      final DocumentSnapshot doc = await _firestore.collection('member').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['hasProfilePhoto'] ?? false;
      }

      return false;

    } catch (e) {
      print('💥 檢查大頭照狀態失敗: $e');
      return false;
    }
  }

  /// 更新 Firestore 中的使用者大頭照資訊
  ///
  /// [userId] 使用者 ID
  /// [photoUrl] 大頭照 URL
  Future<void> _updateUserProfilePhoto(String userId, String photoUrl) async {
    await _firestore.collection('member').doc(userId).update({
      'profilePhotoUrl': photoUrl,
      'hasProfilePhoto': true,
      // TODO: 可以在這裡添加縮圖功能
      // 'profilePhotoThumbUrl': thumbnailUrl,
    });

    print('✅ Firestore 使用者大頭照資訊已更新');
  }

  /// 取得 Storage 中的大頭照檔案大小
  ///
  /// [userId] 使用者 ID
  ///
  /// 返回：檔案大小（bytes），如果檔案不存在則返回 0
  Future<int> getProfilePhotoSize({String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return 0;
      }

      final String storagePath = 'user-profiles/$uid/profile-photo.jpg';
      final Reference storageRef = _storage.ref().child(storagePath);

      final FullMetadata metadata = await storageRef.getMetadata();
      return metadata.size ?? 0;

    } catch (e) {
      print('💥 取得大頭照檔案大小失敗: $e');
      return 0;
    }
  }
}