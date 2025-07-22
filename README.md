# TestSuite

This emulates the basic ccTweaked functions missing in basic-lua.

- fs
- http
- vector-functions
- settings
  - (no validations what so ever as of yet)
- os.pullEvent etc.

Additionally it emulates our **[scm](https://github.com/mc-cc-scripts/script-manager)** script and includes the **[json](https://gist.github.com/tylerneylon/59f4bcf316be525b30ab)** handler - which makes tests a lot easier.

# Usage

As this repo emulates many functionalites given by ccTweaked, you might want to test you code **outside** of Minecraft, maybe even automated. To achieve that, you need to download the scripts listed above and save them in your testingenv.

Ideally you want to add those scripts to your .gitignore and only add them locally / for github actions.

### How to use those functions

```lua
-- IN YOUR TEST_SPEC:

package.path = "pathToTestSuite-lib_Folder/?.lua;" .. package.path
-- adds all libs to your path, so they are available without specifying their path each time

_G.fs = require("fs")
_G.vector = require("vector")
-- ...
-- _G holds all global variables, so it may be used by your other scripts

local scriptToTest = require("scriptToTest")
-- this script can now access the fs- & vector-functions
-- without any need to modify the script you want to test
```

#### os
[how to test with os functions](docs/ccOS.md)


### How to import these scripts

For how to import the scipts, an example is already used by this repo for some of ITS dependancies (which you will also need):

[fetch-deps.sh](fetch-deps.sh)