import re
from typing import Optional
from zipfile import ZipFile

import boto3
import yaml

s3_client = boto3.client("s3")
s3_resource = boto3.resource("s3")


def s3_copy(source_uri, dest_uri):
    pattern = re.compile(r"//([a-z0-9-]*)/(.*)$")
    source_match = pattern.search(source_uri)
    dest_match = pattern.search(dest_uri)

    if source_match is None or dest_match is None:
        raise ValueError("S3 URIs are incorrect")

    source_bucket = source_match.group(1)
    source_key = source_match.group(2)

    s3_client.copy_object(
        Bucket=dest_match.group(1),
        Key=dest_match.group(2),
        CopySource=f"/{source_bucket}/{source_key}",
        MetadataDirective="COPY",
    )


def transform_template(template_path, promotion_bucket_name):
    with open(template_path, "r+", encoding="UTF-8") as template_file:
        template_yaml = yaml.load(template_file, Loader=yaml.SafeLoader)

        transform_lambda_sources(promotion_bucket_name, template_yaml)
        transform_lambda_layer_sources(promotion_bucket_name, template_yaml)
        transform_cloudformation_includes(promotion_bucket_name, template_yaml)
        transform_state_machine_definitions(promotion_bucket_name, template_yaml)

        template_file.seek(0)
        template_file.truncate()
        yaml.dump(template_yaml, template_file)


def transform_lambda_sources(promotion_bucket_name, template_yaml):
    for logical_id in template_yaml["Resources"].keys():
        resource_type = template_yaml["Resources"][logical_id].get("Type", "")
        if resource_type == "AWS::Serverless::Function":
            source_uri = template_yaml["Resources"][logical_id]["Properties"]["CodeUri"]
            dest_uri = re.sub(
                r"//[a-z0-9-]*/",
                "//" + promotion_bucket_name + "/",
                source_uri,
            )

            template_yaml["Resources"][logical_id]["Properties"]["CodeUri"] = dest_uri
            s3_copy(source_uri, dest_uri)


def transform_lambda_layer_sources(promotion_bucket_name, template_yaml):
    for logical_id in template_yaml["Resources"].keys():
        resource_type = template_yaml["Resources"][logical_id].get("Type", "")
        if resource_type == "AWS::Serverless::LayerVersion":
            content_uri = template_yaml["Resources"][logical_id]["Properties"][
                "ContentUri"
            ]
            # The ContentUri may be a dict containing Bucket/Key/Version in which case we will not mess with it
            if isinstance(content_uri, str):
                dest_uri = re.sub(
                    r"//[a-z0-9-]*/", "//" + promotion_bucket_name + "/", content_uri
                )

                template_yaml["Resources"][logical_id]["Properties"][
                    "ContentUri"
                ] = dest_uri
                s3_copy(content_uri, dest_uri)


def transform_cloudformation_includes(promotion_bucket_name, maybe_dict):
    """
    Transforms a given CloudFormation dictionary (maybe_dict) to ensure any
    CloudFormation includes in the dictionary have their location S3 URIs
    changed to reference a promotion bucket (`promotion_bucket_name`). Also
    copies the include artifacts from the old location to the promotion bucket
    location.
    """
    if isinstance(maybe_dict, dict):
        for k in maybe_dict.keys():
            if k == "Fn::Transform" and maybe_dict[k]["Name"] == "AWS::Include":
                source_uri = maybe_dict[k]["Parameters"]["Location"]
                dest_uri = re.sub(
                    r"//[a-z0-9-]*/",
                    "//" + promotion_bucket_name + "/",
                    source_uri,
                )
                s3_copy(source_uri, dest_uri)
                maybe_dict[k]["Parameters"]["Location"] = dest_uri
            else:
                maybe_dict[k] = transform_cloudformation_includes(
                    promotion_bucket_name, maybe_dict[k]
                )

        return maybe_dict
    if isinstance(maybe_dict, list):
        return [
            transform_cloudformation_includes(promotion_bucket_name, a)
            for a in maybe_dict
        ]

    return maybe_dict


def transform_state_machine_definitions(promotion_bucket_name, template_yaml):
    for logical_id in template_yaml["Resources"].keys():
        resource_type = template_yaml["Resources"][logical_id].get("Type", "")
        properties = template_yaml["Resources"][logical_id].get("Properties", dict())
        if (
            resource_type == "AWS::Serverless::StateMachine"
            and "DefinitionUri" in properties
        ):
            source_bucket = template_yaml["Resources"][logical_id]["Properties"][
                "DefinitionUri"
            ]["Bucket"]
            source_key = template_yaml["Resources"][logical_id]["Properties"][
                "DefinitionUri"
            ]["Key"]
            source_uri = f"s3://{source_bucket}/{source_key}"
            dest_uri = f"s3://{promotion_bucket_name}/{source_key}"

            properties["DefinitionUri"]["Bucket"] = promotion_bucket_name
            s3_copy(source_uri, dest_uri)


def promote_template(
    template_path: str,
    source_bucket_name: Optional[str],
    version_id: Optional[str],
    promotion_bucket_name: str,
):
    artifact_name = "template.zip"

    with ZipFile(artifact_name, "w") as template_zip:
        template_zip.write(template_path)

    extra_args = None

    if source_bucket_name and version_id:
        source_bucket_artifact_head = s3_client.head_object(
            Bucket=source_bucket_name, Key=artifact_name, VersionId=version_id
        )
        source_bucket_artifact_metadata = source_bucket_artifact_head["Metadata"]
        commitsha = source_bucket_artifact_metadata.get("commitsha")
        repository = source_bucket_artifact_metadata.get("repository")
        mergetime = source_bucket_artifact_metadata.get("mergetime")
        if commitsha and repository and mergetime:
            extra_args = {
                "Metadata": {
                    "commitsha": commitsha,
                    "repository": repository,
                    "mergetime": mergetime,
                }
            }
        elif commitsha and repository:
            extra_args = {
                "Metadata": {
                    "commitsha": commitsha,
                    "repository": repository,
                }
            }

    s3_resource.Bucket(promotion_bucket_name).upload_file(
        artifact_name, artifact_name, ExtraArgs=extra_args
    )


def main(
    promotion_bucket_name: str,
    source_bucket_name: Optional[str] = None,
    version_id: Optional[str] = None,
):
    transform_template("./cf-template.yaml", promotion_bucket_name)
    promote_template(
        "./cf-template.yaml", source_bucket_name, version_id, promotion_bucket_name
    )
