package com.gamgam.backend.room;

import com.gamgam.backend.global.config.ShareProperties;
import com.gamgam.backend.global.exception.*;
import com.gamgam.backend.user.repository.UserRepository;
import jakarta.validation.constraints.*;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class RoomInvitationService {
    private final RoomRepository rooms;
    private final RoomMemberRepository members;
    private final UserRepository users;
    private final RoomAccess access;
    private final ShareProperties shares;
    private final com.gamgam.backend.media.MediaService media;
    public record Invitation(String roomId, String inviteCode, String shareUrl) {}
    public record JoinRequest(@NotBlank @Size(max=36) String inviteCode) {}
    public record Member(String id, String name, boolean owner, String avatarUrl) {}
    public record UpdateRoom(@NotBlank @Size(max=50) String name,
            @Size(max=2048) @Pattern(regexp="https?://[^\\s]+") String coverImageUrl) {}
    public Invitation invite(String id, String user, boolean rotate) {
        Room r = rooms.findByIdForUpdate(id).orElseThrow(() -> new BusinessException(ErrorCode.ROOM_NOT_FOUND));
        access.requireMember(id, user);
        if (rotate) { owner(r, user); r.rotateInviteCode(); }
        String code = r.ensureInviteCode();
        return new Invitation(id, code, shares.baseUrl() + "/rooms/invite/" + code);
    }
    public RoomResponse join(String user, String code) {
        Room r = rooms.findByInviteCode(code.strip()).orElseThrow(() -> new BusinessException(ErrorCode.INVALID_INVITE_CODE));
        r = rooms.findByIdForUpdate(r.getId()).orElseThrow(() -> new BusinessException(ErrorCode.ROOM_NOT_FOUND));
        if (!code.strip().equals(r.getInviteCode())) throw new BusinessException(ErrorCode.INVALID_INVITE_CODE);
        if (!members.existsByRoomIdAndUserId(r.getId(), user)) members.save(new RoomMember(UUID.randomUUID().toString(), r,
                users.findById(user).orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND))));
        return RoomResponse.from(r, members.countByRoomId(r.getId()));
    }
    @Transactional(readOnly=true)
    public List<Member> members(String id, String user) {
        access.requireMember(id, user);
        return members.findByRoomIdOrderByIdAsc(id).stream().map(m -> new Member(m.getUser().getId(), m.getUser().getName(),
                m.getRoom().getOwnerId().equals(m.getUser().getId()), m.getUser().getAvatarUrl())).toList();
    }
    public RoomResponse rename(String id, String user, UpdateRoom request) {
        Room r = rooms.findByIdForUpdate(id).orElseThrow(() -> new BusinessException(ErrorCode.ROOM_NOT_FOUND));
        access.requireMember(id, user); owner(r, user); media.validateReference(user, request.coverImageUrl()); r.rename(request.name().strip()); if(request.coverImageUrl()!=null) r.setCoverImageUrl(request.coverImageUrl());
        return RoomResponse.from(r, members.countByRoomId(id));
    }
    private void owner(Room r, String user) {
        if (!r.getOwnerId().equals(user)) throw new BusinessException(ErrorCode.ROOM_ACCESS_DENIED);
    }
}
