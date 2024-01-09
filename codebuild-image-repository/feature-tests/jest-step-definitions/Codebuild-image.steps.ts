import { defineFeature, loadFeature } from 'jest-cucumber';
import { Template, Capture, Match } from '@aws-cdk/assertions';
const { schema } = require('yaml-cfn');
import { readFileSync } from 'fs';
import { load } from 'js-yaml';
import { exportTemplate } from '../../../shared-steps/export-template/shared-step-template';

const feature = loadFeature('feature-tests/jest-features/Codebuild-image.feature');

defineFeature(feature, test => {
    test('When a template deploys the Codebuild Image Repository stack, the AWS organisation ID should match the allowed pattern and default', ({ given, then, and }) => {

        given('a template to deploy Codebuild Image Repository stack', () => {
            exportTemplate()
        });
        then('the default AWS organisation ID should match the allowed secret', () => {
            template.hasParameter('AWSOrganizationId', { Default: "o-pjzf8d99ys,o-dpp53lco28" })
        });
        and('match the allowed pattern', () => {
            template.hasParameter('AWSOrganizationId', { AllowedPattern: "^[a-z0-9-]+$" })
        });

    test('When a template deploys the Codebuild Image Repository stack, the Pipeline StackName should match the allowed pattern', ({ given, then }) => {
        given('a template to deploy Codebuild Image Repository stack', () => {
            exportTemplate()
        });
        then('the Pipeline StackName should match the allowed pattern', () => {
            template.hasParameter('PipelineStackName', { AllowedPattern: "^[a-zA-Z0-9-]+$" })
        });

    test('When a template deploys the Codebuild Image Repository stack, it should receive the Codebuild Repository name and uri as an output', ({ given, then, and }) => {

        given('a template to deploy Codebuild Image Repository stack', () => {
            exportTemplate()
        });
        then('it should receive the Codebuild Repository name as an output', () => {
            template.hasOutput("CodebuildRepositoryName",
                {
                    "Value": {"Ref": "CodebuildRepository"}
                })
        });
        and('it should recieve the Codebuild Repository uri as an output', () => {
            template.hasOutput("CodebuildRepositoryUri",
                {
                    "Value": {"Fn::GetAtt": ["CodebuildRepository", "RepositoryUri"]}
                })
        });

    test('When a template deploys the Codebuild Image Repository stack, it should contain the correct Codebuild Repository properties', ({ given, then, and}) => {

        given('a template to deploy Codebuild Image Repository stack', () => {
            exportTemplate()
        });
        then('an image should be scanned when pushed to the Codebuild', () => {
            let found: string = template.findResources('AWS::ECR::Repository')
            let statement = found["CodebuildRepository"]["Properties"]
            expect(statement).toEqual(expect.objectContaining(
                {
                    "ImageScanningConfiguration": {"ScanOnPush": true},
                }))
        });
        and('the encryption type should be kms', () => {
            let found: string = template.findResources('AWS::ECR::Repository')
            let statement = found["CodebuildRepository"]["Properties"]
            expect(statement).toEqual(expect.objectContaining(
                {
                    EncryptionConfiguration: { EncryptionType: 'KMS' },
                }))
        });
        and('the image tag should be immutable', () => {
            let found: string = template.findResources('AWS::ECR::Repository')
            let statement = found["CodebuildRepository"]["Properties"]
            expect(statement).toEqual(expect.objectContaining(
                {
                    ImageTagMutability: 'MUTABLE',
                }))
        });
        and('it should be allowed to edit images as actioned in the statement "AllowAccountToPull"', () => {
            let found: string = template.findResources('AWS::ECR::Repository')
            let statement = found["CodebuildRepository"]["Properties"]["RepositoryPolicyText"]["Statement"]
            expect(statement).toEqual(expect.objectContaining(
                [{
                    "Action": [
                                "ecr:BatchCheckLayerAvailability",
                                "ecr:BatchGetImage",
                                "ecr:DescribeImages",
                                "ecr:DescribeRepositories",
                                "ecr:GetDownloadUrlForLayer",
                                "ecr:GetLifecyclePolicy",
                                "ecr:GetLifecyclePolicyPreview",
                                "ecr:GetRepositoryPolicy",
                                "ecr:ListImages"],
                    "Condition": {"StringEquals": {"aws:PrincipalOrgID": {"Ref": "AWSOrganizationId"}}},
                    "Effect": "Allow",
                    "Principal": "*",
                    "Sid": "AllowAccountToPull"}]
                ))
        });

    })})})})})