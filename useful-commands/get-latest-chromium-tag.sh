#!/bin/bash
chromium_tag=$(curl -s 'https://api.github.com/repos/chromium/chromium/tags' | grep -F '"name":' | sed -n 's/[ \t]*"name":[ ][ ]*"\(.*\)".*/\1/p' | grep -E '([0-9]+.){3}[0-9]+' | head -n 1)

echo "$chromium_tag" >&2

ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${chromium_tag} Safari/537.36"
if [ -z "$ua" ]; then
    echo "Empty reply" >&2
    exit 1
else
    echo "$ua"
fi

flags=("$HOME/.config/chromium-flags.conf" "$HOME/.config/chrome-flags.conf" "$HOME/.config/chrome-dev-flags.conf")
for flag in "${flags[@]}"; do
    if [ -e "$flag" ]; then
        if grep -Eq '^--user-agent=' "$flag"; then
            uae=${ua//\;/\\\;}
            uae=${uae//\//\\\/}
            tflag=$(mktemp -p /tmp chromium-flags.confXXXXXX)
            cp "$flag" "$tflag"
            sed -i "s/^--user-agent=.*$/--user-agent='${uae}'/g" "$flag"
            diff -u "$tflag" "$flag"
            echo "Modified ${flag}" >&2
            rm "$tflag"
        fi
    fi
done
