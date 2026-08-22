package com.nhamhealth.nhamhealth_api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class NhamhealthApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(NhamhealthApiApplication.class, args);
	}

}
