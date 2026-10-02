#!/bin/sh
set -eu
echo "Unsupported: PL/Java 1.6.10 provides Maven/JUnit source tests only; running them rebuilds PL/Java and cannot validate the mounted extension payload." >&2
exit 77
