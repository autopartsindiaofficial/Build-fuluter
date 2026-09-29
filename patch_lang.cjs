const fs = require('fs');
const file = 'react-native-app/src/components/LanguageSelectorModal.tsx';
let content = fs.readFileSync(file, 'utf8');

content = content.replace("import { View, StyleSheet, Modal, TouchableOpacity } from 'react-native';", "import { View, StyleSheet, TouchableOpacity } from 'react-native';\nimport { BottomSheetModal } from './BottomSheetModal';");

const oldReturn = `  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onDismiss}
    >
      <TouchableOpacity
        style={styles.backdrop}
        activeOpacity={1}
        onPress={onDismiss}
      >
        <Surface style={styles.modalContent} elevation={5}>
          {/* Header */}
          <View style={styles.header}>
            <View style={styles.headerTitleRow}>
              <IconButton icon="translate" size={22} iconColor="#0066FF" style={{ margin: 0 }} />
              <Text style={styles.title}>{t('selectLanguage')}</Text>
            </View>
            <IconButton icon="close" size={20} iconColor="#64748B" onPress={onDismiss} />
          </View>
          {/* Options */}
          <View style={styles.optionsList}>
            {LANGUAGES.map((item) => {
              const isSelected = language === item.code;
              return (
                <TouchableOpacity
                  key={item.code}
                  style={[
                    styles.langOption,
                    isSelected && styles.langOptionSelected,
                  ]}
                  onPress={() => handleSelect(item.code)}
                  activeOpacity={0.7}
                >
                  <View style={styles.optionLeft}>
                    <Text style={styles.flagIcon}>{item.flag}</Text>
                    <View>
                      <Text
                        style={[
                          styles.nativeName,
                          isSelected && styles.nativeNameSelected,
                        ]}
                      >
                        {item.nativeName}
                      </Text>
                      <Text style={styles.langName}>{item.name}</Text>
                    </View>
                  </View>
                  <View
                    style={[
                      styles.radioCircle,
                      isSelected && styles.radioCircleSelected,
                    ]}
                  >
                    {isSelected && <View style={styles.radioInner} />}
                  </View>
                </TouchableOpacity>
              );
            })}
          </View>
        </Surface>
      </TouchableOpacity>
    </Modal>
  );`;

const newReturn = `  return (
    <BottomSheetModal
      visible={visible}
      onClose={dismissModal}
      height={380}
    >
      <View style={styles.modalContent}>
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerTitleRow}>
            <IconButton icon="translate" size={22} iconColor="#0066FF" style={{ margin: 0 }} />
            <Text style={styles.title}>{t('selectLanguage')}</Text>
          </View>
          <IconButton icon="close" size={20} iconColor="#64748B" onPress={dismissModal} />
        </View>
        {/* Options */}
        <View style={styles.optionsList}>
          {LANGUAGES.map((item) => {
            const isSelected = language === item.code;
            return (
              <TouchableOpacity
                key={item.code}
                style={[
                  styles.langOption,
                  isSelected && styles.langOptionSelected,
                ]}
                onPress={() => handleSelect(item.code)}
                activeOpacity={0.7}
              >
                <View style={styles.optionLeft}>
                  <Text style={styles.flagIcon}>{item.flag}</Text>
                  <View>
                    <Text
                      style={[
                        styles.nativeName,
                        isSelected && styles.nativeNameSelected,
                      ]}
                    >
                      {item.nativeName}
                    </Text>
                    <Text style={styles.langName}>{item.name}</Text>
                  </View>
                </View>
                <View
                  style={[
                    styles.radioCircle,
                    isSelected && styles.radioCircleSelected,
                  ]}
                >
                  {isSelected && <View style={styles.radioInner} />}
                </View>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>
    </BottomSheetModal>
  );`;

content = content.replace(oldReturn, newReturn);
fs.writeFileSync(file, content);
