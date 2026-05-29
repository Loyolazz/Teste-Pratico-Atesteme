package com.atesteme.taskmanager.branding;

public record BrandingResponse(
        String appName,
        BrandingPaletteResponse light,
        BrandingPaletteResponse dark,
        BrandingPaletteResponse fallback
) {

    static BrandingResponse from(BrandingProperties properties) {
        return new BrandingResponse(
                properties.getAppName(),
                toResponse(properties.getLight()),
                toResponse(properties.getDark()),
                toResponse(properties.getFallback())
        );
    }

    private static BrandingPaletteResponse toResponse(BrandingProperties.Palette palette) {
        return new BrandingPaletteResponse(
                palette.getPrimary(),
                palette.getSecondary(),
                palette.getAccent(),
                palette.getBackground(),
                palette.getSurface(),
                palette.getSurfaceSoft(),
                palette.getBorder(),
                palette.getMuted(),
                palette.getText()
        );
    }
}
