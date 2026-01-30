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

# Helper: given (user, repo) print full GitHub repo URL
full_repo_url() {
  local user="$1" repo="$2"
  printf 'https://github.com/%s/%s' "$user" "$repo"
}
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
jq -r '.personal[] | [ .name, .user, .repo, (.description // ""), (.role // "") ] | join("\u0001")' "$DATA_FILE" | \
while IFS=$'\u0001' read -r name user repo desc role; do
  repo_path="${user}/${repo}"
  full_url="$(full_repo_url "$user" "$repo")"
  stars_badge="https://img.shields.io/github/stars/${repo_path}"
  cat >> "$OUT_FILE" <<ROW
			<tr>
				<th span="row"><a href="$full_url">$name</a></th>
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
jq -r '.contributions[] | [ .name, .user, .repo, (.role // ""), (.pr_html // "") ] | join("\u0001")' "$DATA_FILE" | \
while IFS=$'\u0001' read -r name user repo role pr_html; do
  repo_path="${user}/${repo}"
  full_url="$(full_repo_url "$user" "$repo")"
  commits_badge="https://img.shields.io/github/commit-activity/t/${repo_path}?authorFilter=jnullj"

  if [[ -n "$pr_html" ]]; then
    pr_cell="$pr_html"
  else
    # PR badges (open / merged / reviewed / involvement) — encode queries for shields.io
    q_open="repo:${repo_path} is:open is:pr author:jnullj"
    q_merged="repo:${repo_path} is:pr author:jnullj is:merged"
    q_reviewed="repo:${repo_path} is:pr reviewed-by:jnullj -author:jnullj"
    q_invol="repo:${repo_path} involves:jnullj"

    enc_open=$(jq -nr --arg q "$q_open" '$q|@uri')
    enc_merged=$(jq -nr --arg q "$q_merged" '$q|@uri')
    enc_reviewed=$(jq -nr --arg q "$q_reviewed" '$q|@uri')
    enc_invol=$(jq -nr --arg q "$q_invol" '$q|@uri')

    # Encode labels as well
    label_open="open pr by jnullj"
    label_merged="merged pr by jnullj"
    label_reviewed="pr reviewed by jnullj"
    label_involv="involvment by jnullj"

    enc_label_open=$(jq -nr --arg l "$label_open" '$l|@uri')
    enc_label_merged=$(jq -nr --arg l "$label_merged" '$l|@uri')
    enc_label_reviewed=$(jq -nr --arg l "$label_reviewed" '$l|@uri')
    enc_label_involv=$(jq -nr --arg l "$label_involv" '$l|@uri')

    open_pr="https://img.shields.io/github/issues-search?query=${enc_open}&label=${enc_label_open}&color=green"
    merged_pr="https://img.shields.io/github/issues-search?query=${enc_merged}&label=${enc_label_merged}&color=purple"
    reviewed_pr="https://img.shields.io/github/issues-search?query=${enc_reviewed}&label=${enc_label_reviewed}"
    involvement="https://img.shields.io/github/issues-search?query=${enc_invol}&label=${enc_label_involv}"

    pr_cell="<img alt=\"open pr by jnullj\" src=\"${open_pr}\" /><img alt=\"merged pr by jnullj\" src=\"${merged_pr}\" /><img alt=\"pr reviewed by jnullj\" src=\"${reviewed_pr}\" /><img alt=\"involvment by jnullj\" src=\"${involvement}\" />"
  fi

  cat >> "$OUT_FILE" <<ROW
		<tr>
      <th span="row"><a href="$full_url">$name</a></th>
			<td>
				$pr_cell
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
