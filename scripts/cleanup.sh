# Get the root directory of the repository
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$REPO_ROOT" ]; then
    echo "Not a git repository or unable to determine repository root."
    exit 1
fi

cd $REPO_ROOT
# Delete terraform directories and files
find "./modules" -type d -name '.terraform' -exec rm -rf {} \;
find "./modules" -type f -name 'terraform.tfstate' -exec rm -f {} \;
find "./modules" -type f -name 'terraform.tfstate.backup' -exec rm -f {} \;
find "./modules" -type f -name '.terraform.lock.hcl' -exec rm -f {} \;

find "./resources" -type d -name '.terraform' -exec rm -rf {} \;
find "./resources" -type f -name 'terraform.tfstate' -exec rm -f {} \;
find "./resources" -type f -name 'terraform.tfstate.backup' -exec rm -f {} \;
find "./resources" -type f -name '.terraform.lock.hcl' -exec rm -f {} \;

echo "Cleanup complete."