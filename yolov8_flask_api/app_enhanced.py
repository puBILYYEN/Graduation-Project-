# ==========================================================================
# @檔案: app_enhanced.py
# @描述: 智慧營養分析後端主程式，提供 AI 功能 API，並整合即時通訊。
# ==========================================================================
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from ultralytics import YOLO
from PIL import Image, ImageDraw
import os
import json
from datetime import datetime
from dotenv import load_dotenv

# --- 區塊: 服務與工具導入 ---
# 導入自訂的日誌、Firebase 和 RAG 服務模組。
from utils.logger import logger
from services.firebase_service import firebase_service
from services.rag_service import rag_service

# --- 區塊: 環境變數載入 ---
# 從專案根目錄的 .env 檔案中載入環境變數 (例如 API Keys, 設定路徑)。
load_dotenv()

# --- 區塊: Flask 應用程式初始化 ---
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key-here') # 用於 session 和 socket.io 安全
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 設定上傳檔案大小上限為 16MB

# --- 區塊: 跨域資源共享 (CORS) 設定 ---
# 允許所有來源的跨域請求，方便前端 App (Flutter Web/Mobile) 呼叫。
CORS(app, resources={r"/*": {"origins": "*"}})

# --- 區塊: Socket.IO 初始化 ---
# 啟用 Socket.IO 以進行即時雙向通訊。
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

# --- 區塊: 靜態檔案與上傳資料夾設定 ---
UPLOAD_FOLDER = 'static'
os.makedirs(UPLOAD_FOLDER, exist_ok=True) # 確保資料夾存在

# --- 區塊: YOLO 模型與類別載入 ---
logger.info("正在載入 YOLO 模型...")
MODEL_PATH = os.getenv('YOLO_MODEL_PATH', '初試v2.pt')
CLASSES_PATH = os.getenv('YOLO_CLASSES_PATH', 'classes.txt')

# 載入食物類別名稱
try:
    with open(CLASSES_PATH, 'r', encoding='utf-8') as f:
        class_names = [line.strip() for line in f.readlines()]
    logger.info(f"已載入 {len(class_names)} 個食物類別")
except Exception as e:
    logger.log_error_with_trace(e, "載入類別檔案")
    class_names = []

# 載入 YOLO 模型主體
try:
    model = YOLO(MODEL_PATH)
    logger.info("YOLO 模型載入成功")
except Exception as e:
    logger.log_error_with_trace(e, "載入 YOLO 模型")
    model = None

# --- 區塊: 服務初始化 ---
@app.before_request
def before_first_request():
    """
    @裝飾器: before_request
    @描述: 在處理第一個請求前執行一次，用於初始化各種服務，
           例如 RAG 服務和向量資料庫，避免每次請求都重複初始化。
    """
    # 使用 hasattr 檢查確保此初始化邏輯只執行一次。
    if not hasattr(app, '_services_initialized'):
        logger.info("正在初始化服務...")

        # 如果 RAG 服務可用，則進行初始化。
        if rag_service.is_available():
            # 嘗試從本地檔案載入現有的向量資料庫。
            if not rag_service.load_vector_store():
                # 如果本地不存在，則從 Firebase 獲取資料來建立一個新的向量資料庫。
                if firebase_service.is_available():
                    logger.info("從 Firebase 建立向量資料庫...")
                    nutrition_data = firebase_service.get_all_nutrition_data()
                    if nutrition_data:
                        rag_service.build_vector_store(nutrition_data)
                    else:
                        logger.warning("Firebase 中沒有營養資料，使用空向量資料庫")

        app._services_initialized = True
        logger.info("服務初始化完成")


# --- 區塊: API 路由 (Routes) ---

@app.route('/')
def index():
    """
    @路由: /
    @方法: GET
    @描述: 應用程式的首頁，通常用於測試或提供一個簡單的歡迎頁面。
    """
    logger.log_request('/', 'GET')
    return render_template("index.html")


@app.route('/health', methods=['GET'])
def health_check():
    """
    @路由: /health
    @方法: GET
    @描述: 健康檢查端點，用於監控服務是否正常運行。
    @返回: JSON 物件，包含各個子服務 (YOLO, Firebase, RAG) 的狀態。
    """
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


