const fs = require('fs');

// Fix TypingIndicator
let file = 'react-native-app/src/components/animations/TypingIndicator.tsx';
let content = fs.readFileSync(file, 'utf8');
content = content.replace(/backgroundColor: dotColor,/g, 'backgroundColor: dotColor as any,');
fs.writeFileSync(file, content);

// Fix AppNavigator
file = 'react-native-app/src/navigation/AppNavigator.tsx';
content = fs.readFileSync(file, 'utf8');
content = content.replace(/ChatSoundEffects\.playReceive\(\);/g, '');
fs.writeFileSync(file, content);

