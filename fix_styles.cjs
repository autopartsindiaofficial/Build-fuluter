const fs = require('fs');
const file = 'react-native-app/src/screens/SellPartScreen.tsx';
let content = fs.readFileSync(file, 'utf8');

const missingStyles = `
  sectionIconCircle: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#EFF6FF',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  counterTextRight: {
    fontSize: 12,
    color: '#94A3B8',
    textAlign: 'right',
    marginTop: 4,
  },
  sectionBadgeText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#3B82F6',
  },
`;

content = content.replace('const styles = StyleSheet.create({', 'const styles = StyleSheet.create({\n' + missingStyles);

// fix Icon style issues
content = content.replace(/<Icon\s+source="([^"]+)"\s+size=\{([0-9]+)\}\s+color="([^"]+)"\s+style=\{\{\s*marginRight:\s*([0-9]+)\s*\}\}\s*\/>/g, '<View style={{ marginRight: $4 }}><Icon source="$1" size={$2} color="$3" /></View>');

fs.writeFileSync(file, content);
