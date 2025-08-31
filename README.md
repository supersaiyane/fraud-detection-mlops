# 🚀 Real-Time Fraud Detection with AWS SageMaker & MLOps Guardrails

## 📝 Executive Summary
- Built an **AI-powered fraud detection system** using AWS SageMaker + MLOps Guardrails.  
- Supports **real-time scoring** with <200ms latency via API Gateway + Lambda + SageMaker Endpoint.  
- Ensures **resilience** with Canary Rollouts + Auto-Rollback + Drift Detection.  
- Provides **business visibility** with CloudWatch Dashboards + QuickSight Analytics.  
- Designed for **multi-tenant SaaS** — scalable, cost-optimized, and compliant.  

---

## Author
**Gurpreet Singh**  
Principal Cloud Architect & Senior Staff SRE  

---

## Part 1: Roles & Responsibilities (as Senior SRE + Principal Cloud Architect)

### 🎯 Core Responsibilities

#### AI-Ready SaaS Infrastructure
- Architect **multi-cloud platforms (AWS / GCP / Azure)** tailored for AI/ML workloads (training, inference, pipelines).  
- Ensure GPU/accelerator integration (AWS SageMaker, EKS GPU nodes, FSx for Lustre, EFS for datasets).  
- Build **multi-tenant SaaS infrastructure** with isolation, scaling, and **usage-based metering** for cost efficiency.  

#### SRE for AI Services
- Define **SLOs & SLIs** for AI inference workloads (latency, accuracy drift, throughput).  
- Build **self-healing + auto-scaling clusters** (horizontal scaling for inference, batch orchestration for training).  
- Enforce **error budget policies**: allow innovation in Sandbox, protect SLAs in Production.  

#### DevSecOps for AI/ML
- Create **CI/CD pipelines** for:
  - Data pipelines  
  - Model training workflows  
  - Inference endpoint deployments  
- Embed **security guardrails**:
  - Data encryption (KMS, TLS in transit).  
  - Model version integrity & approvals.  
  - API security (WAF + API Gateway + IAM).  
- Ensure **compliance** with GDPR, HIPAA, SOC2 for sensitive financial & PII data.  

#### Leadership & Team
- **Mentor & lead** SREs, MLOps engineers, and Cloud engineers.  
- Foster **blameless postmortems** & a culture of reliability.  
- Balance **innovation vs reliability** → allow experimentation while protecting production SLAs.  
- Act as the **bridge between Data Scientists & Engineers** → ensure models are deployed reliably, at scale.  

#### Leadership Impact
- Scale engineering teams through **mentorship & career growth**.  
- Build cross-functional collaboration between **SRE, Data Science, and Security teams**.  
- Align **business outcomes** (fraud loss reduction, compliance) with **technical KPIs** (SLOs, MTTR, drift).  

---

## 🎯 Planning

### What We Are Building
A **real-time fraud detection platform** that leverages AWS services for:
- Training fraud detection models on historical data.
- Registering models with governance controls.
- Deploying via CI/CD pipelines with **Guardrails**.
- Serving predictions through a public API with **ms-level latency**.
- Ensuring **compliance, cost-efficiency, and resilience**.

### What We Aim to Achieve
- Reduce fraud losses by flagging high-risk transactions.
- Improve customer trust with accurate real-time decisions.
- Scale to multi-tenant SaaS environments with isolation.
- Optimize cost via **Spot training, serverless inference, and FinOps quotas**.

---

## 🛠️ Strategy

1. **Multi-tenant ready**: Isolated Studio domains, per-tenant S3 buckets.  
2. **Governed datasets**: Amazon DataZone integration.  
3. **CI/CD integration**: CodePipeline + CodeBuild + CodeDeploy.  
4. **Guardrails**: Latency/error budget monitoring, rollback, retraining.  
5. **Cost Optimization**: Spot training, serverless inference, multi-model endpoints.  
6. **Security Compliance**: OPA/Conftest in CodeBuild, WAF on API Gateway.  

