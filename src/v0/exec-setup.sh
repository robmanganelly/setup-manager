#!/bin/bash

# do this chmod +x exec-setup
# chmod +x exec-setup


#function lazyrm removes a file after 10 seconds
lazyrm() {
    local file="$1"
    sleep 10
    rm "$file"
}



# Function to run the algorithm
executor() {
    # Read input YAML file
    local parser="$1"
    local input_yaml="$2"

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
        null_pointer="None"
        context_executable="./../execs/exec.py"
        ;;
    node)
        parser_context="node "
        null_pointer="null"
        context_executable="./../execs/exec.js"
        ;;
    go)
        parser_context="go build "
        null_pointer="nil"
        context_executable="./../execs/exec.go"
        ;;
    *)
        echo "Error: Parser not supported: $parser"
        exit 1
        ;;
    esac

    # Parse input yaml using parser executable, it will always return a string that must be converted to array
    local parsed_yaml="" 
    # Set the IFS (Internal Field Separator) to a comma
    IFS='ó'
    # Use the 'read' command with the '-a' option to create an array from the string
    # local raw_yaml=$(bash -c $parser_context $context_executable "$input_yaml")
    local raw_yaml=$(bash -c "$parser_context $context_executable $input_yaml")
    echo '$raw_yaml: ' $raw_yaml
    read -a parsed_yaml <<< $raw_yaml
    # Restore the IFS to its original value
    unset IFS

    echo length: ${#parsed_yaml[@]} #debug
    echo ${parsed_yaml} #debug

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

    # check if there is errors parsed_yaml_errors length != null pointer
    if [ "$parsed_yaml_errors" != "$null_pointer" ]; then    
        echo "SyntaxError: Bad syntax: $parsed_yaml_errors"
        exit 1
    fi


    # Containers
    if [ "$containers_command" != "$null_pointer" ]; then
        if [ "$containers_command" == "docker" ]; then
            
            echo " executing docker restart $containers_docker_name"

            docker restart "$containers_docker_name"

        elif [ "$containers_command" == "compose" ]; then
            
            echo " executing docker-compose -f $containers_compose_path up -d"

            docker-compose -f "$containers_compose_path" up -d
            
        else
            echo :debug $containers_command $parsed_yaml_errors $containers_docker_name $containers_compose_path
            echo "Error: Bad Syntax: unrecognized option $containers_command for containers"
            echo "Usage: containers: docker|compose"
            exit 1
        fi
    fi

    # Terminal
    if [ "$terminal_command" != "$null_pointer" ]; then
        if [ "$terminal_command" == "konsole" ]; then
            if [ "$terminal_tabs" != "$null_pointer" ]; then

                # Create a temporary file
                terminal_tab_file=$(mktemp -p "$workdir" temp.XXXXXX.konsole)

                # Write the string content to the temporary file
                # echo "$terminal_tabs" >> "$terminal_tab_file"
                echo "$terminal_tabs" | tr '\t' '\n' > "$terminal_tab_file"
                echo "terminal_tabs"
                echo "$terminal_tab_file"


                # Pass the temporary file to the konsole command
                echo launching konsole --tabs-from-file "$terminal_tab_file"

                konsole --tabs-from-file $terminal_tab_file & echo 'konsole launched'

                # Remove the temporary file
                lazyrm "$terminal_tab_file"

            else
                echo launching konsole
                konsole
            fi
            
        else
            echo "Bad Syntax: terminal not implemented with option $terminal_command"
            exit 1
        fi
    fi

    # Browser
    if [ "$browser_command" != "$null_pointer" ]; then
        echo launching browser: $browser_command $browser_tabs
        $browser_command $browser_tabs 
    fi

    # Editor
    if [ "$editor_command" != "$null_pointer" ]; then

        echo launching editor: $editor_command $editor_workspace
        if [ "$editor_workspace" != "$null_pointer" ]; then
            $editor_command $editor_workspace
        else
            $editor_command     
        fi 
    fi

    # Extras
    if [ "$extras" != "$null_pointer" ]; then
        # Set the IFS (Internal Field Separator) to a comma
        IFS=','

        # Use the 'read' command with the '-a' option to create an array from the string
        read -a my_array <<< "$extras"

        # Restore the IFS to its original value
        unset IFS

        # Print the elements of the array
        for element in "${my_array[@]}"; do
            echo executing extra: $element
            $element & echo done
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
        echo "yaml_directory: $yaml_directory"
        ;;
    p)
        parser="$OPTARG"
        echo "parser: $parser"
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
    echo "yaml_filename: $yaml_filename"
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
