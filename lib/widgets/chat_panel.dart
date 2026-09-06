import 'package:flutter/material.dart';

import '../network/chat_controller.dart';

/// A view over a [ChatController] — sending/receiving is handled by the
/// controller (which outlives this widget), so messages sent while the
/// panel is closed are never lost and are reflected as unread count.
class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key, required this.controller, required this.myName});

  final ChatController controller;
  final String myName;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.markAllRead();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    widget.controller.send(widget.myName, _textController.text);
    _textController.clear();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.controller.messages;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: messages.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucun message pour le moment.'),
                )
              : ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = m.from == widget.myName;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFFFB8C00).withValues(alpha: 0.85)
                              : const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe)
                              Text(
                                m.from,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            Text(
                              m.text,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Écrire un message…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
            ],
          ),
        ),
      ],
    );
  }
}
