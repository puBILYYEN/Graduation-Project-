"""
營養知識 RAG 系統 - Flask 後端（最終版本）
整合 YOLO + Firebase + Langchain + Chroma + Gemini + Socket.IO
基於 Chatbot_Chroma.ipynb 和原有架構
"""
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from flask_socketio import SocketIO, emit
import pytorch_fix  # 修復 PyTorch 2.6+ 權重載入問題
from ultralytics import YOLO
from PIL import Image, ImageDraw
import os
import json
from datetime import datetime
from dotenv import load_dotenv

# 載入環境變數
load_dotenv()

# 導入自訂服務
from utils.logger import logger
from services.firebase_service import firebase_service
from services.rag_service_chroma import rag_service_chroma
from services.nutrition_data_manager import nutrition_manager
from services.llm_provider import get_llm_manager

# ===== Flask 應用初始化 =====
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key-here')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# 啟用 CORS
CORS(app, resources={r"/*": {"origins": "*"}})

# 啟用 Socket.IO
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

# ===== 設置上傳資料夾 =====
UPLOAD_FOLDER = 'static'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ===== 載入 YOLO 模型和類別 =====
logger.info("正在載入 YOLO 模型...")
MODEL_PATH = os.getenv('YOLO_MODEL_PATH', 'a11171200.pt')
CLASSES_PATH = os.getenv('YOLO_CLASSES_PATH', 'classes.txt')

try:
    with open(CLASSES_PATH, 'r', encoding='utf-8') as f:
        class_names = [line.strip() for line in f.readlines()]
    logger.info(f"已載入 {len(class_names)} 個食物類別")
except Exception as e:
    logger.log_error_with_trace(e, "載入類別檔案")
    class_names = []

try:
    model = YOLO(MODEL_PATH)
    logger.info("YOLO 模型載入成功")
except Exception as e:
    logger.log_error_with_trace(e, "載入 YOLO 模型")
    model = None

# ===== 應用啟動時初始化服務 =====
_services_initialized = False

def initialize_services():
    """初始化所有服務"""
    global _services_initialized

    if _services_initialized:
        return

    logger.info("=" * 60)
    logger.info("正在初始化服務...")
    logger.info("=" * 60)

    # 1. 載入營養資料庫
    if nutrition_manager.load_nutrition_database():
        logger.info(f"✓ 營養資料庫載入成功")

        # 2. 初始化 Chroma 向量資料庫
        if rag_service_chroma.is_available():
            # 嘗試載入現有向量資料庫
            if not rag_service_chroma.load_vector_store():
                # 如果不存在，從營養資料建立
                logger.info("從營養資料建立 Chroma 向量資料庫...")
                nutrition_data = nutrition_manager.get_all_data_for_vector_store()

                if nutrition_data:
                    rag_service_chroma.build_vector_store(nutrition_data)
                    logger.info(f"✓ Chroma 向量資料庫建立成功")
                else:
                    logger.warning("! 沒有營養資料，使用空向量資料庫")
            else:
                logger.info(f"✓ Chroma 向量資料庫載入成功")
        else:
            logger.warning("! RAG 服務無法使用")

    # 3. 檢查 Firebase 狀態
    if firebase_service.is_available():
        logger.info(f"✓ Firebase 服務已連接")
    else:
        logger.warning("! Firebase 服務未啟用")

    _services_initialized = True
    logger.info("=" * 60)
    logger.info("所有服務初始化完成")
    logger.info("=" * 60)


# ===== 路由：首頁（美化狀態頁面） =====
@app.route('/')
def index():
    """首頁 - 顯示美化的系統狀態頁面"""
    logger.log_request('/', 'GET')
    return render_template('status.html')


# ===== 路由：健康檢查 =====
@app.route('/health', methods=['GET'])
def health_check():
    """健康檢查端點"""
    logger.log_request('/health', 'GET')

    status = {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'services': {
            'yolo': model is not None,
            'firebase': firebase_service.is_available(),
            'rag': rag_service_chroma.is_available(),
            'vector_store': rag_service_chroma.vector_store is not None,
            'nutrition_data': len(nutrition_manager.nutrition_data) if nutrition_manager else 0
        }
    }

    return jsonify(status)


