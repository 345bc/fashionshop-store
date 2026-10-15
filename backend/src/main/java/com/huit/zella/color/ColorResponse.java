package com.huit.zella.color;

public record ColorResponse(
        Integer id,
        String name,
        String hexCode,
        String code
) {
    public static ColorResponse from(Color color) {
        if (color == null) {
            return null;
        }

        return new ColorResponse(
                color.getId(),
                color.getName(),
                color.getHexCode(),
                color.getCode()
        );
    }
}
