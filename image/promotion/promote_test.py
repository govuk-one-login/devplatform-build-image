import atexit
import unittest
from os import remove
from os.path import dirname
from shutil import copyfile
from tempfile import NamedTemporaryFile
from unittest.mock import Mock, call, patch

import yaml
from promote import promote_template, s3_copy, transform_template


def duplicate_template_for_editing(source_template_path):
    # pylint: disable=consider-using-with
    test_template_file = NamedTemporaryFile(delete=False)
    test_template_file.close()
    # pylint: enable=consider-using-with

    atexit.register(remove, test_template_file.name)
    copyfile(source_template_path, test_template_file.name)

    return test_template_file.name


class BaseTest(unittest.TestCase):
    def setUp(self) -> None:
        super().setUp()
        self.template_path = duplicate_template_for_editing(
            dirname(__file__) + "/test-cf-template.yaml"
        )


class TestTransformLambdaSources(BaseTest):
    @patch("promote.s3_copy")
    def test_replaces_lambda_code_uri_destination_bucket(self, _s3_copy_mock):
        transform_template(
            template_path=self.template_path,
            promotion_bucket_name="test-promotion-bucket1234",
        )

        with open(self.template_path, encoding="UTF-8") as transformed_template_file:
            for line in transformed_template_file.readlines():
                if "CodeUri:" in line:
                    self.assertIn(
                        "test-promotion-bucket1234",
                        line,
                        (
                            "All CodeUri property values must be transformed to "
                            "reference the given promotion bucket."
                        ),
                    )

    @patch("promote.s3_copy")
    def test_uploads_lambda_source_artifacts(self, s3_copy_mock):
        transform_template(
            template_path=self.template_path,
            promotion_bucket_name="test-promotion-bucket1234",
        )

        s3_copy_mock.assert_has_calls(
            [
                call(
                    "s3://test-bucket1234/pre-traffic-hook.zip/signed_123.zip",
                    "s3://test-promotion-bucket1234/pre-traffic-hook.zip/signed_123.zip",
                ),
                call(
                    "s3://test-bucket1234/hello-world-function.zip/signed_456.zip",
                    "s3://test-promotion-bucket1234/hello-world-function.zip/signed_456.zip",
                ),
                call(
                    "s3://test-bucket1234/hello-world-function-2.zip/signed_789.zip",
                    "s3://test-promotion-bucket1234/hello-world-function-2.zip/signed_789.zip",
                ),
            ],
            any_order=True,
        )


class TestTransformStateMachineDefinitions(BaseTest):
    @patch("promote.s3_copy")
    def test_replaces_definition_uri_bucket_name(self, _s3_copy_mock):
        transform_template(
            template_path=self.template_path,
            promotion_bucket_name="test-promotion-bucket1234",
        )

        with open(self.template_path, encoding="UTF-8") as transformed_template_file:
            transformed_template_dict = yaml.load(
                transformed_template_file, Loader=yaml.SafeLoader
            )
            self.assertEqual(
                "test-promotion-bucket1234",
                transformed_template_dict["Resources"][
                    "StateMachineWithExternalDefinition"
                ]["Properties"]["DefinitionUri"]["Bucket"],
                (
                    "All external state machine definition property values must be transformed to "
                    "reference the given promotion bucket."
                ),
            )

    @patch("promote.s3_copy")
    def test_uploads_state_machine_source_artifacts(self, s3_copy_mock):
        transform_template(
            template_path=self.template_path,
            promotion_bucket_name="test-promotion-bucket1234",
        )

        s3_copy_mock.assert_any_call(
            "s3://test-bucket/state-machine-key",
            "s3://test-promotion-bucket1234/state-machine-key",
        )


class TestTransformCloudFormationIncludeValues(BaseTest):
    @patch("promote.s3_copy")
    def test_replaces_cfn_include_value_bucket_name(self, _s3_copy_mock):
        transform_template(
            template_path=self.template_path,
            promotion_bucket_name="test-promotion-bucket1234",
        )

        with open(self.template_path, encoding="UTF-8") as transformed_template_file:
            for line in transformed_template_file.readlines():
                if "Location:" in line:
                    self.assertIn(
                        "test-promotion-bucket1234",
                        line,
                        (
                            "All cloudformation include locations must be transformed "
                            "to reference the given promotion bucket."
                        ),
                    )

    @patch("promote.s3_copy")
    def test_uploads_include_artifacts(self, s3_copy_mock):
        transform_template(
            template_path=self.template_path,
            promotion_bucket_name="test-promotion-bucket1234",
        )

        s3_copy_mock.assert_has_calls(
            [
                call(
                    "s3://test-bucket1234/api-definition",
                    "s3://test-promotion-bucket1234/api-definition",
                ),
                call(
                    "s3://test-bucket1234/event-path",
                    "s3://test-promotion-bucket1234/event-path",
                ),
                call(
                    "s3://test-bucket1234/tags-list",
                    "s3://test-promotion-bucket1234/tags-list",
                ),
                call(
                    "s3://test-bucket1234/policy-statement",
                    "s3://test-promotion-bucket1234/policy-statement",
                ),
            ],
            any_order=True,
        )