---

## 🏗️ Architecture Decisions

- **Fraud API** uses **API Gateway + Lambda + SageMaker Endpoint**.  
- **Redis Caching (ElastiCache)** integrated into Fraud Lambda for sub-ms lookups.  
- **Suspicious Transactions** stored in DynamoDB for analyst review.  
- **Logs** pushed to S3 with **Glacier lifecycle policies** (30 → 90 days → 7 years).  
- **Rollback Lambda** with CloudWatch alarms + 30-day log retention.  
- **FinOps Guardrails**: AWS Budgets + Anomaly Detection alerts.  
- **CI/CD** includes **Test Stage** (unit + integration tests) before Sandbox deployment.  
- **QuickSight dashboards** provide business analytics (manual setup required).  

---

## 🚀 Getting Started

1. **Clone this repo**  
   ```bash
   git clone https://github.com/yourname/fraud-detection-mlops.git
   cd fraud-detection-mlops
   ```

2. **Deploy Infra**  
   ```bash
   cd terraform
   terraform init
   terraform apply -auto-approve
   ```

3. **Package & Upload Lambda**  
   ```bash
   cd lambda
   zip fraud_lambda.zip fraud_lambda.py
   aws lambda update-function-code --function-name fraud-detection-fraud-api --zip-file fileb://fraud_lambda.zip
   ```

4. **Trigger CI/CD**  
   Push to `main` → CodePipeline runs → SageMaker Pipeline trains/evaluates model → Canary deploys.  

5. **Test API**  
   ```bash
   curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/prod/fraud-check      -d '{"txn_id":"1234","amount":200,"device":"mobile"}'
   ```

---

## 🏗️ Architecture

**Data → Training → Deployment → Inference → Monitoring**

```
EFS → notebooks, scripts
     │
     ▼
S3 → training data (train/test) 
     │
     ▼
SageMaker Training → output model.tar.gz → S3
     │
     ▼
Model Registry (S3-backed)
     │
     ▼
CI/CD Pipeline → Sandbox Endpoint
     │
     ▼
CodeDeploy Canary → Production Endpoint
     │
     ▼
API Gateway + Lambda
     │
 ┌── DynamoDB (suspicious txn store - ms latency)
 ├── S3 (transaction logs - durable, analytics)
 └── ElastiCache (optional caching - µs latency)
     │
     ▼
CloudWatch / Model Monitor (observability)
     │
     ▼
S3 Glacier (long-term archival logs)
```

---

## 📊 Flows from Multiple Views

### 👤 Customer View
```
Customer → Payment App → Fraud Detection API
           │
           ▼
       Fraud Decision
   ┌──────────┬───────────┬─────────────┐
   │ Legit Txn│ Review Txn│ Suspicious  │
   └──────────┴───────────┴─────────────┘
         │            │           │
         ▼            ▼           ▼
    Bank Authorize   MFA       Decline + Analyst Review
```

---

### 🖥️ Technical View
```
EFS (scripts, notebooks)
   │
   ▼
S3 (train/test datasets)
   │
   ▼
SageMaker Training → model.tar.gz → S3
   │
   ▼
Model Registry
   │
   ▼
CodePipeline + CodeBuild
   │
   ▼
Sandbox Endpoint → Canary (10%) → Prod (100%)
   │
   ▼
API Gateway + Lambda
   │
 ┌─► DynamoDB (suspicious txns)
 ├─► S3 (logs)
 └─► ElastiCache (cache)
   │
   ▼
CloudWatch + Model Monitor
   │
   ▼
S3 Glacier (archival)
```

---

### 💼 Business / Ops View
```
Data Scientists → Build models in Studio
   │
   ▼
ML Engineers → Govern with Model Registry
   │
   ▼
CI/CD + Guardrails → Safe Deployments
   │
   ▼
Fraud API → Real-time fraud detection
   │
   ▼
Business Impact:
- Lower fraud losses
- Improve customer trust
- Optimize infra cost
- Ensure compliance
```

