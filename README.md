# TestSuite

This emulates the basic ccTweaked functions missing in basic-lua.

- fs
- http
- vector-functions

Additionally it emulates our **[scm](https://github.com/mc-cc-scripts/script-manager)** script and includes the **[json](https://gist.github.com/tylerneylon/59f4bcf316be525b30ab)** handler - which makes tests a lot easier.

# Usage

As this repo emulates many functionalites given by ccTweaked, you might want to test you code **outside** of Minecraft, maybe even automated. To achieve that, you need to download the scripts listed above and save them in your testingenv.

Ideally you want to add those scripts to your .gitignore and only add them locally / for github actions.

### Example

For how to import the scipts, an example is already used by this repo for some of its dependancies:

[fetch-deps.sh](fetch-deps.sh)