#!/bin/sh
# Fill in the real links everywhere in one shot:
#   sh scripts/finalize-submission.sh <github_repo_url> <deployed_url> <drive_folder_url>
set -eu
[ $# -eq 3 ] || { echo "usage: $0 <github_repo_url> <deployed_url> <drive_folder_url>"; exit 1; }
REPO="$1"; APP="$2"; DRIVE="$3"
for f in DEVOPS.md README.md; do
  sed -i "s|GITHUB_REPO_URL_HERE|$REPO|g; s|DEPLOYED_URL_HERE|$APP|g; s|DRIVE_URL_HERE|$DRIVE|g" "$f"
done
echo "$REPO"  > submission/GitHub-Repository.txt
echo "$APP"   > submission/Deployed-Application.txt
echo "$DRIVE" > submission/Google-Drive.txt
echo "Done. Review DEVOPS.md and submission/*.txt"
