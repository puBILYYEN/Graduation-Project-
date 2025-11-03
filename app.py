# 匯入需要的套件(程式包)，就像找朋友來幫忙一樣
from flask import Flask, request, jsonify, render_template  # Flask是用來建立網站的工具
from ultralytics import YOLO  # 組員提供的AI模型工具，用來辨識圖片
from PIL import Image, ImageDraw  # 圖片處理工具，可以在圖片上畫框框
import os, requests, json  # 檔案處理、網路請求、資料格式轉換的工具

# 建立Flask應用程式，就像蓋房子先打地基
app = Flask(__name__)  # 【我負責】建立網站主程式

# 設定圖片儲存的資料夾
UPLOAD_FOLDER = 'static'  # 【我負責】決定圖片要放在哪個資料夾
os.makedirs(UPLOAD_FOLDER, exist_ok=True)  # 【我負責】如果資料夾不存在就建立一個

# 讀取類別名稱 (組員的原始註解)
with open('classes.txt', 'r', encoding='utf-8') as f:  # 把AI能辨識的食物類別清單讀出來
    class_names = [line.strip() for line in f.readlines()]  # 把檔案每一行變成清單

# 載入 YOLO 模型 (組員的原始註解)
model = YOLO('初試v2.pt')  # 載入組員訓練好的AI模型檔案

# Gemini API 設定 (組員的原始註解)
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"  # Google AI的網址
GEMINI_API_KEY = "AIzaSyCMBtYrsRUqksBZtJUUcf5vO6GbzwN9CwE"  # 【我負責】API金鑰(建議用環境變數)

# ---------- Gemini API 呼叫函數 ---------- (組員的原始註解)
def ask_gemini(prompt: str):  # 【我可以改進】增加錯誤處理
    # 準備要送給Google AI的訊息格式
    headers = {  # 【我負責】設定訊息的格式說明
        "Content-Type": "application/json",  # 告訴Google我們要送JSON格式的資料
        "X-goog-api-key": GEMINI_API_KEY  # 驗證身份的密碼
    }
    body = {"contents": [{"parts": [{"text": prompt}]}]}  # 把要問的問題包裝好
    response = requests.post(GEMINI_API_URL, headers=headers, json=body)  # 【我負責】送出請求

    # 處理Google AI的回覆
    if response.status_code == 200:  # 如果成功收到回覆
        data = response.json()  # 把回覆轉換成Python可以理解的格式
        try:
            return data["candidates"][0]["content"]["parts"][0]["text"]  # 取出AI的回答
        except (KeyError, IndexError):  # 如果資料格式有問題
            return "Gemini 回覆解析失敗"  # 【我負責】回傳錯誤訊息
    else:
        return f"Gemini API 錯誤: {response.text}"  # 【我負責】回傳錯誤訊息

# ---------- Route: 首頁 ---------- (組員的原始註解)
@app.route('/')  # 【我完全負責】當使用者進入網站首頁時會執行這個
def index():
    return render_template("index.html")  # 【我負責】顯示首頁HTML檔案

# ---------- Route: 辨識圖片 ---------- (組員的原始註解)
@app.route('/predict', methods=['POST'])  # 【我完全負責】處理圖片上傳的網址
def predict():
    # 檢查使用者有沒有上傳圖片
    if 'image' not in request.files:  # 【我負責】檢查上傳的檔案
        return jsonify({'error': 'No image uploaded'}), 400  # 【我負責】回傳錯誤訊息

    # 取得上傳的圖片並儲存
    image = request.files['image']  # 【我負責】取得使用者上傳的圖片
    filename = image.filename  # 【我負責】取得圖片檔名
    image_path = os.path.join(UPLOAD_FOLDER, filename)  # 【我負責】決定圖片要存到哪裡
    image.save(image_path)  # 【我負責】把圖片存到電腦裡

    # 使用AI模型來辨識圖片內容
    results = model(image_path)  # 讓組員的AI模型分析圖片
    result = results[0]  # 取得辨識結果

    # 畫框與信心度 (組員的原始註解)
    img = Image.open(image_path)  # 【我可以美化】重新打開圖片準備加工
    draw = ImageDraw.Draw(img)  # 【我可以美化】準備在圖片上畫畫的工具

    predictions = []  # 建立一個空清單來放辨識結果
    for box in result.boxes:  # 組員的AI找到的每一個物件
        x1, y1, x2, y2 = map(int, box.xyxy[0])  # 組員的AI告訴我們框框的位置
        cls_id = int(box.cls[0].item())  # 組員的AI告訴我們這是什麼食物(編號)
        confidence = round(float(box.conf[0].item()), 2)  # 組員的AI告訴我們有多確定
        label = class_names[cls_id] if cls_id < len(class_names) else f'class_{cls_id}'  # 把編號轉換成食物名稱

        # 在圖片上畫紅色框框和文字
        draw.rectangle([x1, y1, x2, y2], outline="red", width=3)  # 【我可以美化】畫紅色框框
        draw.text((x1, y1), f'{label} ({confidence})', fill="red")  # 【我可以美化】寫上食物名稱和信心度

        # 把辨識結果加到清單裡
        predictions.append({'class_id': cls_id, 'class_name': label, 'confidence': confidence})

    # 儲存處理後圖片 (組員的原始註解)
    output_filename = f"output_{filename}"  # 【我可以改進】為新圖片取名字
    output_path = os.path.join(UPLOAD_FOLDER, output_filename)  # 【我負責】決定新圖片要存在哪裡
    img.save(output_path)  # 【我負責】儲存畫好框框的圖片

    # Gemini 物件解釋 (組員的原始註解)
    explain_prompt = f"以下是物件偵測的結果，請用中文簡單解釋：\n{json.dumps(predictions, ensure_ascii=False)}"  # 組員設計的提示詞
    gemini_reply = ask_gemini(explain_prompt)  # 【我可以加載入動畫】請Google AI回答

    # Gemini 飲食建議 (組員的原始註解)
    diet_prompt = f"以下是使用者拍攝的食物辨識結果：\n{json.dumps(predictions, ensure_ascii=False)}\n請用中文給出飲食建議，包括健康搭配、熱量注意與份量建議。"  # 組員設計的提示詞
    diet_advice = ask_gemini(diet_prompt)  # 【我可以加載入動畫】請Google AI給建議

    # 把所有結果整理好回傳給前端網頁
    return jsonify({  # 【我完全負責】決定要回傳什麼資料給網頁
        'predictions': predictions,  # 組員的AI辨識結果
        'image_path': f'/static/{output_filename}',  # 【我負責】處理後圖片的網址
        'gemini_reply': gemini_reply,  # Google AI的解釋
        'diet_advice': diet_advice  # Google AI的飲食建議
    })

# ---------- 啟動 Flask ---------- (組員的原始註解)
if __name__ == '__main__':  # 當直接執行這個程式時
    app.run(debug=True)  # 【我負責】啟動Flask網站(debug=True方便開發時除錯)
