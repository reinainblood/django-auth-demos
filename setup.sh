#!/bin/bash

# Debug information
echo "Current directory: $(pwd)"
echo "Files in current directory:"
ls -la

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install Django first
pip install django

# Initialize Django project
echo "Initializing Django project..."
django-admin startproject minimal_auth .
python manage.py startapp auth_app

# Function to create directories recursively
create_parent_dirs() {
    local filepath="$1"
    local dirpath=$(dirname "$filepath")
    mkdir -p "$dirpath"
}

# Function to handle file move commands from comments
handle_file_move() {
    local line="$1"
    if [[ $line =~ ^#[[:space:]]Save[[:space:]]+([^[:space:]]+)[[:space:]]+as[[:space:]]+(.+)$ ]]; then
        local source_file="${BASH_REMATCH[1]}"
        local dest_path="${BASH_REMATCH[2]}"

        if [ -f "$source_file" ]; then
            create_parent_dirs "$dest_path"
            cp "$source_file" "$dest_path"
            echo "Moved $source_file to $dest_path"
        else
            echo "Warning: Source file $source_file not found"
        fi
    fi
}

# Initialize variables
current_file=""
file_content=""

# Verify input file exists
if [ ! -f "claude_output.txt" ]; then
    echo "Error: claude_output.txt not found in current directory"
    exit 1
fi

# Read the input file line by line
while IFS= read -r line; do
    # Check for file move commands
    if [[ $line =~ ^#[[:space:]]Save ]]; then
        handle_file_move "$line"
        continue
    fi

    # If line starts with # and isn't a move command
    if [[ $line =~ ^#[[:space:]]([^#].*)$ ]]; then
        # If we have a file to write from previous iteration
        if [ ! -z "$current_file" ] && [ ! -z "$file_content" ]; then
            create_parent_dirs "$current_file"
            echo -e "$file_content" > "$current_file"
            echo "Created file: $current_file"
        fi

        # Get new filename from the line after removing the # and space
        current_file=$(echo "$line" | sed 's/^# //')
        file_content=""
    else
        # Append line to current file content
        if [ ! -z "$current_file" ]; then
            if [ -z "$file_content" ]; then
                file_content="$line"
            else
                file_content="$file_content\n$line"
            fi
        fi
    fi
done < "claude_output.txt"

# Write the last file
if [ ! -z "$current_file" ] && [ ! -z "$file_content" ]; then
    create_parent_dirs "$current_file"
    echo -e "$file_content" > "$current_file"
    echo "Created file: $current_file"
fi

# Install requirements if requirements.txt was created
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    echo "Installed requirements"
fi

# Run Django migrations and create admin user if manage.py exists
if [ -f "manage.py" ]; then
    python manage.py migrate
    python manage.py create_admin
    echo "Ran migrations and created admin user"
fi

echo "Project setup complete!"
echo "Run 'python manage.py runserver' to start the development server"