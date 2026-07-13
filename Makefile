ERLC ?= erlc
MIX ?= mix
PYTHON ?= python3
MIX_ENV ?= atomvm

ATOMVM_BUILD ?= ../atomvm_for_picorv32/AtomVM/build/generic_unix_full
HOST_ATOMVM ?= $(ATOMVM_BUILD)/src/AtomVM
ATOMVMLIB ?= $(ATOMVM_BUILD)/libs/atomvmlib.avm
ESTDLIB ?= $(ATOMVM_BUILD)/libs/estdlib/src/estdlib.avm
EXAVMLIB ?= $(ATOMVM_BUILD)/libs/exavmlib/lib/exavmlib.avm
ESTDLIB_BEAM_DIR ?= $(ATOMVM_BUILD)/libs/estdlib/src/beams
EAVMLIB_BEAM_DIR ?= $(ATOMVM_BUILD)/libs/eavmlib/src/beams
EUNIT_BEAM ?= $(ATOMVM_BUILD)/libs/etest/src/beams/eunit.beam
PACKBEAM ?= ../atomvm_for_picorv32/fw/packbeam
HOST_ATOMVM_INDEX3_URL ?= http://127.0.0.1:18080/index3.html

HOST_ATOMVM_BUILD_DIR := tmp/host_atomvm_smoke
HOST_ATOMVM_SMOKE := micro_scaffold_host_atomvm_smoke
HOST_ATOMVM_SMOKE_SRC := test_atomvm/$(HOST_ATOMVM_SMOKE).erl
HOST_ATOMVM_SMOKE_BEAM := $(HOST_ATOMVM_BUILD_DIR)/$(HOST_ATOMVM_SMOKE).beam
HOST_ATOMVM_SMOKE_AVM := $(HOST_ATOMVM_BUILD_DIR)/$(HOST_ATOMVM_SMOKE).avm

HOST_ATOMVM_APP_NAMES := \
	micro_scaffold_example \
	micro_phoenix \
	mini_ecto \
	req \
	ex_tcp \
	finch \
	mint \
	nimble_pool \
	nimble_options \
	hpax \
	mime \
	jason \
	telemetry

HOST_ATOMVM_APP_EBIN_DIRS := $(addprefix _build/$(MIX_ENV)/lib/,$(addsuffix /ebin,$(HOST_ATOMVM_APP_NAMES)))

HOST_ATOMVM_RUNTIME_BEAMS := \
	$(ESTDLIB_BEAM_DIR)/gen_tcp.beam \
	$(ESTDLIB_BEAM_DIR)/gen_tcp_socket.beam \
	$(ESTDLIB_BEAM_DIR)/socket.beam \
	$(ESTDLIB_BEAM_DIR)/gen_server.beam \
	$(ESTDLIB_BEAM_DIR)/gen.beam \
	$(ESTDLIB_BEAM_DIR)/proc_lib.beam \
	$(ESTDLIB_BEAM_DIR)/sys.beam \
	$(ESTDLIB_BEAM_DIR)/erlang.beam \
	$(ESTDLIB_BEAM_DIR)/logger.beam \
	$(EAVMLIB_BEAM_DIR)/logger_manager.beam \
	$(EAVMLIB_BEAM_DIR)/timer_manager.beam \
	$(ESTDLIB_BEAM_DIR)/proplists.beam \
	$(ESTDLIB_BEAM_DIR)/maps.beam \
	$(ESTDLIB_BEAM_DIR)/lists.beam

.PHONY: host-atomvm-smoke host-atomvm-smoke-avm clean-host-atomvm-smoke

host-atomvm-smoke: host-atomvm-smoke-avm
	@test -x "$(HOST_ATOMVM)" || (echo "HOST_ATOMVM not executable: $(HOST_ATOMVM)" >&2; exit 127)
	@test -f "$(ATOMVMLIB)" || (echo "missing atomvmlib: $(ATOMVMLIB)" >&2; exit 127)
	@test -f "$(ESTDLIB)" || (echo "missing estdlib: $(ESTDLIB)" >&2; exit 127)
	@test -f "$(EXAVMLIB)" || (echo "missing exavmlib: $(EXAVMLIB)" >&2; exit 127)
	$(HOST_ATOMVM) $(HOST_ATOMVM_SMOKE_AVM) $(ATOMVMLIB) $(ESTDLIB) $(EXAVMLIB)

host-atomvm-smoke-avm: $(HOST_ATOMVM_SMOKE_SRC)
	MIX_ENV=$(MIX_ENV) $(MIX) deps.get
	MIX_ENV=$(MIX_ENV) $(MIX) deps.compile req --force
	MICRO_SCAFFOLD_REPO_BACKEND=atomvm MICRO_SCAFFOLD_INDEX3_URL=$(HOST_ATOMVM_INDEX3_URL) MIX_ENV=$(MIX_ENV) $(MIX) compile --force
	@mkdir -p $(HOST_ATOMVM_BUILD_DIR)
	$(ERLC) -o $(HOST_ATOMVM_BUILD_DIR) $(HOST_ATOMVM_SMOKE_SRC)
	@test -f "$(PACKBEAM)" || (echo "missing packbeam: $(PACKBEAM)" >&2; exit 127)
	@test -f "$(EUNIT_BEAM)" || (echo "missing AtomVM eunit beam: $(EUNIT_BEAM)" >&2; exit 127)
	@beam_list="$(HOST_ATOMVM_BUILD_DIR)/beams.list"; \
	: > "$$beam_list"; \
	printf "%s\n" "$(HOST_ATOMVM_SMOKE_BEAM)" "$(EUNIT_BEAM)" $(HOST_ATOMVM_RUNTIME_BEAMS) >> "$$beam_list"; \
	for dir in $(HOST_ATOMVM_APP_EBIN_DIRS); do \
		if [ -d "$$dir" ]; then \
			find "$$dir" -maxdepth 1 -type f -name '*.beam' >> "$$beam_list"; \
		else \
			echo "missing BEAM directory: $$dir" >&2; \
			exit 1; \
		fi; \
	done; \
	sort -u -o "$$beam_list" "$$beam_list"; \
	$(PYTHON) $(PACKBEAM) create -s $(HOST_ATOMVM_SMOKE) $(HOST_ATOMVM_SMOKE_AVM) $$(cat "$$beam_list")
	@echo "Host AtomVM smoke AVM: $(HOST_ATOMVM_SMOKE_AVM)"

clean-host-atomvm-smoke:
	rm -rf $(HOST_ATOMVM_BUILD_DIR)
