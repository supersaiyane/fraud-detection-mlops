# Training script
import argparse, os, pandas as pd, xgboost as xgb

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--train", type=str, default="/opt/ml/input/data/train")
    parser.add_argument("--model-dir", type=str, default="/opt/ml/model")
    args = parser.parse_args()

    df = pd.read_csv(os.path.join(args.train, "train.csv"))
    X, y = df.drop("label", axis=1), df["label"]
    dtrain = xgb.DMatrix(X, label=y)

    model = xgb.train({"objective": "binary:logistic", "eval_metric": "auc"}, dtrain)
    model.save_model(os.path.join(args.model_dir, "xgb_model.json"))
