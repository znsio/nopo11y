
readonly KEY_EXPOSED="exposed"
readonly KEY_DEPENDENT="dependent"
readonly KEY_DECLARED="declared"
readonly KEY_REQUIRED="required"

readonly KEY_WARN="warn"
readonly KEY_ERROR="error"

readonly GENERATE_COMP_ARTIFACTS="generateComponentArtifacts"
readonly GENERATE_API_ARTIFACTS="generateApiArtifacts"
readonly GENERATE_NOPOLLY_API_ARTIFACTS="generateNopo11yApiArtifacts"
readonly RUN_API_CTKS_FROM_COMP_ARTIFACTS="runApiCtksFromComponentArtifacts"

readonly WORKDIR_SUfFIX_CA="comp-build"
readonly WORKDIR_SUfFIX_AA="api-build"
readonly WORKDIR_SUfFIX_NAA="api-build-np"
readonly WORKDIR_SUfFIX_CR="ctk-run"

readonly ODAC_REPO_URL=$(compSpecRepoUrl)
readonly ODAC_REPO_BRANCH=$(compSpecRepoBranch)
readonly ODAC_SPEC_VER=$(compSpecRepoVersionDir)
readonly ODAC_REPO_CO_DIRS="$ODAC_SPEC_VER"

readonly ODAA_REPO_URL=$(apiSpecRepoUrl)
readonly ODAA_REPO_BRANCH=$(apiSpecRepoBranch)
readonly ODAA_SPEC_DIR_NAME=$(apiSpecRepoSpecDir)
readonly ODAA_CTK_SPEC_DIR_NAME=$(apiSpecRepoCtkDir)
readonly ODAA_REPO_CO_DIRS="$ODAA_SPEC_DIR_NAME,$ODAA_CTK_SPEC_DIR_NAME"

readonly GIT_AUTH_TOKEN_ADO=$(specRepoAdoAuth)
readonly GIT_AUTH_TOKEN_LOCAL=$(specRepoLocalAuth)
readonly GIT_REPO_PROXY=$(specRepoProxy)

readonly ALL_ENVS=$(allEnvsAsSsv)
readonly ENV_EAT="eat"
readonly ENV_PROD="prod"
readonly ENV_LOCAL="local"

readonly CHECKOUT_OPTION=$(specRepoCheckoutMode)
readonly INPUT_ODAA_PROJECT_PATH=$(apiProjectPath)
readonly INPUT_ODAC=$(compCodeCheckoutDir)
readonly WORKDIR=$(workDir)

readonly ACTION=$(requestedAction)

readonly RUNTIME_MODE=$(runtimeMode)
readonly RUNTIME_MODE_LOCAL="local"
readonly RUNTIME_MODE_ADO="ado"

readonly RUNTIME_HOST=$(runtimeHost)
readonly RUNTIME_HOST_STANDALONE="local_or_vm"
readonly RUNTIME_HOST_CONTAINER="container"

declare -rA SPEC_MISMATCH_ACTION=(
    ["$KEY_EXPOSED"]=$(onSpecMismatchForApi "$KEY_EXPOSED")
    ["$KEY_DEPENDENT"]=$(onSpecMismatchForApi "$KEY_DEPENDENT")
)

readonly API_ARTIFACTS_PATH=$(apiArtifactCopyPath)
readonly API_ARTIFACT_REPO_URL=$(apiArtifactRepoUrl)
readonly API_ARTIFACT_REPO_CRED=$(apiArtifactRepoCred)

readonly CTK_EXEC_FILE_NAME="Mac-Linux-RUNCTK.sh"
readonly CTK_RESULTS_JSON_FILE_NAME="jsonResults.json"
readonly CTK_RESULTS_HTML_FILE_NAME="htmlResults.html"

readonly CMP_ARTIFACTS_PATH=$(compArtifactsPath)
readonly ON_CTK_FAILURE=$(onCtkFailure)
readonly APP_HOST=$(appHost)
readonly APP_PROTOCOL=$(appProtocol)
readonly APP_ENV=$(appEnv)