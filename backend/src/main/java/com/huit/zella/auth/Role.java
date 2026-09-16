package com.huit.zella.auth;

import com.nimbusds.jose.shaded.gson.annotations.SerializedName;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.Nationalized;

@Entity
@Table(name = "roles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Role {
    //    CREATE TABLE roles
//            (
//                    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
//    role_code   VARCHAR(50) NOT NULL UNIQUE,
//    role_name   NVARCHAR(100) NOT NULL,
//    description NVARCHAR(255) NULL
//);
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "role_code", nullable = false, unique = true, length = 50)
    private String roleCode;

    @Nationalized
    @Column(name = "role_name", nullable = false, length = 100)
    private String roleName;

    private String description;

}
