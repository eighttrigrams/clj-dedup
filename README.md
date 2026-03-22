# clj-dedup

Duplicate code detection for Clojure, leveraging homoiconicity.

## Install

Requires [bbin](https://github.com/babashka/bbin).

```sh
make install
```

This installs `clj-dedup` as a CLI command via bbin.

## Usage

```sh
clj-dedup                    # analyze ./src
clj-dedup path/to/file.clj   # analyze a single file
clj-dedup path/to/dir        # analyze a directory
```

## Development

```sh
make test
```
