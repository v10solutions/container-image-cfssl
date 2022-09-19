#
# Container Image CFSSL
#

FROM golang:1.19.0-alpine3.16 AS bin

ARG PROJ_VERSION

RUN apk update \
	&& apk add --no-cache "shadow" "bash" \
	&& usermod -s "$(command -v "bash")" "root"

SHELL [ \
	"bash", \
	"--noprofile", \
	"--norc", \
	"-o", "errexit", \
	"-o", "nounset", \
	"-o", "pipefail", \
	"-c" \
]

ENV LANG "C.UTF-8"
ENV LC_ALL "${LANG}"

RUN apk add --no-cache \
	"gcc" \
	"libc-dev"

RUN bins=("cfssl" "cfssljson" "mkbundle" "multirootca") \
	&& for bin in "${bins[@]}"; do \
		go install "github.com/cloudflare/cfssl/cmd/${bin}@v${PROJ_VERSION}"; \
	done

########################################################################################################################

FROM alpine:3.16.2

ARG PROJ_NAME
ARG PROJ_VERSION
ARG PROJ_BUILD_NUM
ARG PROJ_BUILD_DATE
ARG PROJ_REPO

LABEL org.opencontainers.image.authors="V10 Solutions"
LABEL org.opencontainers.image.title="${PROJ_NAME}"
LABEL org.opencontainers.image.version="${PROJ_VERSION}"
LABEL org.opencontainers.image.revision="${PROJ_BUILD_NUM}"
LABEL org.opencontainers.image.created="${PROJ_BUILD_DATE}"
LABEL org.opencontainers.image.description="Container image for CFSSL"
LABEL org.opencontainers.image.source="${PROJ_REPO}"

RUN apk update \
	&& apk add --no-cache "shadow" "bash" \
	&& usermod -s "$(command -v "bash")" "root"

SHELL [ \
	"bash", \
	"--noprofile", \
	"--norc", \
	"-o", "errexit", \
	"-o", "nounset", \
	"-o", "pipefail", \
	"-c" \
]

ENV LANG "C.UTF-8"
ENV LC_ALL "${LANG}"

RUN apk add --no-cache \
	"ca-certificates" \
	"curl" \
	"jq"

RUN groupadd -r -g "480" "cfssl" \
	&& useradd \
		-r \
		-m \
		-s "$(command -v "nologin")" \
		-g "cfssl" \
		-c "CFSSL" \
		-u "480" \
		"cfssl"

WORKDIR "/usr/local"

COPY --from="bin" "/go/bin" "bin"

RUN mkdir -p "etc/cfssl"

WORKDIR "/"
