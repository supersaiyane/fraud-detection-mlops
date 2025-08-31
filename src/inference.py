# Inference handler for SageMaker
import json, xgboost as xgb, numpy as np

model = None

def model_fn(model_dir):
    global model
    model = xgb.Booster()
    model.load_model(f"{model_dir}/xgb_model.json")
    return model

def input_fn(request_body, content_type="application/json"):
    data = json.loads(request_body)
    features = np.array(data["features"]).reshape(1, -1)
    return xgb.DMatrix(features)

def predict_fn(input_data, model):
    return model.predict(input_data)

def output_fn(prediction, content_type="application/json"):
    score = float(prediction[0])
    decision = "SUSPICIOUS" if score > 0.8 else "REVIEW" if score > 0.5 else "LEGIT"
    return json.dumps({"fraud_score": score, "decision": decision})
