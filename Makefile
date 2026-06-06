# linux-ops-lab-week1 — Makefile
# Convenience wrappers around the lab scripts. Targets the Ubuntu 24.04 VM.

SHELL := /bin/bash
.DEFAULT_GOAL := help

HEALTHY := lab-api lab-worker lab-scheduler lab-logger
BROKEN  := lab-cpu-hog lab-memory-leak lab-permission-bug

.PHONY: help install uninstall reset health \
        start stop restart status logs \
        break-cpu break-memory break-permissions clear-breaks \
        lint

help:  ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install:  ## Run install.sh (requires sudo).
	sudo ./install.sh

uninstall:  ## Remove all services, user, files (requires sudo).
	sudo ./uninstall.sh

reset:  ## Restore the lab to a healthy baseline (requires sudo).
	sudo ./reset-lab.sh

health:  ## Print a system + service snapshot.
	./healthcheck.sh

start:  ## Start the four healthy services.
	sudo systemctl start $(HEALTHY)

stop:  ## Stop the four healthy services.
	sudo systemctl stop $(HEALTHY)

restart:  ## Restart the four healthy services.
	sudo systemctl restart $(HEALTHY)

status:  ## Show systemctl status for all lab services.
	systemctl --no-pager status $(HEALTHY) $(BROKEN) || true

logs:  ## Tail journald logs for all lab services.
	journalctl -f $(addprefix -u ,$(HEALTHY) $(BROKEN))

break-cpu:  ## Inject the CPU starvation scenario.
	sudo systemctl start lab-cpu-hog

break-memory:  ## Inject the memory pressure scenario.
	sudo systemctl start lab-memory-leak

break-permissions:  ## Inject the permission denied scenario.
	sudo systemctl stop lab-permission-bug 2>/dev/null || true
	sudo touch /var/log/linux-ops-lab/permission-bug.log
	sudo chown root:root /var/log/linux-ops-lab/permission-bug.log
	sudo chmod 0600      /var/log/linux-ops-lab/permission-bug.log
	sudo systemctl start lab-permission-bug

clear-breaks:  ## Stop all failure services without resetting state.
	sudo systemctl stop $(BROKEN) || true

lint:  ## Syntax-check every shell script in the repo.
	@set -e; for f in install.sh uninstall.sh reset-lab.sh healthcheck.sh scripts/*.sh; do \
	  echo "  bash -n $$f"; bash -n "$$f"; \
	done; echo "  ok"
