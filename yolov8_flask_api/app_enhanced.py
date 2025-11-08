"""
營養知識 RAG 系統 - Flask 後端
整合 YOLO + Firebase + Langchain + FAISS + Gemini + Socket.IO
"""
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from flask_socketio import SocketIO, emit
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
from services.rag_service import rag_service

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
MODEL_PATH = os.getenv('YOLO_MODEL_PATH', '初試v2.pt')
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

# ===== 初始化服務 =====
@app.before_request
def before_first_request():
    """在第一次請求前初始化服務"""
    if not hasattr(app, '_services_initialized'):
        logger.info("正在初始化服務...")

        # 初始化向量資料庫
        if rag_service.is_available():
            # 嘗試載入現有向量資料庫
            if not rag_service.load_vector_store():
                # 如果不存在，則從 Firebase 建立
                if firebase_service.is_available():
                    logger.info("從 Firebase 建立向量資料庫...")
                    nutrition_data = firebase_service.get_all_nutrition_data()
                    if nutrition_data:
                        rag_service.build_vector_store(nutrition_data)
                    else:
                        logger.warning("Firebase 中沒有營養資料，使用空向量資料庫")

        app._services_initialized = True
        logger.info("服務初始化完成")


# ===== 路由：首頁 =====
@app.route('/')
def index():
    """首頁"""
    logger.log_request('/', 'GET')
    return render_template("index.html")


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
            'rag': rag_service.is_available(),
            'vector_store': rag_service.vector_store is not None
        }
    }

    return jsonify(status)


# ===== 路由：YOLO 圖片辨識（保持原有介面） =====
@app.route('/predict', methods=['POST'])
def predict():
    """
    YOLO 圖片辨識端點
    保持原有介面不變，增加額外功能
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

            # 繪製框和標籤
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

        # 生成 Gemini 回應（保持原有功能）
        gemini_reply = _generate_basic_explanation(predictions)
        diet_advice = _generate_basic_diet_advice(predictions)

        # 準備回應
        response_data = {
            'predictions': predictions,
            'image_path': f'/static/{output_filename}',
            'gemini_reply': gemini_reply,
            'diet_advice': diet_advice,
            'timestamp': datetime.now().isoformat()
        }

        logger.info(f"辨識完成: {len(predictions)} 個物件")
        return jsonify(response_data)

    except Exception as e:
        logger.log_error_with_trace(e, "圖片辨識")
        return jsonify({'error': str(e)}), 500


# ===== 路由：個性化營養分析（新功能） =====
@app.route('/analyze_nutrition', methods=['POST'])
def analyze_nutrition():
    """
    個性化營養分析端點
    需要包含：
    - image: 圖片檔案
    - user_id: 使用者 ID（選填）
    """
    logger.log_request('/analyze_nutrition', 'POST')

    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    try:
        # 先進行 YOLO 辨識
        image = request.files['image']
        filename = f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{image.filename}"
        image_path = os.path.join(UPLOAD_FOLDER, filename)
        image.save(image_path)

        # YOLO 預測
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

        # 獲取使用者資料（如果提供）
        user_id = request.form.get('user_id')
        user_profile = None
        meal_history = None

        if user_id and firebase_service.is_available():
            user_profile = firebase_service.get_user_profile(user_id)
            meal_history = firebase_service.get_user_meal_history(user_id, limit=5)

        # 生成個性化建議
        personalized_advice = ""
        if rag_service.is_available():
            personalized_advice = rag_service.generate_personalized_advice(
                detected_foods,
                user_profile,
                meal_history
            )

        # 儲存用餐記錄到 Firebase
        if user_id and firebase_service.is_available():
            meal_data = {
                'timestamp': datetime.now().isoformat(),
                'foods': detected_foods,
                'predictions': predictions,
                'image_path': filename
            }
            firebase_service.save_meal_record(user_id, meal_data)

        response_data = {
            'predictions': predictions,
            'detected_foods': detected_foods,
            'personalized_advice': personalized_advice,
            'user_profile': user_profile,
            'timestamp': datetime.now().isoformat()
        }

        logger.info(f"個性化分析完成: {len(detected_foods)} 種食物")
        return jsonify(response_data)

    except Exception as e:
        logger.log_error_with_trace(e, "營養分析")
        return jsonify({'error': str(e)}), 500


# ===== Socket.IO 事件處理 =====
@socketio.on('connect')
def handle_connect():
    """客戶端連接"""
    logger.log_socket_event('connect', f'客戶端已連接')
    emit('connection_response', {'status': 'connected', 'timestamp': datetime.now().isoformat()})


@socketio.on('disconnect')
def handle_disconnect():
    """客戶端斷開"""
    logger.log_socket_event('disconnect', '客戶端已斷開')


@socketio.on('rag_question')
def handle_rag_question(data):
    """處理 RAG 問題"""
    try:
        question = data.get('question', '')
        user_id = data.get('user_id')

        logger.log_socket_event('rag_question', f'問題: {question[:50]}...')

        # 獲取使用者資料
        user_profile = None
        meal_history = None

        if user_id and firebase_service.is_available():
            user_profile = firebase_service.get_user_profile(user_id)
            meal_history = firebase_service.get_user_meal_history(user_id, limit=5)

        # 使用 RAG 生成回答
        if rag_service.is_available():
            # 查詢相關營養資料
            relevant_data = rag_service.query_nutrition(question, k=3)

            # 構建上下文
            context = "\n\n".join([
                rag_service._format_nutrition_document(item)
                for item in relevant_data
            ])

            # 生成回答
            prompt = f"""使用者問題：{question}

