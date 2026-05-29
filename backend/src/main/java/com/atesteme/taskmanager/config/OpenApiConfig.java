package com.atesteme.taskmanager.config;

import com.atesteme.taskmanager.branding.BrandingProperties;
import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI openAPI(BrandingProperties brandingProperties) {
        String bearerScheme = "bearerAuth";

        return new OpenAPI()
                .info(new Info()
                        .title(brandingProperties.getAppName() + " API")
                        .version("1.0.0")
                        .description("API REST compartilhada pelo painel web e pelo aplicativo mobile."))
                .addSecurityItem(new SecurityRequirement().addList(bearerScheme))
                .components(new Components().addSecuritySchemes(
                        bearerScheme,
                        new SecurityScheme()
                                .name(bearerScheme)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                ));
    }
}
