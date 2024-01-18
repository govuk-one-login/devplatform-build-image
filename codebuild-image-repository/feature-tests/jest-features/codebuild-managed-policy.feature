Feature: Codebuild Managed Policy

    Scenario: A managed policy cannot grow beyond a certain size
       Given a template that deploys a managed policy
       Then the managed policy should be within its specified character limit

    Scenario: The CodebuildRepositoryPolicy should have the correct configuration
       Given a template that deploys the Codebuild Image Repository stack
       Then it should return the correct CodebuildRepositoryPolicy configuration