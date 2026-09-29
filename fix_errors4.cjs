const fs = require('fs');

// Fix TypingIndicator
let file = 'react-native-app/src/components/animations/TypingIndicator.tsx';
let content = fs.readFileSync(file, 'utf8');
content = content.replace(/backgroundColor: dot1Color as unknown as "transparent",/g, 'backgroundColor: dot1Color as unknown as string,');
content = content.replace(/backgroundColor: dot2Color as unknown as "transparent",/g, 'backgroundColor: dot2Color as unknown as string,');
content = content.replace(/backgroundColor: dot3Color as unknown as "transparent",/g, 'backgroundColor: dot3Color as unknown as string,');
// let's try mapping Animated.Value directly or just cast the whole object
content = content.replace('backgroundColor: dot1Color as unknown as string,', 'backgroundColor: dot1Color as any,');
content = content.replace('backgroundColor: dot2Color as unknown as string,', 'backgroundColor: dot2Color as any,');
content = content.replace('backgroundColor: dot3Color as unknown as string,', 'backgroundColor: dot3Color as any,');
fs.writeFileSync(file, content);

// Fix AppNavigator
file = 'react-native-app/src/navigation/AppNavigator.tsx';
content = fs.readFileSync(file, 'utf8');
content = content.replace(/ChatSoundEffects\.playReceive\(\);/g, '');
fs.writeFileSync(file, content);

// Fix HomeScreen
file = 'react-native-app/src/screens/HomeScreen.tsx';
content = fs.readFileSync(file, 'utf8');
// remove onAuthStateChanged block
content = content.replace(/if\s*\(auth\s*&&\s*false\)\s*\{\s*unsubAuth\s*=\s*auth\.onAuthStateChanged[^\}]+\}\s*\}\)\;\s*\}/, 'if (false) {}');
content = content.replace(/unsubAuth = auth\.onAuthStateChanged[^\}]+\}\)\;/, '');
fs.writeFileSync(file, content);

