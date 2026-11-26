package com.gamgam.backend.map;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;
public interface PokeNotificationRepository extends JpaRepository<PokeNotification,String> {
    Optional<PokeNotification> findFirstByAppointmentIdAndSenderIdAndRecipientIdOrderByCreatedAtDesc(String appointmentId,String senderId,String recipientId);
    List<PokeNotification> findTop100ByRecipientIdOrderByCreatedAtDesc(String recipientId);
}
