import { apiRequest } from './apiClient';
import { logWarning } from '../utils/errors';

export type BrandingPalette = {
  primary: string;
  secondary: string;
  accent: string;
  background: string;
  surface: string;
  surfaceSoft: string;
  border: string;
  muted: string;
  text: string;
};

export type BrandingConfig = {
  appName: string;
  light: BrandingPalette;
  dark: BrandingPalette;
  fallback: BrandingPalette;
};

const apiFallbackPalette: BrandingPalette = {
  primary: '#008C35',
  secondary: '#27B46A',
  accent: '#D9F6E2',
  background: '#EAF3EE',
  surface: '#FBFEFC',
  surfaceSoft: '#EEF8F2',
  border: '#CADBD1',
  muted: '#66756D',
  text: '#17211F'
};

const darkFallbackPalette: BrandingPalette = {
  primary: '#4ADE80',
  secondary: '#22C55E',
  accent: '#143820',
  background: '#121714',
  surface: '#202621',
  surfaceSoft: '#263228',
  border: '#2F5740',
  muted: '#A7B5AC',
  text: '#EEF7F1'
};

export const fallbackBranding: BrandingConfig = {
  appName: 'Task Manager',
  light: apiFallbackPalette,
  dark: darkFallbackPalette,
  fallback: apiFallbackPalette
};

export async function getBrandingConfig(): Promise<BrandingConfig> {
  try {
    return await apiRequest<BrandingConfig>('/branding', { skipAuthRefresh: true });
  } catch (error) {
    logWarning('branding.load_failed_using_fallback', error);
    return fallbackBranding;
  }
}
