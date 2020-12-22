ARG release_version

ARG pypi_repository_url
ARG pypi_user
ARG pypi_password
ARG app_name
ARG app_version

FROM gradle:6.6-jdk11 as java_generator
WORKDIR /home/project
ARG release_version

COPY ./ .
RUN gradle --no-daemon clean build publish bintrayUpload \
    -Prelease_version=${release_version} \
    -Pnexus_url=${nexus_url} \
    -Pnexus_user=${nexus_user} \
    -Pnexus_password=${nexus_password}

FROM ghcr.io/th2-net/th2-python-service-generator:1.1.1 as python_service_generator
WORKDIR /home/project
COPY ./ .
RUN /home/service/bin/service -p src/main/proto/th2_grpc_act_template -w PythonServiceWriter -o src/gen/main/python/th2_grpc_act_template

FROM python:3.8-slim as python_generator
ARG pypi_repository_url
ARG pypi_user
ARG pypi_password
ARG app_name
ARG app_version

WORKDIR /home/project
COPY --from=python_service_generator /home/project .
RUN pip install -r requirements.txt && \
    python setup.py generate && \
    python setup.py sdist && \
    twine upload --repository-url ${pypi_repository_url} --username ${pypi_user} --password ${pypi_password} dist/*
