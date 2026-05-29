package com.atesteme.taskmanager.branding;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "app.branding")
public class BrandingProperties {

    private String appName = "Task Manager";
    private Palette light = Palette.lightDefaults();
    private Palette dark = Palette.darkDefaults();
    private Palette fallback = Palette.fallbackDefaults();

    public String getAppName() {
        return appName;
    }

    public void setAppName(String appName) {
        this.appName = appName;
    }

    public Palette getLight() {
        return light;
    }

    public void setLight(Palette light) {
        this.light = light;
    }

    public Palette getDark() {
        return dark;
    }

    public void setDark(Palette dark) {
        this.dark = dark;
    }

    public Palette getFallback() {
        return fallback;
    }

    public void setFallback(Palette fallback) {
        this.fallback = fallback;
    }

    public static class Palette {
        private String primary;
        private String secondary;
        private String accent;
        private String background;
        private String surface;
        private String surfaceSoft;
        private String border;
        private String muted;
        private String text;

        static Palette lightDefaults() {
            Palette palette = new Palette();
            palette.primary = "#01B636";
            palette.secondary = "#3BD16F";
            palette.accent = "#74E39A";
            palette.background = "#F7FBF8";
            palette.surface = "#FFFFFF";
            palette.surfaceSoft = "#F4FFF6";
            palette.border = "#E3E3E3";
            palette.muted = "#989898";
            palette.text = "#17211F";
            return palette;
        }

        static Palette darkDefaults() {
            Palette palette = new Palette();
            palette.primary = "#003297";
            palette.secondary = "#00157F";
            palette.accent = "#00094B";
            palette.background = "#0C0C0C";
            palette.surface = "#1D1D1D";
            palette.surfaceSoft = "#242424";
            palette.border = "#003297";
            palette.muted = "#989898";
            palette.text = "#E3E3E3";
            return palette;
        }

        static Palette fallbackDefaults() {
            Palette palette = new Palette();
            palette.primary = "#DFCCB4";
            palette.secondary = "#ECDAC3";
            palette.accent = "#FEDEB8";
            palette.background = "#FEF5E2";
            palette.surface = "#F6E8D5";
            palette.surfaceSoft = "#FEDEB8";
            palette.border = "#ECDAC3";
            palette.muted = "#8F7E69";
            palette.text = "#3A3026";
            return palette;
        }

        public String getPrimary() {
            return primary;
        }

        public void setPrimary(String primary) {
            this.primary = primary;
        }

        public String getSecondary() {
            return secondary;
        }

        public void setSecondary(String secondary) {
            this.secondary = secondary;
        }

        public String getAccent() {
            return accent;
        }

        public void setAccent(String accent) {
            this.accent = accent;
        }

        public String getBackground() {
            return background;
        }

        public void setBackground(String background) {
            this.background = background;
        }

        public String getSurface() {
            return surface;
        }

        public void setSurface(String surface) {
            this.surface = surface;
        }

        public String getSurfaceSoft() {
            return surfaceSoft;
        }

        public void setSurfaceSoft(String surfaceSoft) {
            this.surfaceSoft = surfaceSoft;
        }

        public String getBorder() {
            return border;
        }

        public void setBorder(String border) {
            this.border = border;
        }

        public String getMuted() {
            return muted;
        }

        public void setMuted(String muted) {
            this.muted = muted;
        }

        public String getText() {
            return text;
        }

        public void setText(String text) {
            this.text = text;
        }
    }
}
