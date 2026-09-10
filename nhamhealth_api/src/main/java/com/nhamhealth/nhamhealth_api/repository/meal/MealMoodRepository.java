package com.nhamhealth.nhamhealth_api.repository.meal;
import java.util.*; import org.springframework.data.jpa.repository.JpaRepository; import com.nhamhealth.nhamhealth_api.entity.MealMood;
public interface MealMoodRepository extends JpaRepository<MealMood,Integer>{ List<MealMood> findByMealMealId(Integer id); }
