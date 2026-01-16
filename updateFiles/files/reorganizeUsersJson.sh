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
#JQ="../pkgs/jq-linux64" #jq-linux64 testing on computer, pkgs/jq-linux-arm64 for pi once ready
sudo cp ../pkgs/jq-linux-arm64 /usr/local/bin/jq
sudo chmod +x /usr/local/bin/jq
JQ=/usr/local/bin/jq
# Get all directories stored in /home/kipr/Documents/KISS - Users
for dir in "$HOME_DIR"/*; do
    if [ -d "$dir" ]; then
        userName=$(basename "$dir")
        
        # Skip the 'classrooms' folder
        if [ "$userName" = "classrooms" ]; then
            continue
        fi

        userPath_array+=("$dir")
        user_array+=("$userName")
    fi
done


#New voldigate structure for users.json
voldigateJson=$(printf '%s\n' "${user_array[@]}" | "$JQ" -Rn '
  [inputs] | reduce .[] as $item ({}; .[$item] = {})
')

#Make sure current users.json doesn't have trailing , (v31.1.2)
perl -pe 's/,\s*}/}/g' /home/kipr/Documents/KISS/users.json \
  |  "$JQ" . > /home/kipr/Documents/KISS/users.json.fixed

sudo mv /home/kipr/Documents/KISS/users.json.fixed /home/kipr/Documents/KISS/users.json

echo "Fixed users.json: $(< /home/kipr/Documents/KISS/users.json)"

#Read old users.json to get user interface
oldUsersJson=$(cat "$OLD_USER_JSON")

# Iterate users and collect projects safely
for userPath in "${userPath_array[@]}"; do
    userName=$(basename "$userPath")
    projects_json_list=()
    userMode=$(echo "$oldUsersJson" | jq -r --arg uname "$userName" '.[$uname].mode')

       echo "oldUsers[$userName].mode: $userMode"
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
            includeJSON=$(printf '%s\n' "${includeFiles[@]}" | "$JQ" -R . | "$JQ" -s .)
        else
            includeJSON='[]'
        fi

        if [ ${#srcFiles[@]} -gt 0 ]; then
            srcJSON=$(printf '%s\n' "${srcFiles[@]}" | "$JQ" -R . | "$JQ" -s .)
        else
            srcJSON='[]'
        fi

        if [ ${#dataFiles[@]} -gt 0 ]; then
            dataJSON=$(printf '%s\n' "${dataFiles[@]}" | "$JQ" -R . | "$JQ" -s .)
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

        echo "$project_json" >"$projDir/.project.config.json"
        projects_json_list+=("$project_json")
    done

    # Combine all projects into a JSON array
    all_projects_json=$(printf '%s\n' "${projects_json_list[@]}" | "$JQ" -s .)

    #Create .user.config.json that belongs in the User's root folder
    userConfigJson=$("$JQ" -n \
        --arg user "$userName" \
        --argjson projects "$all_projects_json" \
        --argjson oldUsers "$oldUsersJson" \
        '{
            userName: $user,
            interfaceMode: ($oldUsers[$user].mode // "Simple"),
            projects: $projects,
            classroomName: null
        }')

    echo "$userConfigJson" >"$userPath/.user.config.json"

    # Inject into the Voldigate JSON
    voldigateJson=$(
        echo "$voldigateJson" | "$JQ" \
            --arg user "$userName" \
            --argjson oldUsers "$oldUsersJson" \
            --argjson projs "$all_projects_json" \
            '.[$user] += {
      userName: $user,
      interfaceMode: ($oldUsers[$user].mode // "Simple"),
      projects: $projs,
      classroomName: null
  }'
    )

done

# Output final JSON
echo "$voldigateJson" >"$NEW_USER_JSON"

if [ -f "$NEW_USER_JSON" ]; then
    echo "Successfully created $NEW_USER_JSON"
    cat "$NEW_USER_JSON" > "$OLD_USER_JSON"
    rm "$NEW_USER_JSON"
else
    echo "Failed to create $NEW_USER_JSON"
    exit 1
fi
