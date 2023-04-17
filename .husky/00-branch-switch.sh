
BRANCH_NAME=$(git branch --show-current)
echo "You are about to commit" $(git diff --cached --name-only --diff-filter=ACM)
echo "to $BRANCH_NAME"

while : ; do
    read -p "Do you want to switch branch? [y/n] " RESPONSE < /dev/tty
    case "${RESPONSE}" in
        [Yy]* )
          read -p "Branch name? " BRANCH_NAME < /dev/tty
          break;;
        [Nn]* )
          echo "Will be using $BRANCH_NAME"
          break;;
    esac
done

# Check if BRANCH_NAME is empty
if [ -z "$BRANCH_NAME" ]; then
  echo "Error: Branch name not specified."
  exit 1
fi

# Check if branch exists in main repo
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
  # If branch exists, switch to it if not already on it
  if ! git rev-parse --abbrev-ref HEAD | grep -q "^$BRANCH_NAME$"; then
    #git checkout $BRANCH_NAME
    echo " If branch exists, switch to it if not already on it"
  fi
else
  # If branch does not exist, create and checkout it in main repo
  #git branch $BRANCH_NAME
  #git checkout $BRANCH_NAME
  echo "If branch does not exist, create and checkout it in main repo"
fi

# Check if branch exists in each submodule and create/checkout if necessary
SUBMODULE_DIRS=""
git submodule foreach 'SUBMODULE_DIRS="$SUBMODULE_DIRS $path"'

echo "$SUBMODULE_DIRS"

for SUBMODULE in $SUBMODULE_DIRS; do
  # Check if there are changes in the submodule
  if (cd $SUBMODULE && git diff --quiet) && (cd $SUBMODULE && git diff --quiet --staged); then
    # If no changes in submodule, skip creating and checking out branch
    echo "If no changes in submodule, skip creating and checking out branch"
    continue
  fi

  if (cd $SUBMODULE && git show-ref --verify --quiet refs/heads/$BRANCH_NAME); then
    # If branch exists in submodule, switch to it if not already on it
    if ! git -C $SUBMODULE rev-parse --abbrev-ref HEAD | grep -q "^$BRANCH_NAME$"; then
      #(cd $SUBMODULE && git checkout $BRANCH_NAME)
      echo "If branch exists in submodule, switch to it if not already on it"
    fi
  else
    # If branch does not exist in submodule, create and checkout it
    #(cd $SUBMODULE && git branch $BRANCH_NAME && git checkout $BRANCH_NAME)
    echo "If branch does not exist in submodule, create and checkout it"
  fi
done

# Exit with success status
exit 0
