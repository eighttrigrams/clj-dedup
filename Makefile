.PHONY: test install

test:
	clojure -M:test

install:
	bbin install . --as clj-dedup --main-opts '["-m" "clj-dedup.core"]'
