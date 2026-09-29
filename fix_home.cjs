const fs = require('fs');
let file = 'react-native-app/src/screens/HomeScreen.tsx';
let content = fs.readFileSync(file, 'utf8');
content = content.replace('ProductFeedSkeletonList,', '');
fs.writeFileSync(file, content);
