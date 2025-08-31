resource "aws_codepipeline" "fraud_pipeline" {
  name     = "${var.project}-mlops-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit" # or GitHub
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = var.repo_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }
  }

  stage {
    name = "Test"

    action {
      name             = "RunTests"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["build_output"]
      output_artifacts = ["test_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.test_project.name
      }
    }
  }

  stage {
    name = "DeploySandbox"

    action {
      name            = "DeployToSandbox"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "SageMaker"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        EndpointName = "${var.project}-sandbox-endpoint"
        ModelName    = "${var.project}-model"
      }
    }
  }

  stage {
    name = "CanaryRollout"

    action {
      name            = "DeployCanary"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "SageMaker"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        EndpointName = "${var.project}-fraud-endpoint"
        ModelName    = "${var.project}-model"
        VariantName  = "Canary"
        InitialVariantWeight = "10"
      }
    }
  }

  stage {
    name = "ProdPromotion"

    action {
      name            = "PromoteToProd"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "SageMaker"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        EndpointName = "${var.project}-fraud-endpoint"
        ModelName    = "${var.project}-model"
        VariantName  = "Prod"
        InitialVariantWeight = "100"
      }
    }
  }
}
