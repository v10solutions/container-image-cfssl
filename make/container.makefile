#
# Container Image CFSSL
#

.PHONY: container-run-linux
container-run-linux:
	$(BIN_DOCKER) container create \
		--platform "$(PROJ_PLATFORM_OS)/$(PROJ_PLATFORM_ARCH)" \
		--name "cfssl" \
		-h "cfssl" \
		-u "480" \
		--entrypoint "cfssl" \
		--net "$(NET_NAME)" \
		-p "8888":"8888" \
		--health-interval "10s" \
		--health-timeout "8s" \
		--health-retries "3" \
		--health-cmd "cfssl-healthcheck \"8888\" \"8\"" \
		"$(IMG_REG_URL)/$(IMG_REPO):$(IMG_TAG_PFX)-$(PROJ_PLATFORM_OS)-$(PROJ_PLATFORM_ARCH)" \
		serve \
		-loglevel "2" \
		-address "0.0.0.0" \
		-port "8888" \
		-ca "/usr/local/etc/cfssl/ca-cer.pem" \
		-ca-key "/usr/local/etc/cfssl/ca-key.pem" \
		-tls-cert "/usr/local/etc/cfssl/tls-cer.pem" \
		-tls-key "/usr/local/etc/cfssl/tls-key.pem" \
		-config "/usr/local/etc/cfssl/config.json"
	$(BIN_FIND) "bin" -mindepth "1" -type "f" -iname "*" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "0" --group "0" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "cfssl":"/usr/local"
	$(BIN_FIND) "etc/cfssl" -mindepth "1" -type "f" -iname "*" ! -iname "ca-key.pem" ! -iname "tls-key.pem" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "0" --group "0" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "cfssl":"/usr/local"
	$(BIN_FIND) "etc/cfssl" -mindepth "1" -type "f" "(" -iname "ca-key.pem" -o -iname "tls-key.pem" ")" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "480" --group "480" --mode "600" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "cfssl":"/usr/local"
	$(BIN_DOCKER) container start -a "cfssl"

.PHONY: container-run
container-run:
	$(MAKE) "container-run-$(PROJ_PLATFORM_OS)"

.PHONY: container-rm
container-rm:
	$(BIN_DOCKER) container rm -f "cfssl"
