const fs = require('fs');
let file = 'react-native-app/src/screens/HomeScreen.tsx';
let content = fs.readFileSync(file, 'utf8');
content = content.replace("typeof auth.onAuthStateChanged === 'function'", "false");
fs.writeFileSync(file, content);
