import React, { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { translations, Language, translateDynamic as td } from '../data/translations';

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => Promise<void>;
  t: (key: keyof typeof translations['en']) => string;
  translateDynamic: (text: string) => string;
}

const STORAGE_KEY = '@autoparts_language';

const defaultContext: LanguageContextType = {
  language: 'en',
  setLanguage: async () => {},
  t: (key: any) => {
    try {
      const langDict = translations['en'];
      return (langDict as any)[key] || String(key);
    } catch (_) {
      return String(key);
    }
  },
  translateDynamic: (text: string) => {
    if (!text) return '';
    try {
      return td(text, 'en');
    } catch (_) {
      return String(text);
    }
  },
};

const LanguageContext = createContext<LanguageContextType>(defaultContext);

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [language, setLanguageState] = useState<Language>('en');

  useEffect(() => {
    const loadSavedLanguage = async () => {
      try {
        const saved = await AsyncStorage.getItem(STORAGE_KEY);
        if (saved && (saved === 'en' || saved === 'ta' || saved === 'hi')) {
          setLanguageState(saved as Language);
        }
      } catch (err) {
        console.warn('[LanguageContext] Failed to load saved language:', err);
      }
    };
    loadSavedLanguage();
  }, []);

  const setLanguage = async (lang: Language) => {
    try {
      setLanguageState(lang);
      await AsyncStorage.setItem(STORAGE_KEY, lang);
    } catch (err) {
      console.warn('[LanguageContext] Failed to persist language:', err);
    }
  };

  const t = (key: keyof typeof translations['en']): string => {
    const langDict = translations[language] || translations['en'];
    return langDict[key] || translations['en'][key] || String(key);
  };

  const translateDynamic = (text: string): string => {
    if (!text) return '';
    try {
      return td(text, language);
    } catch (_) {
      return String(text);
    }
  };

  return (
    <LanguageContext.Provider value={{ language, setLanguage, t, translateDynamic }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = (): LanguageContextType => {
  const context = useContext(LanguageContext);
  return context || defaultContext;
};
