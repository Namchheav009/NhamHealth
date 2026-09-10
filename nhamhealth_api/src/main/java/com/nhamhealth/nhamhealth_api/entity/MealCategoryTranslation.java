package com.nhamhealth.nhamhealth_api.entity;
import jakarta.persistence.*;
@Entity @Table(name="meal_category_translations", uniqueConstraints=@UniqueConstraint(name="uk_meal_category_translations_language", columnNames={"category_id","language_code"}))
public class MealCategoryTranslation {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) 
 private Integer id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="category_id",nullable=false) 
 private MealCategory category;
 @Column(name="language_code",nullable=false,length=2) 
 private String languageCode;
 @Column(nullable=false,length=50) 
 private String name; @Column(length=1000) 
 private String description;
 public Integer getId(){return id;} 
 public MealCategory getCategory(){return category;} 
 public void setCategory(MealCategory v){category=v;}
 public String getLanguageCode(){return languageCode;} 
 public void setLanguageCode(String v){languageCode=v;}
 public String getName(){return name;}
  public void setName(String v){name=v;} 
  public String getDescription(){return description;} 
  public void setDescription(String v){description=v;}
}
