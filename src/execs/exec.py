#!/usr/bin/python3

import sys
import yaml
# import json


def _parse(data):

    twelve_pos_array = [None, None, None, None, None, None, None, None, None, None, None, None ]

    # test for errors
    if 'container' in data and data['container'] is None:
        twelve_pos_array[0] = "SyntaxError: wrong container option"
        return twelve_pos_array
    if 'container' in data and data['container'] is not None:
        if 'command' not in data['container']:
            twelve_pos_array[0] = "Error: no command provided"
            return twelve_pos_array

        if not (data['container']['command'] == "docker" or data['container']['command'] == "compose"):
            twelve_pos_array[0] = f"Error: option {data['container']['command']} not supported"
            return twelve_pos_array
        if data['container']['command'] == "docker" and not data['container']['docker-name'] or len(data['container']['docker-name']) < 1:
            twelve_pos_array[0] = "Error: Container name is required for command docker"
            return twelve_pos_array
        if data['container']['command'] == "compose" and not data['container']['compose-path']:
            twelve_pos_array[0] = "Error: Compose name is required for command compose"
            return twelve_pos_array
    if not 'workdir' in data:
        twelve_pos_array[0] = "Error: no workdir provided"
        return twelve_pos_array
    if 'browser' in data and data['browser'] is None:
        twelve_pos_array[0] = "SyntaxError: wrong browser option"
        return twelve_pos_array
    if 'browser' in data and data['browser'] is not None:
        if not data['browser']['command']:
            twelve_pos_array[0] = "Error: no browser command provided"
            return twelve_pos_array
    if 'terminal' in data and data['terminal'] is None:
        twelve_pos_array[0] = "SyntaxError: wrong terminal option"
        return twelve_pos_array
    if 'terminal' in data and data['terminal'] is not None:
        if not data['terminal']['command']:
            twelve_pos_array[0] = "Error: no terminal command provided"
            return twelve_pos_array
    if 'editor' in data and data['editor'] is None:
        twelve_pos_array[0] = "SyntaxError: wrong editor option"
        return twelve_pos_array
    if 'editor' in data and data['editor'] is not None:
        if not data['editor']['command']:
            twelve_pos_array[0] = "Error: no editor command provided"
            return twelve_pos_array
    if 'extras' in data:
        i = -1
        for extra in data['extras']:
            i += 1
            if not extra['command']:
                twelve_pos_array[0] = "Error: no command provided at extras: index {i} "
                return twelve_pos_array

    # parse container
    if 'container' in data:
        twelve_pos_array[1] = data['container']['command']
        if data['container']['command']:
            twelve_pos_array[2] = " ".join(data['container']['docker-name'])
            twelve_pos_array[3] = None
        else:
            twelve_pos_array[2] = None
            twelve_pos_array[3] = data['container']['compose-path']
    twelve_pos_array[4] = data['workdir']
    work_dir = data['workdir']
    if 'browser' in data:
        twelve_pos_array[5] = data['browser']['command']
        if 'tabs' in data['browser']:
            twelve_pos_array[6] = " ".join(
                tab for tab in data['browser']['tabs'])
    #parse terminal
    if 'terminal' in data:
        twelve_pos_array[7] = data['terminal']['command']
        if 'tabs' in data['terminal'] and data['terminal']['command'] == 'konsole':
            final_tabs = ""
            for index, tab in enumerate(data['terminal']['tabs']):
                work_dir = work_dir if not 'dir' in tab else f'{work_dir}/{tab.get("dir")[2:]}'
                keyword= 'command'
                title_key= 'title'
                command = tab.get("command") or None
                # final_tabs += f'#Tab {index}\n
                final_tabs += f'title: {tab.get(title_key) or tab.get(keyword) or f"Tab {index}"};; workdir:{work_dir};;'
                final_tabs += f"{keyword}: {f'{command}' if keyword in tab else 'profile: Shell' }\t"

            twelve_pos_array[8] = final_tabs
            # print(twelve_pos_array[8])
    
    # parse editor
    if 'editor' in data:
        twelve_pos_array[9] = data['editor']['command']
        twelve_pos_array[10] = None if not 'workspace' in data['editor'] else data['editor']['workspace']
    
    # parse extras
    if 'extras' in data:
        prop = 'dir'
        twelve_pos_array[11] = " , ".join([ f"{'' if not extra['dir'] else f'cd {work_dir}/{extra.get(prop)[2:]}; '}{extra['command']}" for extra in data['extras']])

    # print(eleven_pos_array)
    return twelve_pos_array



def exec(path):
    # open file in read mode
    try:
        file = open(path, "r")
        content = file.read()
        file.close()

        # parse yaml
        data = yaml.safe_load(content)

        return _parse(data)

    except FileNotFoundError:
        print("Error: file not found")
        return


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error: no path provided")
        exit(1)
    # print(exec(sys.argv[1]))
    print("ó".join(list(map(str, exec(sys.argv[1])))))


