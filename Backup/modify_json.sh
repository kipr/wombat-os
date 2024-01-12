#!/bin/bash

# Specify the path to the JSON file
json_file="users.json"

# Check if the specified JSON file exists
if [ ! -e "$json_file" ]; then
  echo "Error: The specified JSON file '$json_file' does not exist."
  exit 1
fi

# Extract and output only the keys from the JSON file
keys=$(cat "$json_file" | grep -o '"[^"]*":' | sed 's/"//g; s/://')

# Remove duplicate keys and exclude "mode"
unique_keys=$(echo "$keys" | grep -v "mode" | sort -u)

# Remove trailing spaces and closing parentheses from each key
cleaned_keys=$(echo "$unique_keys" | sed 's/[ \t)]*$//')

# Create a JSON file with each key and value "mode":"Simple"
output_file="users.json"
echo "{" > "$output_file"

# Loop through each cleaned key
echo "$cleaned_keys" | while IFS= read -r key; do
  echo "  \"$key\":{\"mode\":\"Simple\"}," >> "$output_file"
done

# Remove the trailing comma from the last line
sed -i '$s/,$//' "$output_file"

echo "}" >> "$output_file"

# Print the cleaned keys
echo "Created JSON file: $output_file"

