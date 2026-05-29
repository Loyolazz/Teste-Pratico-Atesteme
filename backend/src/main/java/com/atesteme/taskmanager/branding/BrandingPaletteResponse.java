package com.atesteme.taskmanager.branding;

public record BrandingPaletteResponse(
        String primary,
        String secondary,
        String accent,
        String background,
        String surface,
        String surfaceSoft,
        String border,
        String muted,
        String text
) {
}
