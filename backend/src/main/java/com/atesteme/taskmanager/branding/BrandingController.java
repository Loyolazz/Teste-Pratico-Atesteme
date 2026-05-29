package com.atesteme.taskmanager.branding;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/branding")
public class BrandingController {

    private final BrandingProperties brandingProperties;

    public BrandingController(BrandingProperties brandingProperties) {
        this.brandingProperties = brandingProperties;
    }

    @GetMapping
    public BrandingResponse getBranding() {
        return BrandingResponse.from(brandingProperties);
    }
}
