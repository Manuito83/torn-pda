// > All scripts always get GM.info even without specifically requesting it.
// per https://wiki.greasespot.net/@grant
let GM = {
    info: {
        // https://wiki.greasespot.net/GM.info
        scriptHandler: 'TornPDA',
        scriptMetaStr: '',
        scriptWillUpdate: false,
        version: '0.0.0',
        script: {
            name: 'Default Script',
            namespace: 'default',
            description: 'A default userscript.',
            excludes: [],
            includes: [],
            matches: [],
            resources: {},
            'run-at': "document-start",
            version: '0.0.0'
        }
    }
};
