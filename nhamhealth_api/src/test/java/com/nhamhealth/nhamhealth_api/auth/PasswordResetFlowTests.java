package com.nhamhealth.nhamhealth_api.auth;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Properties;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import com.jayway.jsonpath.JsonPath;
import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.auth.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

import jakarta.mail.Multipart;
import jakarta.mail.Part;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;

@SpringBootTest
@AutoConfigureMockMvc
class PasswordResetFlowTests {

    private static final Pattern CODE_PATTERN = Pattern.compile("code is (\\d{4})");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @MockitoBean
    private JavaMailSender mailSender;

    private MimeMessage emailMessage;

    @BeforeEach
    void resetMailSender() {
        reset(mailSender);
        emailMessage = new MimeMessage(Session.getInstance(new Properties()));
        when(mailSender.createMimeMessage()).thenReturn(emailMessage);
    }

    @Test
    void emailedCodeCanBeExchangedForAOneTimeTokenAndANewPassword() throws Exception {
        String email = "reset-" + UUID.randomUUID() + "@example.com";
        createUser(email, "OldPassword123!");

        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s"}
                                """.formatted(email)))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.message").isString());

        verify(mailSender).send(emailMessage);
        assertTrue(email.equals(emailMessage.getAllRecipients()[0].toString()));
        String emailContent = readContent(emailMessage);
        Matcher codeMatcher = CODE_PATTERN.matcher(emailContent);
        assertTrue(codeMatcher.find());
        assertTrue(emailMessage.getSubject().contains(codeMatcher.group(1)));
        assertTrue(emailContent.contains("expires in 3 minutes"));
        assertTrue(emailContent.contains("Here is your verification code"));
        assertTrue(emailContent.contains("Keep your account safe"));
        String code = codeMatcher.group(1);

        String wrongCode = "0000".equals(code) ? "0001" : "0000";
        mockMvc.perform(post("/api/v1/auth/verify-reset-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","code":"%s"}
                                """.formatted(email, wrongCode)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("The verification code is incorrect"));

        MvcResult verification = mockMvc.perform(post("/api/v1/auth/verify-reset-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","code":"%s"}
                                """.formatted(email, code)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.resetToken").isNotEmpty())
                .andExpect(jsonPath("$.expiresIn").value(900))
                .andReturn();
        String resetToken = JsonPath.read(
                verification.getResponse().getContentAsString(),
                "$.resetToken");

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"resetToken":"%s","newPassword":"NewPassword123!"}
                                """.formatted(resetToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Password reset successfully"));

        User updatedUser = userRepository.findByEmailIgnoreCase(email).orElseThrow();
        assertTrue(passwordEncoder.matches("NewPassword123!", updatedUser.getPasswordHash()));

        mockMvc.perform(post("/api/v1/auth/reset-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"resetToken":"%s","newPassword":"AnotherPassword123!"}
                                """.formatted(resetToken)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void unknownEmailGetsTheSameAcceptedResponseWithoutSendingMail() throws Exception {
        mockMvc.perform(post("/api/v1/auth/forgot-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"missing-%s@example.com"}
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.message").isString());

        verifyNoInteractions(mailSender);
    }

    private void createUser(String email, String password) {
        Role role = roleRepository.findByRoleNameIgnoreCase("USER").orElseGet(() -> {
            Role createdRole = new Role();
            createdRole.setRoleName("USER");
            createdRole.setDescription("Standard User");
            return roleRepository.save(createdRole);
        });
        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setRole(role);
        user.setStatus("ACTIVE");
        user.setIsVerified(true);
        userRepository.save(user);
    }

    private String readContent(Part part) throws Exception {
        Object content = part.getContent();
        if (content instanceof String text) {
            return text;
        }
        if (content instanceof Multipart multipart) {
            StringBuilder result = new StringBuilder();
            for (int index = 0; index < multipart.getCount(); index++) {
                result.append(readContent(multipart.getBodyPart(index)));
            }
            return result.toString();
        }
        return "";
    }
}
