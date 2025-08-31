# Phase 4: Guardrails & Auto-Rollback

## 🎯 Goal
Ensure reliable deployments with Canary rollout, Guardrails, and auto-rollback.

## 📦 Services Used
- CodePipeline + CodeBuild  
- CodeDeploy (Canary)  
- CloudWatch Alarms  
- Lambda Rollback Function  
- Slack/MS Teams  

## 🛠️ Steps
1. Deploy model with Canary strategy (10%).  
2. Monitor latency & error rate.  
3. Trigger rollback Lambda if thresholds exceeded.  
4. Send notifications to Slack/Teams.  

## ✅ Outcome
- Canary auto-rolled back, Prod stable.

## 📓 Notes
- Rollback events logged in DynamoDB + QuickSight dashboard.