---

## 🛡️ Guardrails Deep Dive

### Infrastructure Guardrails
- Sandbox vs Production lanes.  
- Terraform OPA/Conftest policies.  
- FinOps quotas to prevent runaway GPU costs.  
- Multi-tenant SaaS isolation.

### Observability Guardrails
- Golden Signals (Latency, Errors, Traffic, Saturation).  
- Model Monitor detects drift.  
- Automated rollback if SLOs breached.

### Error Budget Guardrails
- SLO: 99.9% uptime, <200ms latency @ P95.  
- 30% monthly budget burn in 1 week → freeze.  
- 80% burned → rollback Canary → stable release.  

---

## 🔄 CI/CD Pipeline Stages

| Stage | AWS Service | Guardrail |
|-------|-------------|-----------|
| **Source** | CodeCommit/GitHub | Signed commits |
| **Build** | CodeBuild | OPA policy checks, SAST scans |
| **Test** | CodeBuild | Unit tests, drift detection |
| **Deploy Sandbox** | SageMaker | Deploy model → validate latency |
| **Canary Deploy** | CodeDeploy | 10% traffic, monitored |
| **Promote/Fail** | CodeDeploy | Auto-promotion or rollback |

---

## 🚨 Rollback Flow

1. CloudWatch Alarm → SNS.  
2. SNS → Rollback Lambda.  
3. Rollback Lambda → Update EndpointConfig (Prod=100%, Canary=0).  
4. Rollback Lambda → Notify Slack & Teams.  
5. Rollback Lambda → Log to DynamoDB.  
6. DynamoDB Streams → Firehose → S3 → QuickSight dashboards.  

📌 Example Slack/Teams Notification:
```
🚨 Rollback triggered for fraud-detection-prod
Rollback ID: 123e4567-e89b-12d3-a456-426614174000
Time: 2025-09-01T14:22:10Z
Canary disabled, Prod 100%.
```

---

## 📓 Architecture Decision Notes

- **Why S3?** → Cheap, durable storage for data & models.  
- **Why DynamoDB?** → ms latency for suspicious transaction lookups.  
- **Why ElastiCache?** → µs response for hot features (device IDs, IPs).  
- **Why Glacier?** → Long-term compliance archival (7+ years).  
- **Why Spot Training?** → Save up to 90% cost with checkpointing.  
- **Why Canary?** → Mitigate risk, rollback if error budgets violated.  
- **Why Slack/Teams?** → Fast human-in-loop visibility of rollbacks.  

---

## 📊 Storage Mapping

| Storage Service | Purpose | Latency | Why It Fits |
|-----------------|---------|---------|-------------|
| **Amazon EFS** | Notebooks/scripts | ms | Shared POSIX FS for Studio users |
| **Amazon S3** | Training data, logs, models | ms | Cheap, durable, scalable |
| **Amazon DynamoDB** | Suspicious txn store | ms | Instant lookups, high scale |
| **Amazon ElastiCache** | Cache fraud scores/features | µs | Sub-ms caching |
| **Amazon Glacier** | Compliance archival | minutes–hours | Cheapest for 7-year retention |
| **Model Registry (S3-backed)** | Model lineage/versioning | ms | Approval workflows, rollback |
| **DynamoDB Rollback Logs** | Rollback events | ms | Persistent rollback history |
| **S3 Rollback Archive** | Historical rollback logs | ms | Enables QuickSight analytics |
| **EBS (inside Endpoint)** | Hosting deployed models | µs–ms | Fast NVMe storage |

---

## ⚙️ Machine Types

