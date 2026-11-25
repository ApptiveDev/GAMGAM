package com.gamgam.backend.map;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
public interface LiveLocationRepository extends JpaRepository<LiveLocation, Long> {
    void deleteByRoomIdAndUserId(String roomId, String userId);
    Optional<LiveLocation> findByRoomIdAndUserId(String roomId, String userId);
    List<LiveLocation> findByRoomIdAndSharingEnabledTrue(String roomId);
}
