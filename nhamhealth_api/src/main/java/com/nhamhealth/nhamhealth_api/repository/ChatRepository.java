package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nhamhealth.nhamhealth_api.entity.Chat;

@Repository
public interface ChatRepository extends JpaRepository<Chat, Integer> {
    List<Chat> findAllByOrderByLastMessageAtDescCreatedAtDesc();
}
