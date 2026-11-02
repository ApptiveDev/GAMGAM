import 'package:flutter/material.dart';

import '../../../data/models/live_location.dart';
import 'live_person.dart';
import 'live_style.dart';

/// 지도에서 마커를 눌렀을 때 상단에 뜨는 그 사람 카드.
/// 상태 메시지는 아직 데이터가 없어서 자리만 있다. (항상 빈 문구)
class PersonCard extends StatelessWidget {
  const PersonCard({
    super.key,
    required this.person,
    required this.isMe,
    required this.rank,
    required this.cooldown,
    required this.onPoke,
    this.statusMessage,
    this.onEdit,
  });

  final LiveParticipant person;
  final bool isMe;
  final int? rank;
  final Duration cooldown;
  final VoidCallback onPoke;
  final String? statusMessage;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final message = statusMessage;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LiveColors.border),
        boxShadow: liveShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          LiveAvatar(person.participant, size: 42, borderWidth: 1.05, off: person.status == LiveStatus.sharingOff),
          const SizedBox(width: 10.7),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(person.participant.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: liveText(13, FontWeight.w500, Colors.black)),
              const SizedBox(height: 7),
              LiveStatusLine(person, size: 12),
            ]),
          ),
          const SizedBox(width: 8),
          LiveAction(person: person, isMe: isMe, rank: rank, cooldown: cooldown, onPoke: onPoke, showEdit: true, onEdit: onEdit),
        ]),
        const SizedBox(height: 16.8),
        Text(
          message == null || message.isEmpty ? '아직 상태 메시지가 존재하지 않습니다.' : message,
          style: liveText(13, FontWeight.w400, message == null || message.isEmpty ? LiveColors.textHint : LiveColors.textStrong),
        ),
      ]),
    );
  }
}
