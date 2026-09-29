const fs = require('fs');
const file = 'react-native-app/src/screens/SellPartScreen.tsx';
let content = fs.readFileSync(file, 'utf8');

content = content.replace('ActivityIndicator,\n  FlatList,', 'ActivityIndicator,\n  FlatList,\n  LayoutAnimation,\n  UIManager,');

const next1 = `
  const handleNextStep1 = () => {
`;
const next1Repl = `
  const handleNextStep1 = () => {
`;

const next2 = `
  const handleNextStep2 = () => {
`;

// wait, the best place to configure LayoutAnimation is right before setCurrentStep
content = content.replace(/setCurrentStep\(2\);/g, 'LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);\n    setCurrentStep(2);');
content = content.replace(/setCurrentStep\(3\);/g, 'LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);\n    setCurrentStep(3);');
content = content.replace(/setCurrentStep\(\(prev\) => \(prev - 1\) as 1 \| 2 \| 3\);/g, 'LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);\n        setCurrentStep((prev) => (prev - 1) as 1 | 2 | 3);');
content = content.replace(/setCurrentStep\(1\);/g, 'LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);\n        setCurrentStep(1);');

// enable layout animation for android
const hookInsert = `
  useEffect(() => {
    if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
      UIManager.setLayoutAnimationEnabledExperimental(true);
    }
  }, []);
`;
content = content.replace('// Prevent going back if not on step 1', hookInsert + '\n  // Prevent going back if not on step 1');

fs.writeFileSync(file, content);
