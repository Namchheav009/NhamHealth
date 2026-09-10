package com.nhamhealth.nhamhealth_api.entity;
import jakarta.persistence.*;
@Entity @Table(name="tag_translations", uniqueConstraints=@UniqueConstraint(name="uk_tag_translations_language", columnNames={"tag_id","language_code"}))
public class TagTranslation {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Integer id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="tag_id",nullable=false) private TagType tag;
 @Column(name="language_code",nullable=false,length=2) private String languageCode;
 @Column(nullable=false,length=100) private String name; @Column(length=1000) private String description;
 public Integer getId(){return id;} public TagType getTag(){return tag;} public void setTag(TagType v){tag=v;}
 public String getLanguageCode(){return languageCode;} public void setLanguageCode(String v){languageCode=v;}
 public String getName(){return name;} public void setName(String v){name=v;} public String getDescription(){return description;} public void setDescription(String v){description=v;}
}
