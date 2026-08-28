package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;
<<<<<<< HEAD
=======
import java.util.Optional;
>>>>>>> de26f8c42978dce467e11832233dcabe163d6bc0
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.nhamhealth.nhamhealth_api.entity.Post;

public interface PostRepository extends JpaRepository<Post, Integer> {
    @EntityGraph(attributePaths = "user")
    List<Post> findAllByOrderByUpdatedAtDescCreatedAtDesc();

    @EntityGraph(attributePaths = "user")
    List<Post> findByUser_UserIdAndStatusIgnoreCaseOrderByUpdatedAtDescCreatedAtDesc(
            Integer userId, String status);

    @EntityGraph(attributePaths = "user")
    Page<Post> findAllByOrderByUpdatedAtDescCreatedAtDesc(Pageable pageable);

<<<<<<< HEAD
=======
    Optional<Post> findByRecipeRecipeId(Integer recipeId);

>>>>>>> de26f8c42978dce467e11832233dcabe163d6bc0
    @Query("select count(distinct post.user.userId) from Post post")
    long countDistinctAuthors();
}
