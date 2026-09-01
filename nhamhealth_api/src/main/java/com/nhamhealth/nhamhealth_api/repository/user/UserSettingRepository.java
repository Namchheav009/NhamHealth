package com.nhamhealth.nhamhealth_api.repository.user;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import com.nhamhealth.nhamhealth_api.entity.UserSetting;

public interface UserSettingRepository extends JpaRepository<UserSetting, Integer> {
    Optional<UserSetting> findByUserUserId(Integer userId);
}
