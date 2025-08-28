#!/bin/bash
shopt -s nullglob
LOGFILE="/home/kipr/voldigate_update.log"

sudo touch "$LOGFILE"
sudo chmod 666 "$LOGFILE"

>"$LOGFILE"

exec &> >(tee -a "$LOGFILE")

OLD_USER_JSON="/home/kipr/Documents/KISS/users.json"
NEW_USER_JSON="/home/kipr/Documents/KISS/newUsers.json"
HOME_DIR="/home/kipr/Documents/KISS"
SCRIPT_DIR="$(dirname "$0")"
JQ="$SCRIPT_DIR/pkgs/jq-linux64" #jq-linux64 testing on computer, pkgs/jq-linux-arm64 for pi once ready
#Get all directories stored in /home/kipr/Documents/KISS - Users
for dir in "$HOME_DIR"/*; do
    if [ -d "$dir" ]; then
        echo "User Directory: $dir"
        userName=$(basename "$dir")
        userPath_array+=(${dir})
        user_array+=(${userName})
    elif [ -f "$dir" ]; then
        echo "File: $dir"

    fi
done

echo "user_array: ${user_array[@]}"
echo "userPath_array: ${userPath_array[@]}"

voldigateJson=$(printf '%s\n' "${user_array[@]}" | "$JQ" -Rn '
  [inputs] | reduce .[] as $item ({}; .[$item] = {})
')

#Read old users.json to get user interface
oldUsersJson=$(cat "$OLD_USER_JSON")

# Iterate users and collect projects safely
for userPath in "${userPath_array[@]}"; do
    userName=$(basename "$userPath")
    projects_json_list=()

    for projDir in "$userPath"/*; do
        [ -d "$projDir" ] || continue
        projectName=$(basename "$projDir")

        # Collect files in subdirectories
        includeFiles=()
        srcFiles=()
        dataFiles=()
        projectLanguage=""
        for subDir in "$projDir"/*; do
            [ -d "$subDir" ] || continue
            subDirName=$(basename "$subDir")
            case "$subDirName" in
            "include")
                for f in "$subDir"/*; do
                    [ -f "$f" ] || continue
                    includeFiles+=("$(basename "$f")")
                done
                ;;
            "src")
                for f in "$subDir"/*; do
                    [ -f "$f" ] || continue
                    filename=$(basename "$f")
                    [ "$filename" = "xmlToC.c" ] && continue # skip this file
                    # Detect main.* and extract the extension as projectLanguage
                    if [[ "$filename" == main.* ]]; then
                        ext="${filename##*.}"
                        projectLanguage="$ext"
                    fi
                    srcFiles+=("$filename")
                done
                ;;
            "data")
                for f in "$subDir"/*; do
                    [ -f "$f" ] || continue
                    dataFiles+=("$(basename "$f")")
                done
                ;;
            esac
        done

        if [ ${#includeFiles[@]} -gt 0 ]; then
            includeJSON=$(printf '%s\n' "${includeFiles[@]}" | "$JQ" -R -s .)
        else
            includeJSON='[]'
        fi

        if [ ${#srcFiles[@]} -gt 0 ]; then
            srcJSON=$(printf '%s\n' "${srcFiles[@]}" | "$JQ" -R . | "$JQ" -s .)
        else
            srcJSON='[]'
        fi

        if [ ${#dataFiles[@]} -gt 0 ]; then
            dataJSON=$(printf '%s\n' "${dataFiles[@]}" | "$JQ" -R -s .)
        else
            dataJSON='[]'
        fi

        # Build project JSON
        project_json=$("$JQ" -n \
            --arg projectName "$projectName" \
            --arg projectLanguage "$projectLanguage" \
            --argjson include "$includeJSON" \
            --argjson src "$srcJSON" \
            --argjson data "$dataJSON" \
            '{
        projectName: $projectName,
        projectLanguage: $projectLanguage,
        includeFolderFiles: $include,
        srcFolderFiles: $src,
        dataFolderFiles: $data
    }')

        projects_json_list+=("$project_json")
    done

    # Combine all projects into a JSON array
    all_projects_json=$(printf '%s\n' "${projects_json_list[@]}" | "$JQ" -s .)

    # Inject into the Voldigate JSON
    voldigateJson=$(
        echo "$voldigateJson" | "$JQ" \
            --arg user "$userName" \
            --argjson oldUsers "$oldUsersJson" \
            --argjson projs "$all_projects_json" \
            '.[$user] += {
      userName: $user,
      interfaceMode: ($oldUsers[$user].mode // "Default"),
      projects: $projs,
      classroomName: null
  }'
    )

done

# Output final JSON
echo "$voldigateJson"

exit 1