# ===== 路由：YOLO 圖片辨識（原始端點，保持向後兼容） =====
@app.route('/predict', methods=['POST'])
def predict():
    """
    YOLO 圖片辨識端點（保持原有介面）
    """
    logger.log_request('/predict', 'POST')

    if 'image' not in request.files:
        logger.error("請求中沒有圖片")
        return jsonify({'error': 'No image uploaded'}), 400

    if model is None:
        logger.error("YOLO 模型未載入")
        return jsonify({'error': 'YOLO model not available'}), 500

    try:
        # 儲存上傳的圖片
        image = request.files['image']
        filename = f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{image.filename}"
        image_path = os.path.join(UPLOAD_FOLDER, filename)
        image.save(image_path)
        logger.info(f"圖片已儲存: {filename}")

        # YOLO 辨識
        results = model(image_path)
        result = results[0]

        # 繪製辨識框
        img = Image.open(image_path)
        draw = ImageDraw.Draw(img)

        predictions = []
        detected_foods = []

        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            cls_id = int(box.cls[0].item())
            confidence = round(float(box.conf[0].item()), 2)
            label = class_names[cls_id] if cls_id < len(class_names) else f'class_{cls_id}'

            draw.rectangle([x1, y1, x2, y2], outline="red", width=3)
            draw.text((x1, y1), f'{label} ({confidence})', fill="red")

            predictions.append({
                'class_id': cls_id,
                'class_name': label,
                'confidence': confidence
            })
            detected_foods.append(label)

        logger.log_yolo_prediction(filename, len(predictions))

        # 儲存處理後的圖片
        output_filename = f"output_{filename}"
        output_path = os.path.join(UPLOAD_FOLDER, output_filename)
        img.save(output_path)

        # 使用 LLM Manager（支援自動備援和翻譯）
        llm_manager = get_llm_manager()

        # 生成辨識結果說明
        explain_prompt = f"以下是物件偵測的結果，請用繁體中文簡單解釋：\n{json.dumps(predictions, ensure_ascii=False)}"
        explain_result = llm_manager.generate_with_translation(
            explain_prompt,
            context="食物辨識說明",
            temperature=0.7,
            max_tokens=500
        )
        gemini_reply = explain_result['text'] if explain_result['text'] else "無法生成說明"

        # 生成飲食建議（整合 RAG 系統）
        diet_advice = ""

        # 嘗試使用 RAG 生成個性化建議
        if rag_service_chroma.is_available():
            logger.info("使用 RAG 系統生成個性化飲食建議")
            try:
                # 從 request 獲取使用者ID（如果有提供）
                user_id = request.form.get('user_id', None)
                user_profile = {}
                meal_history = []

                if user_id and firebase_service.is_available():
                    user_profile = firebase_service.get_user_profile(user_id) or {}
                    meal_history = firebase_service.get_user_meal_history(user_id, limit=3) or []

                # 使用 RAG 生成個性化建議
                diet_advice = rag_service_chroma.generate_personalized_advice(
                    detected_foods,
                    user_profile,
                    meal_history
                )
                logger.info("✓ RAG 個性化建議生成成功")
            except Exception as e:
                logger.error(f"RAG 建議生成失敗: {e}")
                diet_advice = ""

        # 如果 RAG 失敗或不可用，使用 Gemini 備用方案
        if not diet_advice:
            logger.info("使用 Gemini 生成基礎飲食建議")
            diet_prompt = f"""以下是使用者拍攝的食物辨識結果：
{json.dumps(predictions, ensure_ascii=False)}

請用繁體中文給出飲食建議，包括健康搭配、熱量注意與份量建議。"""
            diet_result = llm_manager.generate_with_translation(
                diet_prompt,
                context="飲食建議",
                temperature=0.7,
                max_tokens=800
            )
            diet_advice = diet_result['text'] if diet_result['text'] else "無法生成建議"

        response_data = {
            'predictions': predictions,
            'image_path': f'/static/{output_filename}',
            'gemini_reply': gemini_reply,
            'diet_advice': diet_advice,
            'llm_provider': llm_manager.get_current_provider_name(),
            'timestamp': datetime.now().isoformat()
        }

        logger.info(f"辨識完成: {len(predictions)} 個物件")
        return jsonify(response_data)

    except Exception as e:
        logger.log_error_with_trace(e, "圖片辨識")
        return jsonify({'error': str(e)}), 500


