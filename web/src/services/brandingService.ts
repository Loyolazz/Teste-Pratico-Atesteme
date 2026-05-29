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
  primary: '#DFCCB4',
  secondary: '#ECDAC3',
  accent: '#FEDEB8',
  background: '#FEF5E2',
  surface: '#F6E8D5',
  surfaceSoft: '#FEDEB8',
  border: '#ECDAC3',
  muted: '#8F7E69',
  text: '#3A3026'
};

export const fallbackBranding: BrandingConfig = {
  appName: 'Task Manager',
  light: apiFallbackPalette,
  dark: apiFallbackPalette,
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