@app.route('/predict', methods=['POST'])
def predict():
    """
    @路由: /predict
    @方法: POST
    @描述: 傳統的 YOLO 圖片辨識端點。接收一張圖片，返回辨識結果
           和由 Gemini 生成的基本說明。
    @參數 (form-data):
        - image: 圖片檔案。
    @返回: JSON 物件，包含辨識出的物件、處理後的圖片路徑及文字說明。
    """
    logger.log_request('/predict', 'POST')

    # 檢查請求中是否包含圖片檔案
    if 'image' not in request.files:
        logger.error("請求中沒有圖片")
        return jsonify({'error': 'No image uploaded'}), 400

    # 檢查 YOLO 模型是否已成功載入
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

        # 執行 YOLO 辨識
        results = model(image_path)
        result = results[0]

        # 準備在圖片上繪製辨識框
        img = Image.open(image_path)
        draw = ImageDraw.Draw(img)

        predictions = []
        detected_foods = []

        # 遍歷所有辨識到的物件
        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            cls_id = int(box.cls[0].item())
            confidence = round(float(box.conf[0].item()), 2)
            label = class_names[cls_id] if cls_id < len(class_names) else f'class_{cls_id}'

            # 在圖片上繪製紅色的框和標籤
            draw.rectangle([x1, y1, x2, y2], outline="red", width=3)
            draw.text((x1, y1), f'{label} ({confidence})', fill="red")

            predictions.append({
                'class_id': cls_id,
                'class_name': label,
                'confidence': confidence
            })
            detected_foods.append(label)

        logger.log_yolo_prediction(filename, len(predictions))

        # 儲存帶有辨識框的圖片
        output_filename = f"output_{filename}"
        output_path = os.path.join(UPLOAD_FOLDER, output_filename)
        img.save(output_path)

        # 呼叫輔助函數，使用 Gemini API 生成基本說明和建議
        gemini_reply = _generate_basic_explanation(predictions)
        diet_advice = _generate_basic_diet_advice(predictions)

        # 準備要返回的 JSON 資料
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


@app.route('/analyze_nutrition', methods=['POST'])
def analyze_nutrition():
    """
    @路由: /analyze_nutrition
    @方法: POST
    @描述: 進階的個性化營養分析端點。結合 YOLO 辨識、使用者資料和 RAG 服務
           來提供個人化的飲食建議。
    @參數 (form-data):
        - image: 圖片檔案。
        - user_id (str, optional): 使用者 ID，用於獲取個人化資料。
    @返回: JSON 物件，包含辨識結果和個人化建議。
    """
    logger.log_request('/analyze_nutrition', 'POST')

    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    try:
        # 步驟 1: 執行 YOLO 辨識 (與 /predict 類似)
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
            label = class_names[cls_id] if cls_id < len(class_names) else f'class_{cls_id}'
            predictions.append({'class_id': cls_id, 'class_name': label, 'confidence': round(float(box.conf[0].item()), 2)})
            detected_foods.append(label)

        # 步驟 2: 如果提供了 user_id，從 Firebase 獲取使用者資料和用餐歷史。
        user_id = request.form.get('user_id')
        user_profile = None
        meal_history = None
        if user_id and firebase_service.is_available():
            user_profile = firebase_service.get_user_profile(user_id)
            meal_history = firebase_service.get_user_meal_history(user_id, limit=5)

        # 步驟 3: 使用 RAG 服務生成個人化建議。
        personalized_advice = ""
        if rag_service.is_available():
            personalized_advice = rag_service.generate_personalized_advice(
                detected_foods,
                user_profile,
                meal_history
            )

        # 步驟 4: 如果提供了 user_id，將此次用餐記錄儲存到 Firebase。
        if user_id and firebase_service.is_available():
            meal_data = {
                'timestamp': datetime.now().isoformat(),
                'foods': detected_foods,
                'predictions': predictions,
                'image_path': filename
            }
            firebase_service.save_meal_record(user_id, meal_data)

        # 準備回應
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


# --- 區塊: Socket.IO 事件處理 ---

@socketio.on('connect')
def handle_connect():
    """
    @事件: connect
    @描述: 當有客戶端成功建立 WebSocket 連線時觸發。
    """
    logger.log_socket_event('connect', f'客戶端已連接')
    emit('connection_response', {'status': 'connected', 'timestamp': datetime.now().isoformat()})


@socketio.on('disconnect')
def handle_disconnect():
    """
    @事件: disconnect
    @描述: 當有客戶端斷開 WebSocket 連線時觸發。
    """
    logger.log_socket_event('disconnect', '客戶端已斷開')


