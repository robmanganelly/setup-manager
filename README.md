# Setup Manager

## Little Introduction

This project came to light mainly because of my laziness. I was tired of having to run the same commands over and over again, every time I needed to start working on a project. So I decided to create a tool that would do it for me.
It would be much easier to just create a bash script, I know, but why not make it a little more interesting?

So, here it is, **the Setup Manager**.

## What is it?

Basically is a _bash script_, so it's ideally intended for MacOS and Linux users, but there might be a few workarounds for making it work. I append [here](#can-i-run-it-on-windows) the answer gotten from Chat GPT after asking if I could execute a bash script on Windows, just check the end of this file. Feel free to collaborate and PR a Windows version of this script.

### Running the Script

- The script can take an optional `-f` argument, that will indicate the path to a file containing the commands you want to execute, or the current directory if omitted.

- The file must be a **YAML** file, and **providing the name of the file and the extension is required**.

- You can also provide a `-p` argument, that will indicate the parser you want to use to parse the file.
  If you don't provide a parser, the script will use the default one, which is the `node` parser. I chose **node** because I always have node installed on my computer,

So far, there are (_or there will be soon_) parser files created for the following languages:

- Python
- Javascript (Node)
- Go

If you want to create a parser for another language, feel free to do it and PR it, I will be happy to add it to the project.

> Don't forget to give **execution permissions** to the script before running it, you can do it with the following command in the same directory where you have your script.
>
> ```bash
> chmod +x exec-setup.sh
> ```

Once you have the script ready, you can run it with the following command:

```bash
./exec-setup.sh -f <path-to-file> -p [parser] file.yaml
```

## How does it work?

The script checks for the provided files and arguments, and will parse the file with the indicated parser.
If everything is ok, it will start executing the commands in the file. the file must be a **YAML** file, and it must have the following structure:

### YAML file structure

I provided a structure based on my needs, that can be enhanced via PRs, but for now, this is the structure of the file:

```yaml
---
# use this option if you intend to use docker or docker-compose
container:
  # command can be either 'docker' or 'compose'
  command: "docker"
  # this is a list of previously existent containers, if command is compose will be ignored
  docker-name:
    - mariadb-box
  # this is the absolute path to docker compose file, if command is docker will be ignored
  compose-path: "/usr/path/to/docker-compose.yml"

# will point to the working dir where files are, it is an absolute path
workdir: "/absolute/path/to/workdir"

# this section opens a new browser window with the specified tabs
browser:
  command: "google-chrome"
  tabs:
    - "htp://localhost:4200"
    - "htp://localhost:1337/admin"

terminal:
  command: "konsole"
  tabs:
    - command: "pnpm develop:api"
      dir: "." # this will be the default value, if does not appear should be taken as same as path,
    - command: "pnpm develop:portal"
      dir: "./client" # it indicates to run command in path/client
    - command: "htop"

editor:
  command: "code"
  #this field is optional, if present will attach the workspace to the editor command
  workspace: "path/some.code-workspace"

# this is a list of extra commands to run
extras:
  - command: 'echo "hello world"'
    dir: "."
---
```

**Notes**.

- `container.command`: future versions might implement the 'dockerfile' option, but for now, I think it's not necessary, and adds undesired complexity to the script.
- `container.docker-name`: this is a list of previously existent containers, if command is `compose` will be ignored, and if command is `docker`, it will be used to check if the container is already running, and if not, it will be started. Containers must be previously created, and the script will not check if the container exists, so make sure you have it before running the script.
- `container.compose-path`: this is the absolute path to docker compose file, if command is `docker` will be ignored, and if command is `compose`, it will execute the docker-compose file. The script will not check if the file exists, so make sure you have it before running the script. Docker must be previously installed and running.
- `workdir`: this is the absolute path to the working directory, it will be used to run the commands in the `terminal` section, and to open the `editor` workspace.
- `browser`: this section will open a new browser window with the specified tabs. The `command` field is the command to open the browser, and the `tabs` field is a list of tabs to open. The script will not check if the command is valid.
- `terminal`: this section will open a new terminal window with the specified tabs. The `command` field is the command to open the terminal, and the `tabs` field is a list of tabs to open. The script will not check if the command is valid.
  - The `command` field in the tabs is the command to run in every tab opened in the terminal
  - the `dir` field is the _relative_ path to the directory where the tab will be opened and command will be executed. If the `dir` field is not present, it will be taken as the same as the `workdir` field.
