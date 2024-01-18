import { defineFeature, loadFeature, parseFeature } from 'jest-cucumber';
const { schema } = require('yaml-cfn');
import { SpecifiedCharacterLimit } from '../../../shared-steps/managed-policies/functions/SpecifiedCharacterLimit'
import { exportTemplate } from '../../../shared-steps/export-template/shared-step-template';
const feature = loadFeature('feature-tests/jest-features/Codebuild-managed-policy.feature');

type Characters = {
    [key: string]: any
}

let ManagedPolicyList: Characters = {
    "CodebuildRepositoryPolicy": 6145,
    }

defineFeature(feature, test => {
    test('A managed policy cannot grow beyond a certain size', ({ given, then }) => {
        given('a template that deploys a managed policy', () => {
            exportTemplate()
        });

        then('the managed policy should be within its specified character limit', () => {
            SpecifiedCharacterLimit(ManagedPolicyList)
        });
    });
    test('The CodebuildRepositoryPolicy should have the correct configuration', ({ given, then }) => {
        given('a template that deploys the Codebuild Image Repository stack', () => {
            exportTemplate()
        });

        then('it should return the correct CodebuildRepositoryPolicy configuration', () => {
            let found: string = template.findResources('AWS::IAM::ManagedPolicy')
            let statement = found["CodebuildRepositoryPolicy"]["Properties"]["PolicyDocument"]["Statement"]
            expect(statement).toEqual(expect.objectContaining(
            [
            {"Effect":"Allow",
            "Sid":"ListImagesInRepository",
            "Action":["ecr:ListImages"],
            "Resource":[{"Fn::GetAtt":["CodebuildRepository","Arn"]}]},
            {"Effect":"Allow",
            "Sid":"ManageRepositoryContents",
            "Action":["ecr:BatchCheckLayerAvailability","ecr:GetDownloadUrlForLayer","ecr:GetRepositoryPolicy","ecr:DescribeRepositories","ecr:ListImages","ecr:DescribeImages","ecr:BatchGetImage","ecr:InitiateLayerUpload","ecr:UploadLayerPart","ecr:CompleteLayerUpload","ecr:PutImage"],
            "Resource":[{"Fn::GetAtt":["CodebuildRepository","Arn"]}]}
            ]))
        });
    });
})