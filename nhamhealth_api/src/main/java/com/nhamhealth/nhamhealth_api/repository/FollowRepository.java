package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nhamhealth.nhamhealth_api.entity.Follow;

@Repository
public interface FollowRepository extends JpaRepository<Follow, Long> {

}
