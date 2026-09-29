const fs = require('fs');

// Fix LanguageSelectorModal
let file = 'react-native-app/src/components/LanguageSelectorModal.tsx';
let content = fs.readFileSync(file, 'utf8');
content = content.replace(/transparent\s*animationType="fade"\s*onRequestClose={onDismiss}/g, 'onClose={dismissModal}\n      height={380}');
fs.writeFileSync(file, content);

// Fix TypingIndicator
file = 'react-native-app/src/components/animations/TypingIndicator.tsx';
content = fs.readFileSync(file, 'utf8');
content = content.replace(/backgroundColor: dot1Color as any,/g, 'backgroundColor: dot1Color as unknown as string,');
content = content.replace(/backgroundColor: dot2Color as any,/g, 'backgroundColor: dot2Color as unknown as string,');
content = content.replace(/backgroundColor: dot3Color as any,/g, 'backgroundColor: dot3Color as unknown as string,');
fs.writeFileSync(file, content);

// Fix AppNavigator
file = 'react-native-app/src/navigation/AppNavigator.tsx';
content = fs.readFileSync(file, 'utf8');
content = content.replace(/ChatSoundEffects\.playReceive\(\);/g, '');
fs.writeFileSync(file, content);

// Fix ChatRoomScreen
file = 'react-native-app/src/screens/ChatRoomScreen.tsx';
content = fs.readFileSync(file, 'utf8');
content = content.replace(/item\.timestamp/g, 'item.createdAt');
fs.writeFileSync(file, content);

