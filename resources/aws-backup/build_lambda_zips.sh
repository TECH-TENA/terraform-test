#!/bin/bash
set -euo pipefail

# Paths (relative to where you run the script)
LAMBDA_SCRIPTS_DIR="./modules/ami-cleanup/scripts"
LAMBDA_ZIP="./modules/ami-cleanup/lambda_function.zip"

LAYER_BUILD_DIR="./modules/ami-cleanup/layer-build"
LAYER_PYTHON_DIR="$LAYER_BUILD_DIR/python"
LAYER_ZIP="$LAYER_BUILD_DIR/requests_layer.zip"

# Check if pip3 is installed
if ! command -v pip3 &> /dev/null; then
    echo "Error: pip3 not found. Please install pip3 before running this script."
    exit 1
fi

echo "Ensuring required directories exist..."

mkdir -p "$LAMBDA_SCRIPTS_DIR"
mkdir -p "$LAYER_PYTHON_DIR"

echo "Installing Python dependencies (requests) into $LAYER_PYTHON_DIR..."
pip3 install --upgrade requests -t "$LAYER_PYTHON_DIR"

echo "Building Lambda function zip..."
cd "$LAMBDA_SCRIPTS_DIR"
zip -r -q "../lambda_function.zip" .
cd - > /dev/null

echo "Building Lambda layer zip..."
cd "$LAYER_PYTHON_DIR"
zip -r -q "../requests_layer.zip" .
cd - > /dev/null

echo "Rebuild complete!"
echo "Lambda function zip at: $LAMBDA_ZIP"
echo "Lambda layer zip at: $LAYER_ZIP"
