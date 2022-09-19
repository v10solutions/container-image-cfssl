#
# Container Image CFSSL
#

FROM golang:1.19.0-alpine3.16 AS base

ARG PROJ_NAME
ARG CFSSL_VERSION

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
	"gcc" \
	"libc-dev"

RUN bins=("cfssl" "cfssljson") \
	&& for bin in "${bins[@]}"; do \
		go install "github.com/cloudflare/cfssl/cmd/${bin}@v${CFSSL_VERSION}"; \
	done

WORKDIR "/tmp/${PROJ_NAME}"

RUN mkdir ".output"

########################################################################################################################

FROM base AS do-ca

COPY "pki/ca-csr.json" "./"

RUN cfssl gencert -initca "ca-csr.json" \
	| cfssljson -bare ".output/ca" \
	&& mv ".output/ca.csr" ".output/ca-csr.pem" \
	&& mv ".output/ca.pem" ".output/ca-cer.pem"

########################################################################################################################

FROM scratch AS ca

ARG PROJ_NAME

COPY --from="do-ca" "/tmp/${PROJ_NAME}/.output" "."

########################################################################################################################

FROM base AS do-tls

COPY ".output/pki/ca/ca-cer.pem" "./"
COPY ".output/pki/ca/ca-key.pem" "./"

COPY "pki/config.json" "./"
COPY "pki/tls-csr.json" "./"

RUN cfssl genkey "tls-csr.json" \
	| cfssljson -bare ".output/tls" \
	&& mv ".output/tls.csr" ".output/tls-csr.pem"

RUN cfssl sign \
		-ca "ca-cer.pem" \
		-ca-key "ca-key.pem" \
		-profile "tls" \
		-config "config.json" \
		".output/tls-csr.pem" \
	| cfssljson -bare ".output/tls" \
	&& mv ".output/tls.csr" ".output/tls-csr.pem" \
	&& mv ".output/tls.pem" ".output/tls-cer.pem"

########################################################################################################################

FROM scratch AS tls

ARG PROJ_NAME

COPY --from="do-tls" "/tmp/${PROJ_NAME}/.output" "."
