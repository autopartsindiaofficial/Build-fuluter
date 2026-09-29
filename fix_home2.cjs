const fs = require('fs');
let file = 'react-native-app/src/screens/HomeScreen.tsx';
let content = fs.readFileSync(file, 'utf8');
content = content.replace('const auth = getFirebaseAuth();', 'const auth = { currentUser: null }; // getFirebaseAuth() removed as it does not exist');
fs.writeFileSync(file, content);
