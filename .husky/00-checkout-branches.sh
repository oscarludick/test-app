#!/usr/bin/env sh

#Get branches to checkout
BRANCH_NAME=$1
BRANCH_DEFAULT=${2:-master}
BRANCH_CURRENT=$(git branch --show-current)

# Check branches are not equal
if [ "$BRANCH_NAME" == "$BRANCH_CURRENT" ]; then
  exit 0;
fi

# Check if BRANCH_NAME is empty
if [ -z "$BRANCH_NAME" ]; then
  echo "Error: Branch name not specified."
  exit 1
fi

git stash save --keep-index "stash changes to checkout branch $BRANCH_NAME"

# Check if branch exists in main repo
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
  # If branch exists, switch to it if not already on it
  if ! git rev-parse --abbrev-ref HEAD | grep -q "^$BRANCH_NAME$"; then
    git checkout $BRANCH_NAME
  fi
else
  # If branch does not exist, create and checkout it in main repo
  git checkout -b $BRANCH_NAME $BRANCH_DEFAULT
fi

for SUBMODULE in $(git submodule --quiet foreach 'echo $path'); do
  # Check if there are changes in the submodule
  if (cd $SUBMODULE && git diff --quiet) && (cd $SUBMODULE && git diff --quiet --staged); then
    # If no changes in submodule, skip creating and checking out branch
    continue
  fi

  if (cd $SUBMODULE && git show-ref --verify --quiet refs/heads/$BRANCH_NAME); then
    # If branch exists in submodule, switch to it if not already on it
    if ! git -C $SUBMODULE rev-parse --abbrev-ref HEAD | grep -q "^$BRANCH_NAME$"; then
      (cd $SUBMODULE && git checkout $BRANCH_NAME)
    fi
  else
    # If branch does not exist in submodule, create and checkout it
    (cd $SUBMODULE && git checkout -b $BRANCH_NAME $BRANCH_DEFAULT)
  fi
done

git stash apply
