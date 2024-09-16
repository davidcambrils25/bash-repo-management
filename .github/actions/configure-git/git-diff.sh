#!/bin/bash

GIT_PATH=$1
RUNNER_ID=$2
REPO_MANAGEMENT_PATH=$3
OUTPUT_DIR=$4
PR_NAME=$5
BINARY_NAME=""
COUNTRY=""
CHANGES_FOUND=false
declare -a NON_COBOL_FILES

cd $GIT_PATH

CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD)
echo "The modified files are: ${CHANGED_FILES}"

# Check if any files have been modified in the ES or PT directory
if echo $CHANGED_FILES | grep ES/; then
  COUNTRY="ES"
elif echo $CHANGED_FILES | grep PT/; then
  COUNTRY="PT"
else
  echo "There are no modified files in the directories /ES or /PT"
  exit 0
fi
echo "The selected country is: ${COUNTRY}"
echo "country=${COUNTRY}" >> $GITHUB_OUTPUT

# Iterate through files to find the COBOL file and collect non-COBOL files
for file in $CHANGED_FILES; do
  if [[ "$file" == *".cbl"* ]]; then
    # Process the COBOL file
    BINARY_NAME=$(basename "$file" .cbl)
    # Prepare folder COBOL for build only modified files
    cp "$GIT_PATH/$COUNTRY/COBOL-sources/${BINARY_NAME}.cbl" $GIT_PATH/$COUNTRY/COBOL

    # Check if the binary entry exists for the specified PR_NAME
    ENTRY_EXISTS=$(yq e ".${PR_NAME}.binaries[] | select(.name == \"$BINARY_NAME\")" $REPO_MANAGEMENT_PATH/artifacts_version.yml)

    if [ -z "$ENTRY_EXISTS" ]; then
      NEW_VERSION=1
      # Create new entry in the YAML file
      yq e ".${PR_NAME}.binaries += [{\"name\":\"$BINARY_NAME\", \"version\": \"$NEW_VERSION\"}]" -i $REPO_MANAGEMENT_PATH/artifacts_version.yml
    else
      # Find the highest version number across all PR_NAME entries
      CURRENT_VERSION=0
      for PR in $(yq e 'keys | .[]' $REPO_MANAGEMENT_PATH/artifacts_version.yml | grep -v 'global_version'); do
        CURRENT_VERSION=$(yq e ".${PR}.binaries[] | select(.name == \"$BINARY_NAME\") | .version" $REPO_MANAGEMENT_PATH/artifacts_version.yml | sort -V | tail -n1)
        if [[ "$VERSION" -gt "$CURRENT_VERSION" ]]; then
          CURRENT_VERSION=$VERSION
        fi
      done
      # Increment the version number
      NEW_VERSION=$((CURRENT_VERSION + 1))
      # Update the version of the entry
      yq e "(.${PR_NAME}.binaries[] | select(.name == \"$BINARY_NAME\" and .version == \"$CURRENT_VERSION\")) |= . + {\"version\": \"$NEW_VERSION\", \"runID\": \"$RUNNER_ID\"}" -i $REPO_MANAGEMENT_PATH/artifacts_version.yml
    fi

    # Update the runID
    yq e ".${PR_NAME}.runID = \"$RUNNER_ID\"" -i $REPO_MANAGEMENT_PATH/artifacts_version.yml

    CHANGES_FOUND=true
  else
    NON_COBOL_FILES+=("$file")
    echo $NON_COBOL_FILES
  fi
done

echo "files to be compiled:"
ls $GIT_PATH/$COUNTRY/COBOL

echo "changes_found=${CHANGES_FOUND}" >> $GITHUB_OUTPUT