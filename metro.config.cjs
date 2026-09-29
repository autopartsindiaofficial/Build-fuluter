const path = require('path');
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const appDir = path.resolve(__dirname, 'react-native-app');
const rootDir = __dirname;
const defaultConfig = getDefaultConfig(appDir);

const config = {
  projectRoot: appDir,
  watchFolders: [
    rootDir,
    appDir,
    path.resolve(rootDir, 'node_modules'),
  ],
  resolver: {
    nodeModulesPaths: [
      path.resolve(appDir, 'node_modules'),
      path.resolve(rootDir, 'node_modules'),
    ],
    unstable_enablePackageExports: false,
  },
};

module.exports = mergeConfig(defaultConfig, config);
