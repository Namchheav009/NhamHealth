package com.nhamhealth.nhamhealth_api.entity;
import jakarta.persistence.*;
@Entity @Table(name="meal_moods", uniqueConstraints=@UniqueConstraint(name="uk_meal_moods", columnNames={"meal_id","mood_id"}))
public class MealMood {
 @Id @GeneratedValue(strategy=GenerationType.IDENTITY) @Column(name="meal_mood_id") private Integer id;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="meal_id",nullable=false) private Meal meal;
 @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="mood_id",nullable=false) private Mood mood;
 public Integer getId(){return id;} public Meal getMeal(){return meal;} public void setMeal(Meal v){meal=v;} public Mood getMood(){return mood;} public void setMood(Mood v){mood=v;}
}
