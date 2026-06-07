#!/usr/bin/env bash
# Scan staged (or named) files for PII and secrets. Exit 1 if anything is found.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

files=()
if [[ $# -gt 0 ]]; then
  files=("$@")
else
  while IFS= read -r line; do
    [[ -n "$line" ]] && files+=("$line")
  done < <(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
fi

if [[ ${#files[@]} -eq 0 ]]; then
  exit 0
fi

FOUND=0
ALLOWLIST_FILE="$REPO_ROOT/scripts/check-pii-allowlist.txt"

alert() {
  echo "PII/SECRET ALERT: $1"
  FOUND=1
}

is_allowed_token() {
  local token="$1"
  case "$token" in
    TICKER_*) return 0 ;;
  esac
  [[ "${token:0:2}" = "<<" ]] && return 0
  [[ -f "$ALLOWLIST_FILE" ]] && grep -Fxq "$token" "$ALLOWLIST_FILE" 2>/dev/null
}

is_probable_ticker() {
  local token="$1"
  [[ ${#token} -lt 3 || ${#token} -gt 15 ]] && return 1
  [[ "$token" =~ ^[A-Z][A-Z0-9-]+$ ]]
}

is_text_file() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  local mime
  mime="$(file -b --mime-type "$f" 2>/dev/null || echo "")"
  case "$mime" in
    text/*|application/json|application/xml|application/yaml|application/x-yaml) return 0 ;;
  esac
  grep -qI . "$f" 2>/dev/null
}

scan_content() {
  local f="$1"

  if grep -qE 'ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}' "$f" 2>/dev/null; then
    alert "$f — API key or token pattern"
  fi
  if grep -qE 'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY' "$f" 2>/dev/null; then
    alert "$f — private key block"
  fi
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -qiE 'environ|getenv|process\.env|\$\{\{[[:space:]]*secrets\.|YOUR_|example\.com|changeme|REDACTED|placeholder'; then
      continue
    fi
    if echo "$line" | grep -qiE '(api[_-]?key|secret|password|auth[_-]?token)[[:space:]]*[:=][[:space:]]*['\''"][A-Za-z0-9_./+-]{12,}['\''"]'; then
      alert "$f — hardcoded secret assignment"
      break
    fi
  done < <(grep -niE '(api[_-]?key|secret|password|auth[_-]?token)[[:space:]]*[:=]' "$f" 2>/dev/null || true)

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -qE 'github-actions\[bot\]@users\.noreply\.github\.com|@example\.com|@yourcompany\.com|REDACTED|\{\{'; then
      continue
    fi
    local email
    email="$(echo "$line" | grep -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | head -1 || true)"
    if [[ -n "$email" ]]; then
      alert "$f — email address: $email"
    fi
  done < <(grep -nE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$f" 2>/dev/null || true)

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -qE '^[0-9a-f]{32,}$|^[0-9]{16,}$'; then
      continue
    fi
    if echo "$line" | grep -qE '(\+1[-.[:space:]]?)?\(?[0-9]{3}\)?[-.[:space:]]?[0-9]{3}[-.[:space:]]?[0-9]{4}|[0-9]{3}-[0-9]{2}-[0-9]{4}'; then
      alert "$f — phone or SSN-like number pattern"
      break
    fi
  done < <(grep -nE '(\+1[-.[:space:]]?)?\(?[0-9]{3}\)?| [0-9]{3}-[0-9]{2}-[0-9]{4}' "$f" 2>/dev/null || true)

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -qE '^[0-9a-f]{32,}$|^[0-9]{16,}$'; then
      continue
    fi
    if echo "$line" | grep -qE '[0-9]{4}[-[:space:]]?[0-9]{4}[-[:space:]]?[0-9]{4}[-[:space:]]?[0-9]{4}'; then
      alert "$f — credit-card-like number pattern"
      break
    fi
  done < <(grep -nE '[0-9]{4}[-[:space:]]?[0-9]{4}[-[:space:]]?[0-9]{4}[-[:space:]]?[0-9]{4}' "$f" 2>/dev/null || true)
  if grep -qiE '(routing|account)[_-]?(number|no)[[:space:]]*[:=]?[[:space:]]*[0-9]{6,}' "$f" 2>/dev/null; then
    alert "$f — bank account / routing reference"
  fi

  if grep -qE '/Users/[^/]+/Library/CloudStorage/GoogleDrive-[^/]+@gmail\.com' "$f" 2>/dev/null; then
    alert "$f — absolute path with personal Google account email"
  fi

  scan_financial_metadata "$f"
}

scan_financial_metadata() {
  local f="$1"

  # Policy docs describe patterns to block — do not self-flag
  case "$f" in
    rules/no-pii-push.mdc|engineering-skills/no-pii-push/SKILL.md|docs/*)
      return 0
      ;;
  esac

  # Specific holding counts from a real portfolio book (20+ avoids "Top 10 Holdings" chart titles)
  if grep -qE '\b([2-9][0-9]|[1-9][0-9]{2}|100)[[:space:]]+holdings\b' "$f" 2>/dev/null; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      echo "$line" | grep -qiE 'top [0-9]+|cardheader|by value|by magnitude' && continue
      alert "$f — specific holdings count (portfolio metadata)"
      break
    done < <(grep -nE '\b([2-9][0-9]|[1-9][0-9]{2}|100)[[:space:]]+holdings\b' "$f" 2>/dev/null || true)
  fi
  if grep -qE '\b([2-9][0-9]|[1-9][0-9]{2}|100)[[:space:]]+equity[[:space:]]+(stocks|holdings)\b' "$f" 2>/dev/null; then
    alert "$f — specific equity count (portfolio metadata)"
  fi

  # Brokerage account IDs (IBKR-style)
  if grep -qE '\bU[0-9]{6,12}\b' "$f" 2>/dev/null; then
    alert "$f — brokerage account ID pattern (U########)"
  fi

  # Cluster definitions: TICKER + TICKER (quoted or bare)
  if grep -qE "'[A-Z][A-Z0-9-]{2,14}'[[:space:]]*\+[[:space:]]*'[A-Z][A-Z0-9-]{2,14}'" "$f" 2>/dev/null; then
    alert "$f — stock ticker cluster list (quoted symbols joined with +)"
  fi
  if grep -qE '\b[A-Z][A-Z0-9-]{3,14}[[:space:]]+\+[[:space:]]+[A-Z][A-Z0-9-]{3,14}\b' "$f" 2>/dev/null; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      echo "$line" | grep -qE 'TICKER_|placeholder|example|generic' && continue
      alert "$f — stock ticker cluster list (symbols joined with +)"
      break
    done < <(grep -nE '\b[A-Z][A-Z0-9-]{3,14}[[:space:]]+\+[[:space:]]+[A-Z][A-Z0-9-]{3,14}\b' "$f" 2>/dev/null || true)
  fi

  # Symbol + weight on same line (e.g. HDFCBANK at 6.75%)
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    echo "$line" | grep -qiE 'TICKER_|placeholder|example|Theme [ABC]:' && continue
    local sym
    sym="$(echo "$line" | grep -oE '\b[A-Z][A-Z0-9-]{3,14}\b' | head -1 || true)"
    [[ -z "$sym" ]] && continue
    is_allowed_token "$sym" && continue
    if echo "$line" | grep -qE '[0-9]+\.[0-9]+%|[0-9]+% of (NAV|portfolio|equity)'; then
      alert "$f — ticker with portfolio weight: $sym"
      break
    fi
  done < <(grep -nE '[0-9]+\.[0-9]+%' "$f" 2>/dev/null || true)

  # Arrays of probable tickers (THEME_CLUSTERS, position lists)
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    echo "$line" | grep -qE 'TICKER_[A-Z]|FOO|BAR|XYZ|EXAMPLE|placeholder' && continue
    local hit=0
    while IFS= read -r sym; do
      [[ -z "$sym" ]] && continue
      is_allowed_token "$sym" && continue
      if is_probable_ticker "$sym"; then
        hit=1
        break
      fi
    done < <(echo "$line" | grep -oE "'[A-Z][A-Z0-9-]{2,14}'" | tr -d "'" || true)
    if [[ "$hit" -eq 1 ]]; then
      # Require list context: cluster, array, or multiple symbols on one line
      if echo "$line" | grep -qE 'THEME_CLUSTERS|\[[[:space:]]*'\''[A-Z]|[[:space:]]'\''[A-Z][A-Z0-9-]+'\''[[:space:]]*,[[:space:]]*'\''[A-Z]'; then
        alert "$f — real stock ticker(s) in cluster/array (use TICKER_A placeholders)"
        break
      fi
    fi
  done < <(grep -nE "'[A-Z][A-Z0-9-]{2,14}'" "$f" 2>/dev/null || true)
}

for f in "${files[@]}"; do
  [[ -z "$f" ]] && continue

  case "$f" in
    scripts/check-pii.sh|scripts/check-pii-allowlist.txt|scripts/hooks/pre-push|scripts/install-git-hooks.sh)
      continue
      ;;
    *.env|*.env.*|*.pem|*.key|*.p12|*.pfx|*.cookie|credentials*.json|*activity-statement*|*portfolio*.csv|*portfolio*.xlsx|*multigroup*.xlsx)
      alert "$f — sensitive file type (should not be committed)"
      continue
      ;;
  esac

  is_text_file "$f" || continue
  scan_content "$f"
done

if [[ "$FOUND" -eq 1 ]]; then
  echo
  echo "Push blocked. Remove or redact the items above, then re-stage and try again."
  exit 1
fi

exit 0
