#!/usr/bin/env sh

# Get the type and message of the last commit in the main repository
BRANCH_CURRENT=$(git branch --show-current)

echo "$1"
echo "$2"
# Get the last commit if there is not current commit message provided
LAST_COMMIT=${1:-$(git log -1 --pretty=format:"%s")}
# Get the type of the commit
TYPE=$(echo $LAST_COMMIT | cut -d'(' -f1)
# Get the message of the commit
MESSAGE=$(echo $LAST_COMMIT | cut -d')' -f2)

echo "$TYPE($SUBMODULE_PATH)$MESSAGE"

exit 0;

git config --global push.default current

# Loop through all submodules
for SUBMODULE in $(git submodule --quiet foreach 'echo $path'); do
  SUBMODULE_PATH=${SUBMODULE#*/}
  if ! git diff --quiet HEAD "$SUBMODULE"; then
    # Commit and push the submodules with the same commit message
    (
      cd "$SUBMODULE" || exit
      git add .
      git commit -m "$TYPE($SUBMODULE_PATH)$MESSAGE"
      git push origin $BRANCH_CURRENT
    )

    # Return to root folder and commit the submodule new reference
    git add $SUBMODULE
    git commit --no-verify -m "chore(test-app)$MESSAGE - updated reference [skip ci]"
  fi
done

git config --global push.default simple
