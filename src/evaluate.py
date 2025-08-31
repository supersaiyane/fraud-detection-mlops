# Evaluation script
import json, pandas as pd, xgboost as xgb
from sklearn.metrics import roc_auc_score

if __name__ == "__main__":
    test_df = pd.read_csv("/opt/ml/input/data/test/test.csv")
    X_test, y_test = test_df.drop("label", axis=1), test_df["label"]

    dtest = xgb.DMatrix(X_test)
    model = xgb.Booster()
    model.load_model("/opt/ml/model/xgb_model.json")

    preds = model.predict(dtest)
    auc = roc_auc_score(y_test, preds)

    with open("/opt/ml/output/metrics.json", "w") as f:
        json.dump({"auc": auc}, f)
