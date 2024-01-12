FROM ubuntu:noble
RUN apt-get update
RUN apt-get install  unzip pip jq curl -y

ADD https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip ./
RUN unzip -q ./aws-sam-cli-linux-x86_64.zip -d ./sam-installation
RUN sh ./sam-installation/install

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN sh ./aws/install

RUN pip3 install "checkov==3.1.55" --break-system-packages
COPY requirements.txt ./
RUN pip3 install -r "./requirements.txt" --break-system-packages

COPY ./promotion ./
COPY ./grafana-scripts ./
COPY ./dynatrace-scripts ./

RUN mkdir -p reports/checkov
RUN echo '<?xml version="1.0" encoding="UTF-8"?>\n<testsuite xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://maven.apache.org/surefire/maven-surefire-plugin/xsd/surefire-test-report-3.0.xsd"name="" time="" tests="0" errors="0" skipped="0" failures="0"/>' > reports/checkov/blank.xml