# ===== 路由：個性化營養分析（使用 Chroma RAG） =====
@app.route('/analyze_nutrition', methods=['POST'])
def analyze_nutrition():
    """
    個性化營養分析端點（使用 Chroma + RAG）
    """
    logger.log_request('/analyze_nutrition', 'POST')

    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    try:
        # 1. YOLO 辨識
        image = request.files['image']
        filename = f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{image.filename}"
        image_path = os.path.join(UPLOAD_FOLDER, filename)
        image.save(image_path)

        results = model(image_path)
        result = results[0]

        predictions = []
        detected_foods = []

        for box in result.boxes:
            cls_id = int(box.cls[0].item())
            confidence = round(float(box.conf[0].item()), 2)
            label = class_names[cls_id] if cls_id < len(class_names) else f'class_{cls_id}'

            predictions.append({
                'class_id': cls_id,
                'class_name': label,
                'confidence': confidence
            })
            detected_foods.append(label)

        logger.log_yolo_prediction(filename, len(predictions))

        # 2. 獲取使用者資料
        user_id = request.form.get('user_id')
        user_profile = None
        meal_history = None

        if user_id and firebase_service.is_available():
            user_profile = firebase_service.get_user_profile(user_id)
            meal_history = firebase_service.get_user_meal_history(user_id, limit=5)

        # 3. 使用 Chroma RAG 生成個性化建議
        personalized_advice = ""
        if rag_service_chroma.is_available():
            personalized_advice = rag_service_chroma.generate_personalized_advice(
                detected_foods,
                user_profile,
                meal_history
            )
        else:
            personalized_advice = "RAG 服務未啟用，無法提供個性化建議"

        # 4. 儲存用餐記錄到 Firebase
        if user_id and firebase_service.is_available():
            meal_data = {
                'timestamp': datetime.now().isoformat(),
                'foods': detected_foods,
                'predictions': predictions,
                'image_path': filename
            }
            firebase_service.save_meal_record(user_id, meal_data)

        # 5. 返回結果
        response_data = {
            'predictions': predictions,
            'detected_foods': detected_foods,
            'personalized_advice': personalized_advice,
            'user_profile': user_profile,
            'meal_history': meal_history,
            'timestamp': datetime.now().isoformat()
        }

        logger.info(f"個性化分析完成: {len(detected_foods)} 種食物")
        return jsonify(response_data)

    except Exception as e:
        logger.log_error_with_trace(e, "營養分析")
        return jsonify({'error': str(e)}), 500


# ===== 路由：RAG 查詢端點 =====
@app.route('/rag_query', methods=['POST'])
def rag_query():
    """
    RAG 查詢端點（使用 Chroma）
    """
    logger.log_request('/rag_query', 'POST')

    try:
        data = request.get_json()
        question = data.get('question', '')

        if not question:
            return jsonify({'error': 'No question provided'}), 400

        # 使用 Chroma RAG 生成回答
        if rag_service_chroma.is_available():
            answer = rag_service_chroma.generate_answer_with_rag(question, k=3)

            return jsonify({
                'question': question,
                'answer': answer,
                'timestamp': datetime.now().isoformat()
            })
        else:
            return jsonify({'error': 'RAG service not available'}), 503

    except Exception as e:
        logger.log_error_with_trace(e, "RAG 查詢")
        return jsonify({'error': str(e)}), 500


# ===== Socket.IO 事件處理 =====
@socketio.on('connect')
def handle_connect():
    """客戶端連接"""
    logger.log_socket_event('connect', '客戶端已連接')
    emit('connection_response', {
        'status': 'connected',
        'timestamp': datetime.now().isoformat()
    })


