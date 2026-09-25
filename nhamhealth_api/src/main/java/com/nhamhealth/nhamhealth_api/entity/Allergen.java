package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "allergens")
public class Allergen {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "allergen_id")
    private Integer allergenId;

    @Column(name = "code", nullable = false, unique = true, length = 40)
    private String code;

    @Column(name = "name_en", nullable = false, length = 100)
    private String nameEn;

    public Integer getAllergenId() { return allergenId; }
    public String getCode() { return code; }
    public String getNameEn() { return nameEn; }
}
