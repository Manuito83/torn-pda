# TORN PDA - Userscripts

Here you will find a list of tested userscripts working in Torn PDA as well as the Javascript API.

## Preexisting Userscripts
Preexisting scripts (for other tools, such as GreaseMonkey) normally require some changes in order to work with the app, as there might be missing libraries or different code loading times that are not directly compatible. We would appreciate if you let us know about any other scripts you are using in Torn PDA, so that we can add them to the list. Also, we can probably support you in making older scripts to work with Torn PDA.

## Javascript API
Torn PDA's JavaScript API provides access to the user's API key and enables cross-origin http requests. 

To access the API key, define a string constant(s), "_###PDA-APIKEY###_" in the script source. It will be replaced at runtime with the user's api key. 

Additionally, functions PDA_httpGet() and PDA_httpPost() are provided. For more information on those, see [TornPDA_API.js](TornPDA_API.js)

## Contact Us
For discussion and support with scripting, please join our Discord server!

[![Discord](https://img.shields.io/discord/715785867519721534?style=for-the-badge&color=%23447e9b&label=Discord&logo=discord&logoColor=FFF)](https://discord.gg/vyP23kJ)
