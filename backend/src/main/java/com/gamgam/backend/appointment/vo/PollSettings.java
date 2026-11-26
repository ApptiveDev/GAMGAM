package com.gamgam.backend.appointment.vo;

import jakarta.persistence.*;
import java.time.Instant;
import lombok.Getter;

/** An absent settings row preserves the legacy unrestricted poll contract. */
@Embeddable
@Getter
public class PollSettings {
    private boolean multipleSelection = true;
    private boolean anonymous;
    private boolean allowAddingOptions = true;
    private Instant startedAt;
    private Instant endsAt;
    private Instant closedAt;
    @Column(length = 100) private String giftDescription;
    @Enumerated(EnumType.STRING) private GiftMethod giftMethod;
    private Integer winnerCount;
    @Column(length = 4000) private String winnerIds;
    public enum GiftMethod { RANDOM, FIRST_COME }

    public PollSettings() {}
    public void configure(boolean multiple, boolean anonymous, boolean allowAdding, int minutes,
                          String gift, GiftMethod method, Integer count) {
        this.multipleSelection = multiple;
        this.anonymous = anonymous;
        this.allowAddingOptions = allowAdding;
        this.startedAt = Instant.now();
        this.endsAt = startedAt.plusSeconds(minutes * 60L);
        this.closedAt = null;
        this.giftDescription = gift;
        this.giftMethod = method;
        this.winnerCount = count;
        this.winnerIds = null;
    }
    public boolean closed() { return closedAt != null || endsAt != null && !Instant.now().isBefore(endsAt); }
    public void close() { if (closedAt == null) closedAt = Instant.now(); }
    public void award(java.util.List<String> users) { winnerIds = String.join(",", users); }
}
