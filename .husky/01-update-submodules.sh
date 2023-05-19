#!/usr/bin/env sh

# Get the type and message of the last commit in the main repository
BRANCH_CURRENT=$(git branch --show-current)

#Format message commit
LAST_COMMIT= ${1:-$(git log -1 --pretty=format:"%s")}
TYPE=$(echo $LAST_COMMIT | cut -d'(' -f1)
MESSAGE=$(echo $LAST_COMMIT | cut -d')' -f2 | xargs)

echo $LAST_COMMIT
echo $TYPE
echo $MESSAGE

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
