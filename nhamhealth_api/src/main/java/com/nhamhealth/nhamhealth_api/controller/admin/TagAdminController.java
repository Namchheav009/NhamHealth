package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
import java.util.Map;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.cache.annotation.CacheEvict;

import com.nhamhealth.nhamhealth_api.dto.request.AdminTagRequest;
import com.nhamhealth.nhamhealth_api.entity.TagType;
import com.nhamhealth.nhamhealth_api.repository.catalog.TagTypeRepository;

import jakarta.validation.Valid;

@Controller
public class TagAdminController {

    private final TagTypeRepository tagTypeRepository;

    public TagAdminController(TagTypeRepository tagTypeRepository) {
        this.tagTypeRepository = tagTypeRepository;
    }

    @GetMapping("/admin/tags")
    public String tags(Authentication authentication, Model model) {
        List<TagType> tags = tagTypeRepository.findAllByOrderByTagNameAsc();

        long activeTags = tags.stream()
                .filter(tag -> Boolean.TRUE.equals(tag.getIsActive()))
                .count();

        model.addAttribute("pageTitle", "Tags");
        model.addAttribute("activePage", "tags");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("tags", tags);
        model.addAttribute("totalTags", tags.size());
        model.addAttribute("activeTags", activeTags);
        model.addAttribute("inactiveTags", Math.max(0, tags.size() - activeTags));
        return "admin/tags";
    }

    @PostMapping("/admin/tags")
    @CacheEvict(value = {"tags", "mealTagNames"}, allEntries = true)
    @ResponseBody
    public ResponseEntity<?> createTag(@Valid @RequestBody AdminTagRequest request) {
        if (tagTypeRepository.findByTagNameIgnoreCase(request.tagName().trim()).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("message", "A tag with this name already exists"));
        }
        TagType tag = new TagType();
        apply(tag, request);
        return ResponseEntity.ok(toResponse(tagTypeRepository.saveAndFlush(tag)));
    }

    @PutMapping("/admin/tags/{tagId}")
    @CacheEvict(value = {"tags", "mealTagNames"}, allEntries = true)
    @ResponseBody
    public ResponseEntity<?> updateTag(@PathVariable Integer tagId, @Valid @RequestBody AdminTagRequest request) {
        return tagTypeRepository.findById(tagId)
                .<ResponseEntity<?>>map(tag -> {
                    boolean duplicate = tagTypeRepository.findByTagNameIgnoreCase(request.tagName().trim())
                            .filter(existing -> !existing.getTagId().equals(tagId)).isPresent();
                    if (duplicate) {
                        return ResponseEntity.badRequest().body(Map.of("message", "A tag with this name already exists"));
                    }
                    apply(tag, request);
                    return ResponseEntity.ok(toResponse(tagTypeRepository.saveAndFlush(tag)));
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/admin/tags/{tagId}")
    @CacheEvict(value = {"tags", "mealTagNames"}, allEntries = true)
    @ResponseBody
    public ResponseEntity<?> deleteTag(@PathVariable Integer tagId) {
        if (!tagTypeRepository.existsById(tagId)) {
            return ResponseEntity.notFound().build();
        }
        try {
            tagTypeRepository.deleteById(tagId);
            tagTypeRepository.flush();
            return ResponseEntity.noContent().build();
        } catch (DataIntegrityViolationException exception) {
            return ResponseEntity.status(409)
                    .body(Map.of("message", "This tag is used by a meal or post. Mark it inactive instead."));
        }
    }

    private void apply(TagType tag, AdminTagRequest request) {
        tag.setTagName(request.tagName().trim());
        tag.setTagScope(request.tagScope().trim().toUpperCase());
        tag.setDescription(request.description() == null || request.description().isBlank()
                ? null : request.description().trim());
        tag.setIsActive(request.active() == null || request.active());
    }

    private Map<String, Object> toResponse(TagType tag) {
        return Map.of(
                "id", tag.getTagId(),
                "tagName", tag.getTagName(),
                "tagScope", tag.getTagScope(),
                "description", tag.getDescription() == null ? "" : tag.getDescription(),
                "active", Boolean.TRUE.equals(tag.getIsActive()));
    }
}
