Feature: Codebuild Image

    Scenario: When a template deploys the Codebuild Image Repository stack, the AWS organisation ID should match the allowed pattern and default
        Given a template to deploy Codebuild Image Repository stack
        Then the default AWS organisation ID should match the allowed secret
        And match the allowed pattern

    Scenario: When a template deploys the Codebuild Image Repository stack, the Pipeline StackName should match the allowed pattern
        Given a template to deploy Codebuild Image Repository stack
        Then the Pipeline StackName should match the allowed pattern

    Scenario: When a template deploys the Codebuild Image Repository stack, it should receive the Codebuild Repository name and uri as an output
        Given a template to deploy Codebuild Image Repository stack
        Then it should receive the Codebuild Repository name as an output
        And it should recieve the Codebuild Repository uri as an output

    Scenario: When a template deploys the Codebuild Image Repository stack, it should contain the correct Codebuild Repository properties
        Given a template to deploy Codebuild Image Repository stack
        Then an image should be scanned when pushed to the Codebuild
        And the encryption type should be kms
        And the image tag should be mutable
        And it should be allowed to edit images as actioned in the statement "AllowAccountToPull"