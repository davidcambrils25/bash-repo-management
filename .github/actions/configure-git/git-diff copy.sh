#!/bin/bash

SOURCE_PATH=$1
BUILD_PATH=$2
RUNNER_ID=$3
REPO_MANAGEMENT_PATH=$4
BINARY_NAME=""
CHANGES_FOUND=false
declare -a NON_COBOL_FILES

cd $SOURCE_PATH

CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD)
echo "The modified files are: ${CHANGED_FILES}"


# Iterate through files to find the COBOL file and collect non-COBOL files
for file in $CHANGED_FILES; do
  if [[ "$file" == *".cbl"* && -z "$BINARY_NAME" ]]; then
    # Process the COBOL file
    BINARY_NAME=$(basename "$file" .cbl)
    cp "${SOURCE_PATH}/${BINARY_NAME}.cbl" $BUILD_PATH
    ls $BUILD_PATH
    echo "binary=${BINARY_NAME}" >> $GITHUB_OUTPUT

    # Check if the entry exists
    ENTRY_EXISTS=$(yq e ".binaries[] | select(.name == \"$BINARY_NAME\")" $REPO_MANAGEMENT_PATH/artifacts_version.yml)

    if [ -z "$ENTRY_EXISTS" ]; then
      NEW_VERSION=1
      # Create new entry in the YAML file
      yq e ".binaries += [{\"name\":\"$BINARY_NAME\", \"runID\":\"$RUNNER_ID\", \"version\": \"$NEW_VERSION\", \"sources\": []}]" -i $REPO_MANAGEMENT_PATH/artifacts_version.yml
    else
      # Search the last version
      CURRENT_VERSION=$(yq e ".binaries[] | select(.name == \"$BINARY_NAME\") | .version" $REPO_MANAGEMENT_PATH/artifacts_version.yml | sort -V | tail -n1)
      # Increment the version number
      NEW_VERSION=$((CURRENT_VERSION + 1))
      # Update the version of the entry
      yq e "(.binaries[] | select(.name == \"$BINARY_NAME\" and .version == \"$CURRENT_VERSION\") | .version) = \"$NEW_VERSION\"" -i $REPO_MANAGEMENT_PATH/artifacts_version.yml
    fi
    CHANGES_FOUND=true
  else
    NON_COBOL_FILES+=("$file")
    echo $NON_COBOL_FILES
  fi
done

echo "changes_found=${CHANGES_FOUND}" >> $GITHUB_OUTPUT
echo "version=${NEW_VERSION}" >> $GITHUB_OUTPUT

# Process non-COBOL files
for file in "${NON_COBOL_FILES[@]}"; do
  if [ -n "$BINARY_NAME" ]; then
    SOURCE_FILE=$(basename "$file")
    # Ensure to add non-COBOL files only to the latest version of the binary
    yq e "(.binaries[] | select(.name == \"$BINARY_NAME\" and .version == \"$NEW_VERSION\")).sources += [\"$SOURCE_FILE\"]" -i $REPO_MANAGEMENT_PATH/artifacts_version.yml
  fi
done

cat $REPO_MANAGEMENT_PATH/artifacts_version.yml
