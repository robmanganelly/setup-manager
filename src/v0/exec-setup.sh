#!/bin/bash

# do this chmod +x exec-setup
# chmod +x exec-setup

# Function to run the algorithm
executor() {
    # Read input YAML file
    local input_yaml="$1"
    local parser="$2"

    # Check if the file is empty
    if [ ! -s "$input_yaml" ]; then
        echo "Error: File is empty: $input_yaml"
        exit 1
    fi

    local parser_context=""
    local context_executable=""

    # switch case for parser (python| node| go)
    case $parser in
    python)
        parser_context="python3 "
        context_executable="exec.py"
        ;;
    node)
        parser_context="node "
        context_executable="exec.js"
        ;;
    go)
        parser_context="go build "
        context_executable="exec.go"
        ;;
    *)
        echo "Error: Parser not supported: $parser"
        exit 1
        ;;
    esac

    # Parse input yaml using parser executable, it will always return an array
    local parsed_yaml=($($parser_context $context_executable "$input_yaml"))

    # get variables from parsed yaml
    # local parsed_yaml_length=${#parsed_yaml[@]}
    local parsed_yaml_errors=${parsed_yaml[0]}
    local containers_command=${parsed_yaml[1]}
    local containers_docker_name=${parsed_yaml[2]}
    local containers_compose_path=${parsed_yaml[3]}
    local workdir=${parsed_yaml[4]}
    local browser_command=${parsed_yaml[5]}
    local browser_tabs=${parsed_yaml[6]}
    local terminal_command=${parsed_yaml[7]}
    local terminal_tabs=${parsed_yaml[8]}
    local editor_command=${parsed_yaml[9]}
    local editor_workspace=${parsed_yaml[10]}
    local extras=${parsed_yaml[11]}

    local e_details=""
    local e_cases=0

    # check if there is errors
    if [ -n "$parsed_yaml_errors"]; then
        echo "Error: Bad syntax: $parsed_yaml_errors"
        exit 1
    fi

    # Containers
    if [ -n "$containers_command" ]; then
        if [ "$containers_command" == "docker" ]; then
            docker restart "$containers_docker_name"

        elif [ "$containers_command" == "compose" ]; then
            docker-compose -f "$containers_compose_path" up -d
            
        else
            echo "Bad Syntax: unrecognized option $containers_command"
            exit 1
        fi
    fi

    # Terminal
    if [ -n "$terminal_command" ]; then
        if [ "$terminal_command" == "konsole" ]; then
            konsole "$terminal_tabs"
        else
            echo "Bad Syntax: not implemented with option $terminal_command"
            exit 1
        fi
    fi

    # Browser
    if [ -n "$browser_command" ]; then
        "$browser_command" $browser_tabs 
    fi

    # Editor
    if [ -n "$editor_command" ]; then
        "$editor_command" $editor_workspace     
    fi

    # Extras
    if [ -n "$extras" ]; then
        # Set the IFS (Internal Field Separator) to a comma
        IFS=','

        # Use the 'read' command with the '-a' option to create an array from the string
        read -a my_array <<< "$extras"

        # Restore the IFS to its original value
        unset IFS

        # Print the elements of the array
        for element in "${my_array[@]}"; do
            $element &
        done

    fi

    echo "Setup finished"
}

# setup init

# Function to log error message
e_log() {
    echo "Usage: exec-setup [-f path/to/directory] [-p parser] filename.yaml"
    echo "Options:"
    echo "-f \tPath to the directory containing the YAML file"
    echo "parser: node, python, go"
}

# Set default path to the current directory
yaml_directory="."
yaml_filename=""
parser="node"

# Parse command-line arguments
while getopts "f:p:" option; do
    case $option in
    f)
        yaml_directory="$OPTARG"
        ;;
    p)
        parser="$OPTARG"
        ;;
    *)
        e_log
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

# Get the filename from remaining arguments
if [ "$#" -eq 1 ]; then
    yaml_filename="$1"
else
    e_log
    echo "Error: Filename is required"
    exit 1
fi

# Combine the path and filename
yaml_path="$yaml_directory/$yaml_filename"

# Check if the file exists
if [ ! -f "$yaml_path" ]; then
    echo "Error: File not found: $yaml_path"
    exit 1
fi

# Call the executor function
executor "$parser" "$yaml_path"