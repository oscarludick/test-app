#!/usr/bin/env sh

# Get the type and message of the last commit in the main repository
BRANCH_CURRENT=$(git branch --show-current)

#Format message commit
TYPE=$(echo $LAST_COMMIT | cut -d'(' -f1)
LAST_COMMIT=$(git log -1 --pretty=format:"%s")
MESSAGE=$(echo $LAST_COMMIT | cut -d')' -f2 | xargs)

# Loop through all submodules
for SUBMODULE in $(git submodule --quiet foreach 'echo $path'); do
  SUBMODULE_PATH=${SUBMODULE#*/}
  if ! git diff --quiet HEAD "$SUBMODULE"; then
    # Commit and push the submodules with the same commit message
    (
      cd "$SUBMODULE" || exit
      git add .
      git commit -m "$TYPE($SUBMODULE_PATH)$MESSAGE"
      git push --quiet || git push --quiet --set-upstream origin $BRANCH_CURRENT
    )

    # Return to root folder and commit the submodule new reference
    git add $SUBMODULE
    git commit --no-verify -m "chore(test-app)$MESSAGE - updated reference [skip ci]"
  fi
done
