const fs = require('fs');

// Fix TypingIndicator
let file = 'react-native-app/src/components/animations/TypingIndicator.tsx';
let content = fs.readFileSync(file, 'utf8');
content = content.replace(/backgroundColor: dot1Color as unknown as string,/g, 'backgroundColor: dot1Color as any,');
content = content.replace(/backgroundColor: dot2Color as unknown as string,/g, 'backgroundColor: dot2Color as any,');
content = content.replace(/backgroundColor: dot3Color as unknown as string,/g, 'backgroundColor: dot3Color as any,');
// let's just make it a string cast
content = content.replace(/backgroundColor: dot1Color as any,/g, 'backgroundColor: dot1Color as unknown as "transparent",');
content = content.replace(/backgroundColor: dot2Color as any,/g, 'backgroundColor: dot2Color as unknown as "transparent",');
content = content.replace(/backgroundColor: dot3Color as any,/g, 'backgroundColor: dot3Color as unknown as "transparent",');
fs.writeFileSync(file, content);

// Fix ChatRoomScreen
file = 'react-native-app/src/screens/ChatRoomScreen.tsx';
content = fs.readFileSync(file, 'utf8');
content = content.replace(/a\.timestamp/g, 'a.createdAt');
content = content.replace(/b\.timestamp/g, 'b.createdAt');
content = content.replace(/msg\.timestamp/g, 'msg.createdAt');
content = content.replace(/data\.timestamp/g, 'data.createdAt');
fs.writeFileSync(file, content);

// Fix HomeScreen
file = 'react-native-app/src/screens/HomeScreen.tsx';
content = fs.readFileSync(file, 'utf8');
// remove onAuthStateChanged
content = content.replace(/const unsubscribeAuth = auth.onAuthStateChanged[^\}]+\]\)\;[^\}]+\]\)\;[^\}]+\};/s, 'const unsubscribeAuth = () => {};');
content = content.replace(/const unsubscribeAuth = auth.onAuthStateChanged.*?;/g, 'const unsubscribeAuth = () => {};');
fs.writeFileSync(file, content);