相關營養資訊：
{context}

"""
            if user_profile:
                prompt += f"\n使用者資料：{json.dumps(user_profile, ensure_ascii=False)}"

            prompt += "\n\n請用繁體中文回答，簡潔專業。"

            # 呼叫 Gemini
            import google.generativeai as genai
            model = genai.GenerativeModel('gemini-2.0-flash-exp')
            response = model.generate_content(prompt)

            answer = response.text

            emit('rag_response', {
                'question': question,
                'answer': answer,
                'relevant_data': relevant_data,
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
    """接收營養數據"""
    try:
        logger.log_socket_event('nutrition_data', f'收到營養數據')

        user_id = data.get('user_id')
        if user_id and firebase_service.is_available():
            # 儲存到 Firebase
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


# ===== 輔助函數 =====
def _generate_basic_explanation(predictions):
    """生成基本物件說明（保持原功能）"""
    try:
        import google.generativeai as genai
        genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

        prompt = f"以下是物件偵測的結果，請用中文簡單解釋：\n{json.dumps(predictions, ensure_ascii=False)}"

        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response = model.generate_content(prompt)

        return response.text

    except Exception as e:
        logger.log_error_with_trace(e, "生成基本說明")
        return "無法生成說明"


def _generate_basic_diet_advice(predictions):
    """生成基本飲食建議（保持原功能）"""
    try:
        import google.generativeai as genai
        genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

        prompt = f"""以下是使用者拍攝的食物辨識結果：
{json.dumps(predictions, ensure_ascii=False)}

請用中文給出飲食建議，包括健康搭配、熱量注意與份量建議。"""

        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        response = model.generate_content(prompt)

        return response.text

    except Exception as e:
        logger.log_error_with_trace(e, "生成飲食建議")
        return "無法生成建議"


# ===== 啟動應用 =====
if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("營養知識 RAG 系統啟動")
    logger.info(f"Flask 環境: {os.getenv('FLASK_ENV', 'production')}")
    logger.info(f"監聽位址: {os.getenv('FLASK_HOST', '0.0.0.0')}:{os.getenv('FLASK_PORT', '5000')}")
    logger.info("=" * 60)

    # 使用 socketio.run 而不是 app.run
    socketio.run(
        app,
        host=os.getenv('FLASK_HOST', '0.0.0.0'),
        port=int(os.getenv('FLASK_PORT', 5000)),
        debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    )