@socketio.on('rag_question')
def handle_rag_question(data):
    """
    @事件: rag_question
    @描述: 處理來自客戶端的即時 RAG (檢索增強生成) 問題。
    @參數 (data):
        - question (str): 使用者提出的問題。
        - user_id (str, optional): 使用者 ID，用於獲取個人化資料。
    @發送 (emit):
        - 'rag_response': 成功時返回答案。
        - 'rag_error': 失敗時返回錯誤訊息。
    """
    try:
        question = data.get('question', '')
        user_id = data.get('user_id')
        logger.log_socket_event('rag_question', f'問題: {question[:50]}...')

        # 獲取使用者資料以提供更個人化的回答
        user_profile = None
        meal_history = None
        if user_id and firebase_service.is_available():
            user_profile = firebase_service.get_user_profile(user_id)
            meal_history = firebase_service.get_user_meal_history(user_id, limit=5)

        # 使用 RAG 服務生成回答
        if rag_service.is_available():
            # 步驟 1: 從向量資料庫查詢與問題相關的營養資料。
            relevant_data = rag_service.query_nutrition(question, k=3)

            # 步驟 2: 構建提供給大型語言模型的上下文 (Context)。
            context = "\n\n".join([rag_service._format_nutrition_document(item) for item in relevant_data])

            # 步驟 3: 構建完整的提示 (Prompt)。
            prompt = f"""使用者問題：{question}\n\n相關營養資訊：\n{context}\n"""
            if user_profile:
                prompt += f"\n使用者資料：{json.dumps(user_profile, ensure_ascii=False)}"
            prompt += "\n\n請用繁體中文回答，簡潔專業。"

            # 步驟 4: 呼叫 Gemini 模型生成回答。
            import google.generativeai as genai
            model = genai.GenerativeModel('gemini-2.0-flash-exp')
            response = model.generate_content(prompt)
            answer = response.text

            # 步驟 5: 透過 WebSocket 將回答發送回客戶端。
            emit('rag_response', {
                'question': question,
                'answer': answer,
                'relevant_data': relevant_data,
                'timestamp': datetime.now().isoformat()
            })
            logger.log_rag_query(question, len(answer))
        else:
            emit('rag_error', {'message': 'RAG 服務未啟用', 'timestamp': datetime.now().isoformat()})
    except Exception as e:
        logger.log_error_with_trace(e, "處理 RAG 問題")
        emit('rag_error', {'message': str(e), 'timestamp': datetime.now().isoformat()})


@socketio.on('nutrition_data')
def handle_nutrition_data(data):
    """
    @事件: nutrition_data
    @描述: 接收客戶端發送的營養數據並儲存到 Firebase。
    """
    try:
        logger.log_socket_event('nutrition_data', f'收到營養數據')
        user_id = data.get('user_id')
        if user_id and firebase_service.is_available():
            firebase_service.save_meal_record(user_id, data)
            emit('nutrition_data_received', {'status': 'success', 'timestamp': datetime.now().isoformat()})
        else:
            emit('nutrition_data_received', {'status': 'no_firebase', 'message': 'Firebase 未啟用或缺少 user_id', 'timestamp': datetime.now().isoformat()})
    except Exception as e:
        logger.log_error_with_trace(e, "接收營養數據")
        emit('error', {'message': str(e)})


# --- 區塊: 輔助函數 ---

def _generate_basic_explanation(predictions):
    """生成關於辨識物件的基本說明（由 Gemini API 提供）。"""
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
    """根據辨識結果生成基本的飲食建議（由 Gemini API 提供）。"""
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


# --- 區塊: 程式啟動點 ---
if __name__ == '__main__':
    logger.info("=" * 60)
    logger.info("營養知識 RAG 系統啟動")
    logger.info(f"Flask 環境: {os.getenv('FLASK_ENV', 'production')}")
    logger.info(f"監聽位址: {os.getenv('FLASK_HOST', '0.0.0.0')}:{os.getenv('FLASK_PORT', '5000')}")
    logger.info("=" * 60)

    # 使用 socketio.run 來啟動伺服器，以確保 Flask 和 Socket.IO 都能正常運作。
    socketio.run(
        app,
        host=os.getenv('FLASK_HOST', '0.0.0.0'),
        port=int(os.getenv('FLASK_PORT', 5000)),
        debug=os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    )
