FROM golang:1.19.0-windowsservercore-ltsc2022 as build_env

# Copy the source from the current directory to the Working Directory inside the container
WORKDIR /app

#ENV http_proxy 188.82.97.82:80
#ENV https_proxy 188.82.97.82:80

ENV GOPRIVATE=github.com/Checkmarx/*
ARG VERSION="development"
ARG COMMIT="NOCOMMIT"
ARG SENTRY_DSN=""
ARG DESCRIPTIONS_URL=""
ARG TARGETOS
ARG TARGETARCH

RUN echo $GOPATH


# Copy go mod and sum files
COPY go.mod go.sum  ./

# Get dependancies - will also be cached if we won't change mod/sum
RUN go mod download -x

# COPY the source code as the last step
COPY . .

# Build the Go app
#-ldflags "-s -X github.com/Checkmarx/kics/internal/constants.Version=${VERSION} -X github.com/Checkmarx/kics/internal/constants.SCMCommit=${COMMIT} -X github.com/Checkmarx/kics/internal/constants.SentryDSN=${SENTRY_DSN} -X github.com/Checkmarx/kics/internal/constants.BaseURL=${DESCRIPTIONS_URL}" \

#RUN go get github.com/Checkmarx/kics/test
#RUN go mod vendor

RUN go build \
    #-ldflags "-s -X github.com/Checkmarx/kics/internal/constants.Version=${VERSION} -X github.com/Checkmarx/kics/internal/constants.SCMCommit=${COMMIT} -X github.com/Checkmarx/kics/internal/constants.SentryDSN=${SENTRY_DSN} -X github.com/Checkmarx/kics/internal/constants.BaseURL=${DESCRIPTIONS_URL}" \
    -a -installsuffix cgo \
    -o bin/kics cmd/console/main.go
USER Checkmarx

# Healthcheck the container
HEALTHCHECK CMD curl -q --method=HEAD localhost/system-status.txt

# Runtime image
# Ignore no User Cmd since KICS container is stopped afer scan
# kics-scan ignore-line
FROM mcr.microsoft.com/windows/servercore:ltsc2022 

ENV TERM xterm-256color

# Install Terraform and Terraform plugins
RUN curl -o ./terraform_1.2.3_linux_amd64.zip  https://releases.hashicorp.com/terraform/1.2.3/terraform_1.2.3_linux_amd64.zip \
    && powershell -Command "Expand-Archive -Path '/terraform_1.2.3_linux_amd64.zip'" \
    && powershell -Command "Remove-Item -Path terraform_1.2.3_linux_amd64.zip"
RUN move terraform /usr/bin/terraform \
    && -o ./terraform-provider-azurerm_3.18.0_linux_amd64.zip curl https://releases.hashicorp.com/terraform-provider-azurerm/3.18.0/terraform-provider-azurerm_3.18.0_linux_amd64.zip \
    && -o ./terraform-provider-aws_3.72.0_linux_amd64.zip curl https://releases.hashicorp.com/terraform-provider-aws/3.72.0/terraform-provider-aws_3.72.0_linux_amd64.zip \
    && -o ./terraform-provider-google_4.32.0_linux_amd64.zip curl https://releases.hashicorp.com/terraform-provider-google/4.32.0/terraform-provider-google_4.32.0_linux_amd64.zip \
    && powershell -Command "Expand-Archive -Path '/terraform-provider-azurerm_3.18.0_linux_amd64.zip'" \
    && powershell -Command "Remove-Item -Path terraform-provider-azurerm_3.18.0_linux_amd64.zip'"\
    && powershell -Command "Expand-Archive -Path '/terraform-provider-google_4.32.0_linux_amd64.zip'" \
    && powershell -Command "Remove-Item terraform-provider-google_4.32.0_linux_amd64.zip'" \
    && powershell -Command "Expand-Archive -Path '/terraform-provider-aws_3.72.0_linux_amd64.zip'" \
    && powershell -Command "Remove-Item terraform-provider-aws_3.72.0_linux_amd64.zip'" \
    && mkdir ~/.terraform.d && mkdir ~/.terraform.d/plugins && mkdir ~/.terraform.d/plugins/linux_amd64 && mv terraform-provider-aws_v3.72.0_x5 terraform-provider-google_v4.32.0_x5 terraform-provider-azurerm_v3.18.0_x5 ~/.terraform.d/plugins/linux_amd64 \
    && apk upgrade --no-cache pcre2 \
    && apk add --no-cache \
    git=2.36.2-r0


# Install Terraformer
RUN curl -o ./terraformer-all-linux-amd64 ./terraform_1.2.3_linux_amd64.zip https://github.com/GoogleCloudPlatform/terraformer/releases/download/0.8.21/terraformer-all-linux-amd64 \
    && chmod +x terraformer-all-linux-amd64 \
    && move terraformer-all-linux-amd64 /usr/bin/terraformer \
    && apk add gcompat=1.0.0-r4 --no-cache


# Copy built binary to the runtime container
# Vulnerability fixed in latest version of KICS remove when gh actions version is updated
# kics-scan ignore-line
COPY --from=build_env /app/bin/kics /app/bin/kics
COPY --from=build_env /app/assets/queries /app/bin/assets/queries
COPY --from=build_env /app/assets/libraries/* /app/bin/assets/libraries/

WORKDIR /app/bin

# Healthcheck the container
HEALTHCHECK CMD curl -q --method=HEAD localhost/system-status.txt
ENV PATH $PATH:/app/bin

# Command to run the executable
ENTRYPOINT ["/app/bin/kics"]