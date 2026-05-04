#!/bin/bash
set -e

echo "=== Generating xcconfig from environment variables ==="

# Xcode Cloud 환경변수에서 xcconfig 파일 생성
# xcconfig에서 //는 주석이므로 :// → :/$()/로 escape
ESCAPED_SUPABASE_URL=$(echo "$SUPABASE_URL" | sed 's|://|:/$()/|g')

mkdir -p "$CI_PRIMARY_REPOSITORY_PATH/Config"

cat > "$CI_PRIMARY_REPOSITORY_PATH/Config/App-Debug.xcconfig" <<EOF
SUPABASE_URL=${ESCAPED_SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
ENV=DEBUG
GOOGLE_BOOKS_API_KEY=${GOOGLE_BOOKS_API_KEY}
EOF

cat > "$CI_PRIMARY_REPOSITORY_PATH/Config/App-Release.xcconfig" <<EOF
SUPABASE_URL=${ESCAPED_SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
ENV=RELEASE
GOOGLE_BOOKS_API_KEY=${GOOGLE_BOOKS_API_KEY}
EOF

echo "=== xcconfig files generated ==="

echo "=== Installing mise ==="
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

echo "=== Installing Tuist via mise ==="
mise install tuist@4.134.0
eval "$(mise activate bash)"

echo "=== Tuist version ==="
tuist version

echo "=== Installing dependencies ==="
tuist install

echo "=== Generating project ==="
tuist generate --no-open

echo "=== Done ==="
