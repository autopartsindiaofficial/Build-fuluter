const fs = require('fs');
const file = 'react-native-app/src/screens/SellPartScreen.tsx';
let content = fs.readFileSync(file, 'utf8');

const hookInsert = `
  // Prevent going back if not on step 1
  useEffect(() => {
    const unsubscribe = navigation.addListener('beforeRemove', (e: any) => {
      // If we are not on Step 1, prevent the default back action and instead go to the previous step.
      if (currentStep > 1 && e.data.action.type === 'GO_BACK') {
        e.preventDefault();
        setCurrentStep((prev) => (prev - 1) as 1 | 2 | 3);
      }
    });
    return unsubscribe;
  }, [navigation, currentStep]);
`;

content = content.replace('const [currentStep, setCurrentStep] = useState<1 | 2 | 3>(1);', 'const [currentStep, setCurrentStep] = useState<1 | 2 | 3>(1);\n' + hookInsert);
fs.writeFileSync(file, content);
