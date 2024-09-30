#!/usr/bin/env bash

set -e

# Check if a branch pattern is provided
if [ -z "$1" ]; then
  echo "Please provide a branch pattern (e.g., branch1 or DSS-3990)."
  exit 1
fi

BRANCH_PATTERN=$1
MAIN_BRANCH=${2:-master}  # Use 'master' as default if no second parameter is provided

# Fetch the latest branches
git fetch

# Checkout the main branch
git checkout $MAIN_BRANCH

# Find all commits in the main branch with commit messages that match the branch pattern
echo "Searching for commits with pattern '$BRANCH_PATTERN' in '$MAIN_BRANCH'..."
COMMIT_LIST=$(git log --pretty=format:"%H" --grep="^$BRANCH_PATTERN")

# Count the number of commits found
COMMIT_COUNT=$(echo "$COMMIT_LIST" | wc -l)

# If there is 1 commit or less, exit without doing anything
if [ "$COMMIT_COUNT" -le 1 ]; then
  echo "Only $COMMIT_COUNT commit(s) found with pattern '$BRANCH_PATTERN'. No need to squash."
  exit 0
fi

# Squash all the commits into a single commit using rebase
echo "Squashing $COMMIT_COUNT commits matching pattern '$BRANCH_PATTERN' into one commit..."

# Create a temporary file to store the commits to be squashed
TEMP_FILE=$(mktemp)

# Fill the temp file with the commits to be squashed
for commit in $COMMIT_LIST; do
    echo "$commit squash" >> $TEMP_FILE
done

# Use interactive rebase with an exact list of commits to squash
git rebase -i --autosquash $(tail -n 1 <<< "$COMMIT_LIST")

# Force push the changes to the main branch
git push origin $MAIN_BRANCH --force

# Clean up temporary file
rm $TEMP_FILE

echo "All $COMMIT_COUNT commits matching pattern '$BRANCH_PATTERN' have been squashed and force-pushed to '$MAIN_BRANCH'."
