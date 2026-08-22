package com.nhamhealth.nhamhealth_api.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.Message;

public interface MessageRepository extends JpaRepository<Message, Integer> {
    long countByChatChatIdAndDeletedAtIsNull(Integer chatId);

    List<Message> findTop50ByChatChatIdAndDeletedAtIsNullOrderByCreatedAtDesc(Integer chatId);

    @Query("""
            select message.chat.chatId as chatId, count(message) as total
            from Message message
            where message.chat.chatId in :chatIds and message.deletedAt is null
            group by message.chat.chatId
            """)
    List<ChatCount> countActiveByChatIds(@Param("chatIds") List<Integer> chatIds);

    long countByCreatedAtGreaterThanEqualAndDeletedAtIsNull(LocalDateTime since);

    interface ChatCount {
        Integer getChatId();
        long getTotal();
    }
}
