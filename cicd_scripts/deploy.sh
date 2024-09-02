OWNER=$1
REPO=$2
WORKFLOW_RUN_ID=$3
GITHUB_TOKEN=$4
ARTIFACT_NAME=$5
ARTIFACT_VERSION=$6
DEPLOYMENT_PATH=$7
declare -a GIT_ARTIFACT

GIT_ARTIFACT=$ARTIFACT_NAME-$ARTIFACT_VERSION

# List artifacts for the workflow run to find the artifact ID
ARTIFACTS_URL="https://api.github.com/repos/$OWNER/$REPO/actions/runs/$WORKFLOW_RUN_ID/artifacts"
ARTIFACTS_JSON=$(curl -s -H "Authorization: token $GITHUB_TOKEN" $ARTIFACTS_URL)
ARTIFACT_ID=$(echo $ARTIFACTS_JSON | jq --arg GIT_ARTIFACT "$GIT_ARTIFACT" '.artifacts[] | select(.name==$GIT_ARTIFACT) | .id')

# Check if the artifact ID was found
if [ -z "$ARTIFACT_ID" ]; then
  echo "Artifact $ARTIFACT_NAME with version $ARTIFACT_VERSION not found"
  exit 1
fi

# Download the artifact
DOWNLOAD_URL="https://api.github.com/repos/$OWNER/$REPO/actions/artifacts/$ARTIFACT_ID/zip"
curl -L -o "$ARTIFACT_NAME.zip" -H "Authorization: token $GITHUB_TOKEN" $DOWNLOAD_URL

echo "Artifact $GIT_ARTIFACT donwloaded"

mv ./$ARTIFACT_NAME.zip $DEPLOYMENT_PATH
cd $DEPLOYMENT_PATH
unzip $ARTIFACT_NAME.zip
rm $ARTIFACT_NAME.zip
echo "List of files in Deployment path:"
ls -l
