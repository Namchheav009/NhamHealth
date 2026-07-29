package com.nhamhealth.nhamhealth_api.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class WebLoginController {

	@GetMapping("/login")
	public String login() {
		return "login";
	}
}
