// #!/usr/bin/env node //unused

//TODO optimize code
//     change var names
//     use js specific syntax

const fs = require("fs");
const yaml = require("js-yaml");

function _parse(data) {
  let twelvePosArray = Array(12).fill(null);

  // test for errors
  if ("container" in data && data["container"] == null) {
    twelvePosArray[0] = "SyntaxError: wrong container option";
    return twelvePosArray;
  }
  if ("container" in data && data["container"] != null) {
    if (!("command" in data["container"])) {
      twelvePosArray[0] = "Error: no command provided";
      return twelvePosArray;
    }

    if (
      !(
        data["container"]["command"] == "docker" ||
        data["container"]["command"] == "compose"
      )
    ) {
      twelvePosArray[0] = `Error: option ${data["container"]["command"]} not supported`;
      return twelvePosArray;
    }
    if (
      data["container"]["command"] == "docker" &&
      (!data["container"]["docker-name"] ||
        data["container"]["docker-name"].length < 1)
    ) {
      twelvePosArray[0] =
        "Error: Container name is required for command docker";
      return twelvePosArray;
    }
    if (
      data["container"]["command"] == "compose" &&
      !data["container"]["compose-path"]
    ) {
      twelvePosArray[0] = "Error: Compose name is required for command compose";
      return twelvePosArray;
    }
  }
  if (!("workdir" in data)) {
    twelvePosArray[0] = "Error: no workdir provided";
    return twelvePosArray;
  }
  if ("browser" in data && data["browser"] == null) {
    twelvePosArray[0] = "SyntaxError: wrong browser option";
    return twelvePosArray;
  }
  if ("browser" in data && data["browser"] != null) {
    if (!data["browser"]["command"]) {
      twelvePosArray[0] = "Error: no browser command provided";
      return twelvePosArray;
    }
  }
  if ("terminal" in data && data["terminal"] == null) {
    twelvePosArray[0] = "SyntaxError: wrong terminal option";
    return twelvePosArray;
  }
  if ("terminal" in data && data["terminal"] != null) {
    if (!data["terminal"]["command"]) {
      twelvePosArray[0] = "Error: no terminal command provided";
      return twelvePosArray;
    }
  }
  if ("editor" in data && data["editor"] == null) {
    twelvePosArray[0] = "SyntaxError: wrong editor option";
    return twelvePosArray;
  }
  if ("editor" in data && data["editor"] != null) {
    if (!data["editor"]["command"]) {
      twelvePosArray[0] = "Error: no editor command provided";
      return twelvePosArray;
    }
  }
  if ("extras" in data && data["extras"] == null) {
    twelvePosArray[0] = "SyntaxError: wrong extras option";
    return twelvePosArray;
  }
  if ("extras" in data && data["extras"] != null) {
    if (!Array.isArray(data["extras"])) {
      twelvePosArray[0] = "SyntaxError: extras must be an array";
      return twelvePosArray;
    }
    if (data["extras"].length < 1) {
      twelvePosArray[0] = "Error: extras array must have at least one element";
      return twelvePosArray;
    }
    let i = -1;
    for (let extra of data["extras"]) {
      i += 1;
      if (!extra["command"]) {
        twelvePosArray[0] = `Error: no command provided at extras: index ${i} `;
        return twelvePosArray;
      }
    }
  }

  //parse container
  if ("container" in data) {
    twelvePosArray[1] = data["container"]["command"];
    if (data["container"]["command"]) {
      twelvePosArray[2] = data["container"]["docker-name"]
        ? data["container"]["docker-name"].join(" ")
        : null;
      twelvePosArray[3] = null;
    } else {
      twelvePosArray[2] = null;
      twelvePosArray[3] = data["container"]["compose-path"];
    }
  }
  //parse workdir
  twelvePosArray[4] = data["workdir"];
  const work_dir = data["workdir"];

  //parse browser
  if ("browser" in data) {
    twelvePosArray[5] = data["browser"]["command"];
    if ("tabs" in data["browser"]) {
      twelvePosArray[6] = data["browser"]["tabs"].join(" ");
    }
  }

  //parse terminal
  if ("terminal" in data) {
    twelvePosArray[7] = data["terminal"]["command"];
    if (
      "tabs" in data["terminal"] &&
      data["terminal"]["command"] == "konsole"
    ) {
      let final_tabs = "";
      for (let index in data["terminal"]["tabs"]) {
        let tab = data["terminal"]["tabs"][index];
        let pathTo = !!tab["dir"] ? `${pathTo}/${tab["dir"].slice(2)}` : null;
        let tabCommand = tab["command"] || null;
        final_tabs += `title: ${
          tab["title"] || tab["command"] || `Tab ${index}`
        };; workdir:${pathTo};;`;
        final_tabs += `command: ${
          tabCommand ? `${tabCommand}` : "profile: Shell"
        }\t`;
      }
      twelvePosArray[8] = final_tabs;
    }
  }

  //parse editor
  if ("editor" in data) {
    twelvePosArray[9] = data["editor"]["command"];
    if ("tabs" in data["editor"]) {
      twelvePosArray[10] = data["editor"]["workspace"] ?? null;
    }
  }

  //parse extras
  if ("extras" in data) {
    let final_extras = "";
    for (let extra of data["extras"]) {
      let pathTo = !!extra["dir"]
        ? `${work_dir}/${extra["dir"].slice(2)}`
        : null;
      final_extras += `${!!extra["dir"] ? `cd ${pathTo}; ` : ""}${
        extra["command"]
      }; `;
    }
    twelvePosArray[11] = final_extras;
  }

  return twelvePosArray;
}

function exec(path) {
  try {
    const content = fs.readFileSync(path, "utf8");
    const data = yaml.load(content);

    return _parse(data);
  } catch (error) {
    if (error.code === "ENOENT") {
      console.error("Error: file not found");
    } else {
      console.error(error);
    }
    return;
  }
}

if (process.argv.length < 3) {
  console.error("Error: no path provided");
  process.exit(1);
}

console.log(exec(process.argv[2]).map(i=>i??null).map(String).join("ó"));
