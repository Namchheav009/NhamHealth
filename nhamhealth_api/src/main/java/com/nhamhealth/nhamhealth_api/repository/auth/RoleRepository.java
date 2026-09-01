package com.nhamhealth.nhamhealth_api.repository.auth;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.Role;

public interface RoleRepository extends JpaRepository<Role, Integer> {

    Optional<Role> findByRoleNameIgnoreCase(String roleName);
}