class TestTransformLambdaLayers(BaseTest):
    @patch("promote.s3_copy")
    def test_replaces_lambda_layer_content_uri_destination_bucket(self, _s3_copy_mock):
        transform_template(
            template_path=self.template_path,
            promotion_bucket_name="test-promotion-bucket1234",
        )

        with open(self.template_path, encoding="UTF-8") as transformed_template_file:
            for line in transformed_template_file.readlines():
                if "ContentUri:" in line:
                    self.assertIn(
                        "test-promotion-bucket1234",
                        line,
                        (
                            "All ContentUri property values must be transformed to "
                            "reference the given promotion bucket."
                        ),
                    )

    @patch("promote.s3_copy")
    def test_uploads_lambda_layer_source_artifacts(self, s3_copy_mock):
        transform_template(
            template_path=self.template_path,
            promotion_bucket_name="test-promotion-bucket1234",
        )

        s3_copy_mock.assert_any_call(
            "s3://test-bucket1234/sample_lib.zip/signed_456.zip",
            "s3://test-promotion-bucket1234/sample_lib.zip/signed_456.zip",
        )


class TestPromoteTemplate(BaseTest):
    @patch("promote.s3_client.copy")
    def test_file_copy_raises_error_when_poorly_formatted_uri_provided(
        self, _s3_copy_mock
    ):
        self.assertRaises(
            ValueError,
            s3_copy,
            "s3://woaHAHAGZ~~~34$££/hah",
            "s3://ccdsdfhFGD()(*&/lol",
        )

    @patch("promote.s3_resource.Bucket")
    def test_upload_file_is_called_without_metadata_when_no_source_bucket_provided(
        self, mock_bucket
    ):
        mock_bucket_object = Mock()
        mock_upload_file = Mock()
        mock_bucket_object.upload_file = mock_upload_file
        mock_bucket.return_value = mock_bucket_object

        promote_template(
            self.template_path,
            source_bucket_name=None,
            version_id=None,
            promotion_bucket_name="test-promotion-bucket1234",
        )

        mock_upload_file.assert_called_once_with(
            "template.zip", "template.zip", ExtraArgs=None
        )

    @patch("promote.s3_client.head_object")
    @patch("promote.s3_resource.Bucket")
    def test_upload_file_is_called_without_metadata_when_no_metadata_exists_on_source_artifact(
        self, mock_bucket, stub_head_object
    ):
        mock_bucket_object = Mock()
        mock_upload_file = Mock()
        mock_bucket_object.upload_file = mock_upload_file
        mock_bucket.return_value = mock_bucket_object

        stub_head_object.return_value = {"Metadata": {}}

        promote_template(
            self.template_path,
            source_bucket_name="test-source-bucket1234",
            version_id="the-version-id",
            promotion_bucket_name="test-promotion-bucket1234",
        )

        mock_upload_file.assert_called_once_with(
            "template.zip", "template.zip", ExtraArgs=None
        )

    @patch("promote.s3_client.head_object")
    @patch("promote.s3_resource.Bucket")
    def test_upload_file_is_called_with_metadata_when_metadata_exists_on_source_artifact(
        self, mock_bucket, stub_head_object
    ):
        mock_bucket_object = Mock()
        mock_upload_file = Mock()
        mock_bucket_object.upload_file = mock_upload_file
        mock_bucket.return_value = mock_bucket_object

        stub_head_object.return_value = {
            "Metadata": {"commitsha": "1234", "repository": "the-repo"}
        }

        promote_template(
            self.template_path,
            source_bucket_name="test-source-bucket1234",
            version_id="the-version-id",
            promotion_bucket_name="test-promotion-bucket1234",
        )

        mock_upload_file.assert_called_once_with(
            "template.zip",
            "template.zip",
            ExtraArgs={"Metadata": {"commitsha": "1234", "repository": "the-repo"}},
        )
