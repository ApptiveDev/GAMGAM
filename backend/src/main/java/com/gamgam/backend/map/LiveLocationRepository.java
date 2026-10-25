package com.gamgam.backend.map;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
interface LiveLocationRepository extends JpaRepository<LiveLocation, Long> {
    Optional<LiveLocation> findByRoomIdAndUserId(String roomId, String userId);
    List<LiveLocation> findByRoomIdAndSharingEnabledTrue(String roomId);
}
