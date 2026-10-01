package com.huit.zella.sizeguide;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;

@Entity
@Table(name = "size_guides")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class SizeGuide {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Nationalized
    @Column(nullable = false, length = 100)
    private String name;

    @Nationalized
    @Column(length = 500)
    private String description;

    @Column(name = "guide_image_url", length = 500)
    private String guideImageUrl;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;
}