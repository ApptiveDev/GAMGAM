package com.gamgam.backend.map;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
public record LocationUpdateRequest(
        @NotNull @DecimalMin("-90") @DecimalMax("90") Double latitude,
        @NotNull @DecimalMin("-180") @DecimalMax("180") Double longitude,
        boolean sharingEnabled,
        String shareLevel,
        @DecimalMin("0") @DecimalMax("500") Double speedKmh,
        String transport
) {}
