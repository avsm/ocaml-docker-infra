ALL=$(wildcard Dockerfile.*)
LOGS=$(ALL:Dockerfile.%=log.%)

all: $(LOGS)
	@ :

log.%: Dockerfile.%
	rm -f ok.$* err.$*
	if docker build --rm -f $* . >log.$* 2>&1; then \
		touch ok.$*; \
	else \
		touch err.$*; \
	fi

clean:
	rm -f $(LOGS) ok.* err.*
