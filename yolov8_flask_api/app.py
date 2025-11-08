from flask import Flask, request, jsonify, render_template
from ultralytics import YOLO
from PIL import Image, ImageDraw
import os, requests, json

app = Flask(__name__)

UPLOAD_FOLDER = 'static'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# 讀取類別名稱
with open('classes.txt', 'r', encoding='utf-8') as f:
    class_names = [line.strip() for line in f.readlines()]

# 載入 YOLO 模型
model = YOLO('初試v2.pt')

# Gemini API 設定
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
GEMINI_API_KEY = "AIzaSyCMBtYrsRUqksBZtJUUcf5vO6GbzwN9CwE"  # ← 建議用環境變數

# ---------- Gemini API 呼叫函數 ----------
def ask_gemini(prompt: str):
    headers = {
        "Content-Type": "application/json",
        "X-goog-api-key": GEMINI_API_KEY
    }
    body = {"contents": [{"parts": [{"text": prompt}]}]}
    response = requests.post(GEMINI_API_URL, headers=headers, json=body)

    if response.status_code == 200:
        data = response.json()
        try:
            return data["candidates"][0]["content"]["parts"][0]["text"]
        except (KeyError, IndexError):
            return "Gemini 回覆解析失敗"
    else:
        return f"Gemini API 錯誤: {response.text}"

# ---------- Route: 首頁 ----------
@app.route('/')
def index():
    return render_template("index.html")

# ---------- Route: 辨識圖片 ----------
@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    image = request.files['image']
    filename = image.filename
    image_path = os.path.join(UPLOAD_FOLDER, filename)
    image.save(image_path)

    results = model(image_path)
    result = results[0]

    # 畫框與信心度
    img = Image.open(image_path)
    draw = ImageDraw.Draw(img)

    predictions = []
    for box in result.boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        cls_id = int(box.cls[0].item())
        confidence = round(float(box.conf[0].item()), 2)
        label = class_names[cls_id] if cls_id < len(class_names) else f'class_{cls_id}'

        draw.rectangle([x1, y1, x2, y2], outline="red", width=3)
        draw.text((x1, y1), f'{label} ({confidence})', fill="red")

        predictions.append({'class_id': cls_id, 'class_name': label, 'confidence': confidence})

    # 儲存處理後圖片
    output_filename = f"output_{filename}"
    output_path = os.path.join(UPLOAD_FOLDER, output_filename)
    img.save(output_path)

    # Gemini 物件解釋
    explain_prompt = f"以下是物件偵測的結果，請用中文簡單解釋：\n{json.dumps(predictions, ensure_ascii=False)}"
    gemini_reply = ask_gemini(explain_prompt)

    # Gemini 飲食建議
    diet_prompt = f"以下是使用者拍攝的食物辨識結果：\n{json.dumps(predictions, ensure_ascii=False)}\n請用中文給出飲食建議，包括健康搭配、熱量注意與份量建議。"
    diet_advice = ask_gemini(diet_prompt)

    return jsonify({
        'predictions': predictions,
        'image_path': f'/static/{output_filename}',
        'gemini_reply': gemini_reply,
        'diet_advice': diet_advice
    })

# ---------- 啟動 Flask ----------
if __name__ == '__main__':
    app.run(debug=True)
