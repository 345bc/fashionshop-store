package com.huit.zella.size;

public record SizeResponse(
        Integer id,
        String name,
        Integer displayOrder
) {
    public static SizeResponse from(Size size) {
        if (size == null) {
            return null;
        }

        return new SizeResponse(
                size.getId(),
                size.getName(),
                size.getDisplayOrder()
        );
    }

}