@socketio.on('disconnect')
def handle_disconnect():
    """客戶端斷開"""
    logger.log_socket_event('disconnect', '客戶端已斷開')


@socketio.on('rag_question')
def handle_rag_question(data):
    """處理 RAG 問題（透過 Socket.IO）"""
    try:
        question = data.get('question', '')
        user_id = data.get('user_id')

        logger.log_socket_event('rag_question', f'問題: {question[:50]}...')

        # 使用 Chroma RAG 生成回答
        if rag_service_chroma.is_available():
            answer = rag_service_chroma.generate_answer_with_rag(question, k=3)

            emit('rag_response', {
                'question': question,
                'answer': answer,
                'timestamp': datetime.now().isoformat()
            })

            logger.log_rag_query(question, len(answer))
        else:
            emit('rag_error', {
                'message': 'RAG 服務未啟用',
                'timestamp': datetime.now().isoformat()
            })

    except Exception as e:
        logger.log_error_with_trace(e, "處理 RAG 問題")
        emit('rag_error', {
            'message': str(e),
            'timestamp': datetime.now().isoformat()
        })


@socketio.on('nutrition_data')
def handle_nutrition_data(data):
    """接收營養數據（透過 Socket.IO）"""
    try:
        logger.log_socket_event('nutrition_data', '收到營養數據')

        user_id = data.get('user_id')
        if user_id and firebase_service.is_available():
            firebase_service.save_meal_record(user_id, data)

            emit('nutrition_data_received', {
                'status': 'success',
                'timestamp': datetime.now().isoformat()
            })
        else:
            emit('nutrition_data_received', {
                'status': 'no_firebase',
                'message': 'Firebase 未啟用或缺少 user_id',
                'timestamp': datetime.now().isoformat()
            })

    except Exception as e:
        logger.log_error_with_trace(e, "接收營養數據")
        emit('error', {'message': str(e)})


@socketio.on('body_data_update')
def handle_body_data_update(data):
    """接收使用者身體數據更新（透過 Socket.IO）"""
    try:
        logger.log_socket_event('body_data_update', '收到身體數據更新')

        user_id = data.get('user_id')
        body_data = data.get('bodyData', {})

        if user_id and firebase_service.is_available():
            # 儲存身體數據到 Firebase
            firebase_service.update_user_body_data(user_id, body_data)

            emit('body_data_updated', {
                'status': 'success',
                'message': '身體數據已更新',
                'timestamp': datetime.now().isoformat()
            })

            logger.info(f"✓ 使用者 {user_id} 身體數據已更新")
        else:
            emit('body_data_updated', {
                'status': 'error',
                'message': 'Firebase 未啟用或缺少 user_id',
                'timestamp': datetime.now().isoformat()
            })

    except Exception as e:
        logger.log_error_with_trace(e, "更新身體數據")
        emit('error', {
            'message': f'更新身體數據失敗: {str(e)}',
            'timestamp': datetime.now().isoformat()
        })


# ===== 應用啟動時初始化服務 =====
# 注意：必須在模組級別執行，確保 gunicorn 也能初始化
logger.info("=" * 60)
logger.info("開始初始化服務...")
logger.info("=" * 60)
initialize_services()
logger.info("✓ 服務初始化完成")

# ===== 僅用於本地開發的啟動方式 =====
if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("營養知識 RAG 系統啟動（本地開發模式）")
    logger.info(f"Flask 環境: {os.getenv('FLASK_ENV', 'production')}")
    logger.info(f"監聽位址: {os.getenv('FLASK_HOST', '0.0.0.0')}:{os.getenv('FLASK_PORT', '5000')}")
    logger.info("=" * 60)

    # 使用 socketio.run 而不是 app.run（僅限本地開發）
    socketio.run(
        app,
        host=os.getenv('FLASK_HOST', '0.0.0.0'),
        port=int(os.getenv('FLASK_PORT', 5000)),
        debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    )
