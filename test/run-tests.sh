#!/bin/sh
# corpus suite runner. Usage: test/run-tests.sh
# QUINT_0331 and QUINT_0340 name the two Quint binaries; see the README.
set -e
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec janet "$here/corpus_test.janet"
