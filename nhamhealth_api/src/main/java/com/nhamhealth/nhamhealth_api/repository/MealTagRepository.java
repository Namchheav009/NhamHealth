package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.nhamhealth.nhamhealth_api.entity.MealTag;

public interface MealTagRepository extends JpaRepository<MealTag, Integer> {

    List<MealTag> findByMealMealId(Integer mealId);

    @Query("select distinct mealTag.tag.tagName from MealTag mealTag order by mealTag.tag.tagName")
    List<String> findDistinctTagNames();
}
