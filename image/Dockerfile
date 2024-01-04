FROM amazonlinux:2023
ADD https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip ./
RUN yum install unzip python-pip -y
RUN ls -la
RUN unzip -q ./aws-sam-cli-linux-x86_64.zip -d ./sam-installation
RUN sh ./sam-installation/install
RUN mkdir -p reports/checkov
RUN echo '<?xml version="1.0" encoding="UTF-8"?>\n<testsuite xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://maven.apache.org/surefire/maven-surefire-plugin/xsd/surefire-test-report-3.0.xsd"name="" time="" tests="0" errors="0" skipped="0" failures="0"/>' > reports/checkov/blank.xml
RUN pip3 install "checkov==2.*"
COPY requirements.txt ./
RUN pip3 install -r "./requirements.txt"