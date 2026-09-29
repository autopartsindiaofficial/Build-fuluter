const fs = require('fs');

// Fix AppNavigator
let file = 'react-native-app/src/navigation/AppNavigator.tsx';
let content = fs.readFileSync(file, 'utf8');
content = content.replace(/chatSounds\.playReceive\(\);/g, '');
fs.writeFileSync(file, content);