- `editor`: this section will open a new editor window with the specified workspace. The `command` field is the command to open the editor, and the `workspace` field is the path to the workspace to open. The script will not check if the command is valid.
- `extras`: this section will run a list of extra commands. The `command` field is the command to run, and the `dir` field is the _relative_ path to the directory where the command will be executed. If the `dir` field is not present, it will be taken as the same as the `workdir` field.

#### Standard

It is very good idea to keep a standardized structure for the files, so it is easier to read and understand them. I recommend the above structure, but changes might be implemented in future versions. If so, this section will be updated.
Tentatively, the version might be stored in a `version` field.

## FAQ

### Create a new parser

If you want to create a new parser, you can do it by creating a new file in the `execs` folder, with the name `exec` and the extension of the language you want to add support for,
the parser is just a function that receives the `yaml` file with commands. and returns a pound (`#`) separated string with the commands to run. I decided to use the pound sign as IFS to parse the string into a Bash array, avoiding install extra packages. The script will take care of parsing the array.

- `parsed_yaml_errors`: index `0`: a string, containing the errors found in the yaml file, if any. if multiple I would recommend just to return the first one. and if none, return an empty string.
- `containers_command`: index `1`: a string containing the option to run the containers, it can be `docker` or `compose`
- `containers_docker_name`: index `2` a string containing one or more containers to restart, if more than one, they should be separated by a space
- `containers_compose_path`: index `3` a string containing the path to the docker-compose file
- `workdir`: index `4` a string containing the path to the working directory
- `browser_command`: index `5` a string containing the command to open the browser
- `browser_tabs`: index `6` an array of strings containing the tabs to open in the browser, if multiple, they should be separated by a space, provide the full url
- `terminal_command`: index `7` a string containing the command to open the terminal
- `terminal_tabs`: index `8` a composed string, containing the tabs to be opened in the terminal
- `editor_command`: index `9` a string containing the command to open the editor
- `editor_workspace`: index `10` a string containing the path to the workspace to open
- `extras`: index `11`, a comma separated string containing the commands to run in the extras section, this string will be split by the comma, and each command will be executed in the background.

:warning: this array will only contain strings so, if an option is not preset, make sure to return an empty string.

### Can I run it on Windows?

This is a copy of the answer provided by Chat GPT after asking if I could run a bash script on Windows, I haven't tested any of this so I can't guarantee it will work, but I'm sure Chat GPT will be happy to help you if you have any problems

Yes, you can run Bash scripts on Windows using one of the following methods:

1. **Windows Subsystem for Linux (WSL)**: WSL is a compatibility layer developed by Microsoft that allows you to run a full-fledged Linux environment on Windows without the need for a virtual machine. You can install WSL on Windows 10 or Windows Server, and then choose a Linux distribution (such as Ubuntu, Debian, or Fedora) from the Microsoft Store. Once installed, you can use the Linux terminal to run Bash scripts just like you would on a native Linux system. This is the recommended method for running Bash scripts on Windows, as it provides the most complete and seamless Linux experience.

   To install WSL, you can follow Microsoft's official guide: [Install WSL](https://docs.microsoft.com/en-us/windows/wsl/install)

2. **Git Bash**: Git Bash is a Bash emulation environment that comes with Git for Windows. It provides a limited set of Unix tools and allows you to run simple Bash scripts. However, it is not as comprehensive as WSL and may not be suitable for complex scripts that require a complete Linux environment.

   To use Git Bash, download and install Git for Windows from the official website: [Git for Windows](https://gitforwindows.org/)

3. **Cygwin**: Cygwin is a software package that provides a large collection of GNU and Open Source tools which provide functionality similar to a Linux distribution on Windows. Cygwin can be used to run Bash scripts, but the setup process is more involved compared to WSL or Git Bash. Additionally, it may not provide as seamless an experience as WSL.

   To install Cygwin, you can follow the instructions on the official website: [Cygwin](https://www.cygwin.com/)

These methods allow you to run Bash scripts on Windows, but keep in mind that certain scripts might still require modifications, especially if they rely on Linux-specific features or tools not available in the chosen environment.
