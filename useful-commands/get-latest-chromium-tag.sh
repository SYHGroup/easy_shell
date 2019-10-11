#!/bin/bash
curl -s 'https://api.github.com/repos/chromium/chromium/tags' | grep -F '"name":' | sed -n 's/[ \t]*"name":[ ][ ]*"\(.*\)".*/\1/p' | grep -E '([0-9]+.){3}[0-9]+' | head -n 1
