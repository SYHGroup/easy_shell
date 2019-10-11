#!/bin/bash
chromium_tag=$(curl -s 'https://api.github.com/repos/chromium/chromium/tags' | grep -F '"name":' | sed -n 's/[ \t]*"name":[ ][ ]*"\(.*\)".*/\1/p' | grep -E '([0-9]+.){3}[0-9]+' | head -n 1)

echo "$chromium_tag" >&2

echo "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${chromium_tag} Safari/537.36"
