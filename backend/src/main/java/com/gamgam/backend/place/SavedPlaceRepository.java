package com.gamgam.backend.place;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface SavedPlaceRepository extends JpaRepository<SavedPlace,String> {
    List<SavedPlace> findByUserIdOrderByCreatedAtDesc(String userId);
}
