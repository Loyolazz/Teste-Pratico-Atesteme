import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import {
  fallbackBranding,
  getBrandingConfig,
  type BrandingConfig,
  type BrandingPalette
} from '../services/brandingService';

type ThemeMode = 'light' | 'dark';

type ThemeContextValue = {
  theme: ThemeMode;
  appName: string;
  branding: BrandingConfig;
  toggleTheme: () => void;
};

const ThemeContext = createContext<ThemeContextValue | null>(null);
const THEME_KEY = 'atesteme-taskmanager-theme';

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<ThemeMode>(() => {
    return (localStorage.getItem(THEME_KEY) as ThemeMode | null) ?? 'light';
  });
  const [branding, setBranding] = useState<BrandingConfig>(fallbackBranding);

  useEffect(() => {
    let isMounted = true;

    getBrandingConfig().then((config) => {
      if (isMounted) {
        setBranding(config);
      }
    });

    return () => {
      isMounted = false;
    };
  }, []);

  useEffect(() => {
    const palette = theme === 'dark' ? branding.dark : branding.light;

    document.documentElement.dataset.theme = theme;
    document.title = branding.appName;
    applyPalette(palette);
    localStorage.setItem(THEME_KEY, theme);
  }, [branding, theme]);

  const value = useMemo(() => ({
    theme,
    appName: branding.appName,
    branding,
    toggleTheme: () => setTheme((current) => current === 'dark' ? 'light' : 'dark')
  }), [branding, theme]);

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

function applyPalette(palette: BrandingPalette) {
  const root = document.documentElement;

  root.style.setProperty('--bg', palette.background);
  root.style.setProperty('--surface', palette.surface);
  root.style.setProperty('--surface-soft', palette.surfaceSoft);
  root.style.setProperty('--text', palette.text);
  root.style.setProperty('--muted', palette.muted);
  root.style.setProperty('--border', palette.border);
  root.style.setProperty('--accent', palette.primary);
  root.style.setProperty('--accent-strong', palette.secondary);
  root.style.setProperty('--accent-soft', palette.accent);
  root.style.setProperty('--button-soft', palette.surfaceSoft);
  root.style.setProperty('--on-accent', readableTextFor(palette.primary));
}

function readableTextFor(hexColor: string) {
  const cleanHex = hexColor.replace('#', '');
  if (cleanHex.length !== 6) {
    return '#FFFFFF';
  }

  const red = Number.parseInt(cleanHex.slice(0, 2), 16);
  const green = Number.parseInt(cleanHex.slice(2, 4), 16);
  const blue = Number.parseInt(cleanHex.slice(4, 6), 16);
  const luminance = (0.299 * red + 0.587 * green + 0.114 * blue) / 255;

  return luminance > 0.6 ? '#17211F' : '#FFFFFF';
}

export function useTheme() {
  const context = useContext(ThemeContext);

  if (!context) {
    throw new Error('useTheme deve ser usado dentro de ThemeProvider.');
  }

  return context;
}
