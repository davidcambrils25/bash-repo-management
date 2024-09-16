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


# Iterate through files to find the COBOL file and collect non-COBOL files
for file in $CHANGED_FILES; do
  if [[ "$file" == *".cbl"* ]]; then
    # Process the COBOL file
    BINARY_NAME=$(basename "$file" .cbl)
    # Prepare folder COBOL for build only modified files
    cp "$GIT_PATH/$COUNTRY/COBOL-sources/${BINARY_NAME}.cbl" $GIT_PATH/$COUNTRY/COBOL

    # Iterate over all keys in the YAML file
    ENTRY_EXISTS=false
    CURRENT_VERSION=0
    for PR in $(yq e 'keys | .[]' $REPO_MANAGEMENT_PATH/artifacts_version.yml | grep -v 'global_version'); do
      # Check if the binary name exists in the current PR entry
      BINARY_ENTRY=$(yq e ".${PR}.binaries[] | select(.name == \"$BINARY_NAME\")" $REPO_MANAGEMENT_PATH/artifacts_version.yml)
      if [ -n "$BINARY_ENTRY" ]; then
        ENTRY_EXISTS=true
        VERSION=$(yq e ".${PR}.binaries[] | select(.name == \"$BINARY_NAME\") | .version" $REPO_MANAGEMENT_PATH/artifacts_version.yml | sort -V | tail -n1)
        if [[ "$VERSION" -gt "$CURRENT_VERSION" ]]; then
          CURRENT_VERSION=$VERSION
        fi
      fi
    done

    if [ "$ENTRY_EXISTS" = false ]; then
      NEW_VERSION=1
    else
      # Increment the version number
      NEW_VERSION=$((CURRENT_VERSION + 1))
    fi

    # Check if the binary name exists in the PR_NAME
    BINARY_EXISTS=$(yq e ".${PR_NAME}.binaries[] | select(.name == \"$BINARY_NAME\")" $REPO_MANAGEMENT_PATH/artifacts_version.yml)
    if [ -n "$BINARY_EXISTS" ]; then
      # Update the version of the existing binary
      yq e "(.${PR_NAME}.binaries[] | select(.name == \"$BINARY_NAME\")) |= . + {\"version\": \"$NEW_VERSION\"}" -i $REPO_MANAGEMENT_PATH/artifacts_version.yml
    else
      # Add a new binary entry if it doesn't exist
      yq e ".${PR_NAME}.binaries += [{\"name\":\"$BINARY_NAME\", \"version\": \"$NEW_VERSION\"}]" -i $REPO_MANAGEMENT_PATH/artifacts_version.yml
    fi
    CHANGES_FOUND=true
  else
    NON_COBOL_FILES+=("$file")
    echo $NON_COBOL_FILES
  fi
done
# Update the runID
yq e ".${PR_NAME}.runID = \"$RUNNER_ID\"" -i $REPO_MANAGEMENT_PATH/artifacts_version.yml

echo "files to be compiled:"
ls $GIT_PATH/$COUNTRY/COBOL

# Process non-COBOL files
for file in "${NON_COBOL_FILES[@]}"; do
  if [ -n "$BINARY_NAME" ]; then
    SOURCE_FILE=$(basename "$file")
    # Add non-COBOL files under the specific PR_NAME
    yq e ".${PR_NAME}.sources += [\"$SOURCE_FILE\"]" -i $REPO_MANAGEMENT_PATH/artifacts_version.yml
    # Copy the non-COBOL file to the Output directory with compiled COBOL files
    cp $GIT_PATH/"$file" ${OUTPUT_DIR}/
  fi
done

cat $REPO_MANAGEMENT_PATH/artifacts_version.yml

echo "files to be uploaded to Artifact Registry:"
ls ${OUTPUT_DIR}/

echo "changes_found=${CHANGES_FOUND}" >> $GITHUB_OUTPUT
echo "country=${COUNTRY}" >> $GITHUB_OUTPUT