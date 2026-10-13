SHELL := /bin/bash
.DEFAULT_GOAL := check

BINARY  := bin/tfkit
VERSION ?= 0.1.0

.PHONY: check fmt vet test build install clean

check: fmt vet test build

fmt:
	@echo "==> gofmt -s -l ."
	@unformatted="$$(gofmt -s -l .)"; \
	if [[ -n "$$unformatted" ]]; then \
	  echo "error: unformatted Go files:" >&2; \
	  echo "$$unformatted" >&2; \
	  exit 1; \
	fi

vet:
	@echo "==> go vet ./..."
	@go vet ./...

test:
	@echo "==> go test -race -cover ./..."
	@go test -race -cover ./...

build:
	@echo "==> go build $(BINARY)"
	@mkdir -p bin
	@go build -buildvcs=false -trimpath -ldflags="-s -w -X github.com/hatan4ik/tfkit/internal/cli.Version=$(VERSION)" -o "$(BINARY)" ./cmd/tfkit

install:
	@go install -buildvcs=false -trimpath -ldflags="-s -w -X github.com/hatan4ik/tfkit/internal/cli.Version=$(VERSION)" ./cmd/tfkit

clean:
	@rm -rf bin/

