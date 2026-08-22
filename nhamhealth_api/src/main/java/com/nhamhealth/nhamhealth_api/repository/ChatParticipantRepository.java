package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.ChatParticipant;

public interface ChatParticipantRepository extends JpaRepository<ChatParticipant, Integer> {
    long countByChatChatIdAndLeftAtIsNull(Integer chatId);

    @Query("""
            select participant.chat.chatId as chatId, count(participant) as total
            from ChatParticipant participant
            where participant.chat.chatId in :chatIds and participant.leftAt is null
            group by participant.chat.chatId
            """)
    List<ChatCount> countActiveByChatIds(@Param("chatIds") List<Integer> chatIds);

    @Query("select count(distinct participant.user.userId) from ChatParticipant participant where participant.leftAt is null")
    long countActiveUsers();

    interface ChatCount {
        Integer getChatId();
        long getTotal();
    }
}
