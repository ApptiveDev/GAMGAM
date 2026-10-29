import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/poke_note.dart';
import 'widgets/note_card.dart';
import 'widgets/note_sheet.dart';
import 'widgets/poke_style.dart';

/// 08 · 콕 찌르기 (보내는 쪽) — 쪽지 꾸미기. 보내면 꾸민 쪽지를, 닫으면 null을 돌려준다.
Future<PokeNote?> showPokeNotePage(BuildContext context) =>
    Navigator.of(context).push<PokeNote>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const PokeNotePage()));

class PokeNotePage extends StatefulWidget {
  const PokeNotePage({super.key});

  @override
  State<PokeNotePage> createState() => _PokeNotePageState();
}

class _PokeNotePageState extends State<PokeNotePage> {
  PokeNote _note = const PokeNote();
  NoteTab? _tab;

  void _toggle(NoteTab tab) => setState(() => _tab = _tab == tab ? null : tab);
  void _close() => setState(() => _tab = null);

  void _pickCard(NoteCard card) => setState(() {
        _note = _note.copyWith(card: card);
        _tab = null;
      });

  void _pickPhrase(String phrase) => setState(() {
        _note = _note.copyWith(text: phrase);
        _tab = null;
      });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final open = _tab != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        const Positioned.fill(child: DotBackground()),
        // 상단은 흰색에서 투명으로.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: top + 91,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0x00FFFFFF)],
                stops: [0.76, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: top + 147,
          left: 0,
          right: 0,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NoteCardView.radius),
                boxShadow: const [BoxShadow(color: Color(0x4D212121), blurRadius: 7)],
              ),
              child: NoteCardView(card: _note.card, text: _note.text),
            ),
          ),
        ),
        Positioned(left: 0, right: 0, top: top, child: _TopBar(canSend: _note.canSend, onSend: () => Navigator.pop(context, _note))),
        // 시트가 열리면 뒤를 어둡게 흐리고, 누르면 닫힌다.
        if (open)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: const ColoredBox(color: Color(0x66212121)),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: NoteSheet(
            tab: _tab,
            onTab: _toggle,
            onClose: _close,
            child: switch (_tab) {
              NoteTab.card => CardPicker(onPick: _pickCard),
              NoteTab.text => PhrasePicker(onPick: _pickPhrase),
              NoteTab.emoji || null => null,
            },
          ),
        ),
      ]),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.canSend, required this.onSend});

  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 68,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: '닫기',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
              icon: SvgPicture.asset('${PokeStyle.assets}/icons/close.svg', width: 24, height: 24),
            ),
            const Spacer(),
            if (canSend)
              Material(
                color: PokeStyle.pink,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onSend,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    child: Text('보내기', style: TextStyle(fontFamily: 'Pretendard', fontSize: 14, fontWeight: FontWeight.w500, color: PokeStyle.textBody)),
                  ),
                ),
              ),
          ]),
        ),
      );
}
