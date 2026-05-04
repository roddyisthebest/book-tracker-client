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

# Xcode Cloud는 ci_scripts/ 에서 실행하므로 레포 루트로 이동
cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "=== Installing mise ==="
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

echo "=== Installing Tuist via mise ==="
mise install tuist@4.134.0

# CI 환경에서는 activate 대신 mise exec로 직접 실행
echo "=== Tuist version ==="
mise exec tuist@4.134.0 -- tuist version

echo "=== Installing dependencies ==="
mise exec tuist@4.134.0 -- tuist install

echo "=== Generating project ==="
mise exec tuist@4.134.0 -- tuist generate --no-open

echo "=== Done ==="
