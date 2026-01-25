#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_FILE="$ROOT/data/repos.json"
INTRO_FILE="$ROOT/content/intro.md"
HACK_FILE="$ROOT/content/hackathons.md"
OUT_FILE="$ROOT/README.md"

command -v jq >/dev/null 2>&1 || { echo "This script requires 'jq' (https://stedolan.github.io/jq/)." >&2; exit 1; }

intro_md=""
hack_md=""
if [[ -f "$INTRO_FILE" ]]; then
  intro_md=$(sed 's/^/\n/' "$INTRO_FILE")
fi
if [[ -f "$HACK_FILE" ]]; then
  hack_md=$(sed 's/^/\n- /' "$HACK_FILE")
fi

if [[ -f "$INTRO_FILE" ]]; then
  cat "$INTRO_FILE" > "$OUT_FILE"
  echo "" >> "$OUT_FILE"
fi

cat >> "$OUT_FILE" <<README
## Some of the repos you can find on my profile
<table width="100%">
    <thead>
        <th span="col">Project ⚙️</th>
        <th span="col">Description 📝</th>
        <th span="col">Role 👷‍♂️</th>
        <th span="col">Stars ⭐</th>
    </thead>
    <tbody>
README

# personal projects
jq -r '.personal[] | "\(.name)\u0001\(.url)\u0001\(.description)\u0001\(.role)"' "$DATA_FILE" | \
while IFS=$'\u0001' read -r name url desc role; do
  repo_path=$(echo "$url" | sed -E 's#https?://github.com/##' | sed 's#/$##')
  stars_badge="https://img.shields.io/github/stars/${repo_path}"
  cat >> "$OUT_FILE" <<ROW
		<tr>
			<th span="row"><a href="$url">$name</a></th>
			<td>$desc</td>
			<td>$role</td>
			<td><img alt="Stars: $name" src="$stars_badge" /></td>
		</tr>
ROW
done

cat >> "$OUT_FILE" <<README
    </tbody>
</table>

## Some contributions i made to others
<table width="100%">
    <thead>
        <th span="col">Project ⚙️</th>
        <th span="col">Pull requests 🏆</th>
        <th span="col">Role 👷‍♂️</th>
        <th span="col">Commits</th>
    </thead>
    <tbody>
README

# contributions
jq -r '.contributions[] | "\(.name)\u0001\(.url)\u0001\(.role)"' "$DATA_FILE" | \
while IFS=$'\u0001' read -r name url role; do
  repo_path=$(echo "$url" | sed -E 's#https?://github.com/##' | sed 's#/$##')
  # PR badges (open / merged / involvement)
  open_pr="https://img.shields.io/github/issues-search?query=repo%3A${repo_path}%20is%3Aopen%20is%3Apr%20author%3Ajnullj&label=open%20pr%20by%20jnullj&color=green"
  merged_pr="https://img.shields.io/github/issues-search?query=repo%3A${repo_path}%20is%3Apr%20author%3Ajnullj%20is%3Amerged&label=merged%20pr%20by%20jnullj&color=purple"
  involvement="https://img.shields.io/github/issues-search?query=repo%3A${repo_path}%20involves%3Ajnullj&label=involvment%20by%20jnullj"
  commits_badge="https://img.shields.io/github/commit-activity/t/${repo_path}?authorFilter=jnullj"
  cat >> "$OUT_FILE" <<ROW
		<tr>
			<th span="row"><a href="$url">$name</a></th>
			<td>
				<img alt="open pr by jnullj" src="$open_pr" />
				<img alt="merged pr by jnullj" src="$merged_pr" />
				<img alt="involvment by jnullj" src="$involvement" />
			</td>
			<td>$role</td>
			<td><img alt="Commits by jnullj" src="$commits_badge" /></td>
		</tr>
ROW
done

cat >> "$OUT_FILE" <<README
    </tbody>
</table>

## hackathons
$([[ -f "$HACK_FILE" ]] && sed -n '1,$p' "$HACK_FILE" || echo "- TBD")

README

echo "Generated $OUT_FILE"
