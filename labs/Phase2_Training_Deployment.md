# Phase 2: Training & Deployment - SageMaker Training + Endpoint

## 🎯 Goal
Train an ML model on fraud dataset and deploy to a real-time endpoint.

## 📦 Services Used
- SageMaker Training Jobs  
- SageMaker Endpoints  
- S3 (input/output)  

## 🛠️ Steps
1. Upload dataset to S3.  
2. Launch training job (XGBoost / custom).  
3. Save model artifacts to S3.  
4. Deploy model as a SageMaker real-time endpoint.  

## ✅ Outcome
- Model trained and deployed, endpoint is live.

## 📓 Notes
- Start with `ml.m5.large` before scaling up.
