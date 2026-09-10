package com.nhamhealth.nhamhealth_api.entity;
import jakarta.persistence.*;
@Entity @Table(name="mood_translations", uniqueConstraints=@UniqueConstraint(name="uk_mood_translations_language", columnNames={"mood_id","language_code"}))
public class MoodTranslation {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Integer id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="mood_id",nullable=false) private Mood mood;
 @Column(name="language_code",nullable=false,length=2) private String languageCode;
 @Column(nullable=false,length=100) private String name;
 public Integer getId(){return id;} public Mood getMood(){return mood;} public void setMood(Mood v){mood=v;}
 public String getLanguageCode(){return languageCode;} public void setLanguageCode(String v){languageCode=v;}
 public String getName(){return name;} public void setName(String v){name=v;}
}
