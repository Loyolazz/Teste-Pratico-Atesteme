const TOKEN_KEY = 'atesteme-taskmanager-token';
const REFRESH_TOKEN_KEY = 'atesteme-taskmanager-refresh-token';

export const tokenStorage = {
  get() {
    return localStorage.getItem(TOKEN_KEY);
  },
  getRefresh() {
    return localStorage.getItem(REFRESH_TOKEN_KEY);
  },
  set(token: string) {
    localStorage.setItem(TOKEN_KEY, token);
  },
  setTokens(accessToken: string, refreshToken: string) {
    localStorage.setItem(TOKEN_KEY, accessToken);
    localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
  },
  clear() {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
  }
};
