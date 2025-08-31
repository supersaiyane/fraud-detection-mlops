resource "aws_codebuild_project" "test_project" {
  name          = "${var.project}-mlops-tests"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
  }
  source {
    type = "CODEPIPELINE"
    buildspec = "pipeline/test-buildspec.yml"
  }
}
