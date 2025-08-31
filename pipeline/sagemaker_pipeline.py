import sagemaker
from sagemaker.workflow.pipeline import Pipeline
from sagemaker.workflow.steps import ProcessingStep, TrainingStep, CreateModelStep
from sagemaker.workflow.model_step import RegisterModel
from sagemaker.inputs import TrainingInput
from sagemaker.estimator import Estimator

def get_pipeline(region, role, bucket):
    sm_session = sagemaker.session.Session()

    # 1. Training Step
    xgb_estimator = Estimator(
        image_uri=sagemaker.image_uris.retrieve("xgboost", region, "1.5-1"),
        instance_type="ml.m5.2xlarge",
        instance_count=1,
        role=role,
        output_path=f"s3://{bucket}/models/"
    )

    train_step = TrainingStep(
        name="TrainFraudModel",
        estimator=xgb_estimator,
        inputs={
            "train": TrainingInput(f"s3://{bucket}/train/"),
            "validation": TrainingInput(f"s3://{bucket}/validation/")
        }
    )

    # 2. Evaluation Step
    evaluate_step = ProcessingStep(
        name="EvaluateFraudModel",
        processor=xgb_estimator,
        inputs=[train_step.properties.ModelArtifacts.S3ModelArtifacts],
        outputs=[],
        code="src/evaluate.py"
    )

    # 3. Register Model
    register_step = RegisterModel(
        name="RegisterFraudModel",
        estimator=xgb_estimator,
        model_data=train_step.properties.ModelArtifacts.S3ModelArtifacts,
        content_types=["text/csv"],
        response_types=["application/json"],
        inference_instances=["ml.m5.large"],
        transform_instances=["ml.m5.xlarge"],
        model_package_group_name="FraudDetectionGroup"
    )

    # 4. Assemble Pipeline
    pipeline = Pipeline(
        name="fraud-detection-mlops",
        steps=[train_step, evaluate_step, register_step],
        sagemaker_session=sm_session
    )
    return pipeline

if __name__ == "__main__":
    import json, sys
    region = sys.argv[1]
    role = sys.argv[2]
    bucket = sys.argv[3]

    pipeline = get_pipeline(region, role, bucket)
    definition = pipeline.definition()
    with open("pipeline/sagemaker_pipeline.json", "w") as f:
        f.write(definition)