| Stage | Instance Type | Reason |
|-------|--------------|--------|
| **Training (XGBoost)** | `ml.m5.2xlarge` (Spot) | Balanced CPU perf/cost |
| **Training (Large)** | `ml.c5.4xlarge` | For big datasets |
| **Training (DL)** | `ml.p3.2xlarge` | GPU for deep learning |
| **Inference** | `ml.m5.large` | Low-latency prod scoring |
| **Serverless Inference** | N/A | Cost saving for low-traffic tenants |
| **CI/CD Build** | CodeBuild medium | Lightweight, runs OPA scans |

---

## 🎮 Demo

- Send a LEGIT transaction:  
  ```json
  {"txn_id":"1","amount":50,"device":"mobile"}
  ```
  ✅ Returns `LEGIT`

- Send a suspicious transaction:  
  ```json
  {"txn_id":"2","amount":5000,"geo":"unknown","device":"rooted-phone"}
  ```
  ❌ Returns `SUSPICIOUS`  
  → Logged in DynamoDB for Fraud Team review.  

---

## ❓ FAQ

**Q: Why SageMaker instead of building my own ML infra?**  
A: SageMaker gives managed training, auto-scaling endpoints, drift detection, and integration with CI/CD — so you focus on ML, not infra.  

**Q: How does rollback happen automatically?**  
A: CloudWatch Alarms → SNS → Rollback Lambda → updates EndpointConfig (Canary=0, Prod=100%). Notifications go to Slack/Teams.  

**Q: What’s the business impact?**  
A: Faster fraud detection → reduced losses → improved trust. Plus cost-optimized infra with Spot + Serverless.  

---

## 🧑‍🏫 Hands-On Labs

Hands-on labs are provided in the [labs/](./labs) folder:

1. [Phase 1: Foundations - Studio, Notebooks, Storage](./labs/Phase1_Foundations.md)  
2. [Phase 2: Training & Deployment - SageMaker Training + Endpoint](./labs/Phase2_Training_Deployment.md)  
3. [Phase 3: Hyperparameter Tuning & Model Registry](./labs/Phase3_HPO_ModelRegistry.md)  
4. [Phase 4: Guardrails & Auto-Rollback](./labs/Phase4_Guardrails_Rollback.md)  
5. [Phase 5: Advanced - Multi-Tenant, DataZone, FinOps](./labs/Phase5_Advanced_MultiTenant.md)  

👉 Each phase builds on the last, ending with a **production-grade fraud detection pipeline** with full guardrails and dashboards.


---

## 🔮 Roadmap

### Technical Roadmap
- Add Explainable AI (SHAP, LIME) for model transparency.  
- Multi-cloud support (GCP Vertex AI, Azure ML).  
- Edge inference with SageMaker Edge.  

### Business Roadmap
- Expand into payment gateway integrations (Stripe, PayPal sandbox).  
- Offer SaaS fraud detection service to 3rd parties.  
- Compliance-ready exports (GDPR, PCI-DSS reports).  

---

## 🔄 Workflow Diagram (Detailed Tech View)
See [fraud-detection-uml.puml](./diagrams/fraud-detection-uml.puml)

---

## 🔄 Workflow Diagram (Executive View)
See [fraud-detection-exec-view.puml](./diagrams/fraud-detection-exec-view.puml)

---

## 📊 Dashboards

- **CloudWatch Dashboard** → Real-time latency, API errors, rollback counts.  
- **QuickSight Dashboard** → Historical rollback analytics (via Firehose + S3 archive).  

---

## 🏆 Webinar One-Slide Summary

| Pillar | Value |
|--------|-------|
| **Security** | Protects customers & bank assets |
| **Reliability** | 99.9% uptime with auto-rollback |
| **Efficiency** | 70–90% savings (Spot + Serverless) |
| **Compliance** | Audit logs, GDPR/SOC2, Glacier archival |
| **Scalability** | Multi-tenant SaaS ready |
| **Transparency** | Rollback history in Slack, Teams, Dashboards |

---
