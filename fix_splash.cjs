const fs = require('fs');
const file = 'react-native-app/src/screens/SplashScreen.tsx';
let content = fs.readFileSync(file, 'utf8');

// fix style string error in Alert
content = content.replace("style: 'default',", "");

fs.writeFileSync(file, content);
