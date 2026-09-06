import 'package:flutter/material.dart';

import '../models/board_data.dart';
import '../models/board_layout.dart';
import '../models/board_theme.dart';
import '../services/custom_board_service.dart';
import '../widgets/board_painter.dart';

/// Lists the player's custom boards and lets them create a new one or edit
/// an existing one.
class BoardEditorListScreen extends StatefulWidget {
  const BoardEditorListScreen({super.key});

  @override
  State<BoardEditorListScreen> createState() => _BoardEditorListScreenState();
}

class _BoardEditorListScreenState extends State<BoardEditorListScreen> {
  List<CustomBoard> _boards = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final boards = await CustomBoardService.instance.loadAll();
    if (mounted) setState(() => _boards = boards);
  }

  Future<void> _openEditor({CustomBoard? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BoardEditScreen(existing: existing)),
    );
    await _reload();
  }

  Future<void> _delete(CustomBoard board) async {
    await CustomBoardService.instance.delete(board.name);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes plateaux'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Crée ton propre plateau : place tes échelles, serpents et cases bonus/malus, '
                'puis choisis-le au moment de lancer une partie locale.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Créer un nouveau plateau'),
              ),
              const SizedBox(height: 20),
              if (_boards.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Aucun plateau personnalisé pour l\'instant.')),
                ),
              ..._boards.map(
                (b) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.map_rounded, color: Color(0xFF8E24AA)),
                    title: Text(b.name),
                    subtitle: Text(_summary(b.layout)),
                    onTap: () => _openEditor(existing: b),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () => _delete(b),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summary(BoardLayout layout) {
    final snakes = layout.snakesAndLadders.entries.where((e) => e.value < e.key).length;
    final ladders = layout.snakesAndLadders.entries.where((e) => e.value > e.key).length;
    return '$snakes serpent${snakes > 1 ? 's' : ''} · $ladders échelle${ladders > 1 ? 's' : ''}';
  }
}

enum _EditMode { ladder, snake, bonus, erase }

/// The actual editor: tap two cells to place a ladder/snake, tap one cell to
/// place a bonus/malus, with a live preview of the board being built.
class BoardEditScreen extends StatefulWidget {
  const BoardEditScreen({super.key, this.existing});

  final CustomBoard? existing;

  @override
  State<BoardEditScreen> createState() => _BoardEditScreenState();
}

class _BoardEditScreenState extends State<BoardEditScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final Map<int, int> _snakesAndLadders =
      Map.of(widget.existing?.layout.snakesAndLadders ?? BoardLayout.classic.snakesAndLadders);
  late final Map<int, int> _bonusCells =
      Map.of(widget.existing?.layout.bonusCells ?? BoardLayout.classic.bonusCells);

  _EditMode _mode = _EditMode.ladder;
  int? _pendingStart;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  BoardLayout get _layout =>
      BoardLayout(snakesAndLadders: _snakesAndLadders, bonusCells: _bonusCells);

  void _onCellTap(int cell) {
    if (cell == 1 || cell == finishCell) {
      _showMessage('La case GO et la case FINISH ne se modifient pas.');
      return;
    }
    switch (_mode) {
      case _EditMode.ladder:
      case _EditMode.snake:
        _handleLadderOrSnakeTap(cell);
      case _EditMode.bonus:
        _pendingStart = null;
        _promptBonusValue(cell);
      case _EditMode.erase:
        _pendingStart = null;
        setState(() {
          _snakesAndLadders.remove(cell);
          _bonusCells.remove(cell);
        });
    }
  }

  void _handleLadderOrSnakeTap(int cell) {
    final start = _pendingStart;
    if (start == null) {
      setState(() => _pendingStart = cell);
      return;
    }
    if (cell == start) {
      setState(() => _pendingStart = null);
      return;
    }
    final wantsLadder = _mode == _EditMode.ladder;
    // Order the two taps so a ladder always climbs and a snake always
    // slides, whichever order the player tapped them in.
    final low = start < cell ? start : cell;
    final high = start < cell ? cell : start;
    setState(() {
      if (wantsLadder) {
        _snakesAndLadders[low] = high;
      } else {
        _snakesAndLadders[high] = low;
      }
      _pendingStart = null;
    });
  }

  Future<void> _promptBonusValue(int cell) async {
    final value = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [-5, -3, -2, -1, 1, 2, 3, 5].map((v) {
            return Padding(
              padding: const EdgeInsets.all(6),
              child: ChoiceChip(
                label: Text(v > 0 ? '+$v' : '$v'),
                selected: false,
                onSelected: (_) => Navigator.of(context).pop(v),
              ),
            );
          }).toList(),
        ),
      ),
    );
    if (value != null) {
      setState(() => _bonusCells[cell] = value);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Donne un nom à ton plateau.');
      return;
    }
    await CustomBoardService.instance.save(CustomBoard(name: name, layout: _layout));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Nouveau plateau' : 'Modifier le plateau'),
        actions: [
          IconButton(icon: const Icon(Icons.save_rounded), onPressed: _save),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du plateau',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Échelle'),
                      avatar: const Icon(Icons.stairs_rounded, size: 18),
                      selected: _mode == _EditMode.ladder,
                      onSelected: (_) => setState(() {
                        _mode = _EditMode.ladder;
                        _pendingStart = null;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Serpent'),
                      avatar: const Icon(Icons.timeline_rounded, size: 18),
                      selected: _mode == _EditMode.snake,
                      onSelected: (_) => setState(() {
                        _mode = _EditMode.snake;
                        _pendingStart = null;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Bonus/malus'),
                      avatar: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      selected: _mode == _EditMode.bonus,
                      onSelected: (_) => setState(() {
                        _mode = _EditMode.bonus;
                        _pendingStart = null;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('Effacer'),
                      avatar: const Icon(Icons.backspace_outlined, size: 18),
                      selected: _mode == _EditMode.erase,
                      onSelected: (_) => setState(() {
                        _mode = _EditMode.erase;
                        _pendingStart = null;
                      }),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _pendingStart != null
                      ? 'Case de départ : $_pendingStart. Touche la case d\'arrivée.'
                      : _mode == _EditMode.bonus
                          ? 'Touche une case pour lui donner un bonus ou un malus.'
                          : _mode == _EditMode.erase
                              ? 'Touche une case pour effacer ce qu\'elle contient.'
                              : 'Touche la case de départ.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      var cellSize = constraints.maxWidth / boardCols;
                      if (constraints.maxHeight.isFinite) {
                        final byHeight = constraints.maxHeight / boardRows;
                        if (byHeight < cellSize) cellSize = byHeight;
                      }
                      final width = cellSize * boardCols;
                      final height = cellSize * boardRows;
                      return Center(
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: Size(width, height),
                                painter: BoardPainter(theme: BoardTheme.classic, layout: _layout),
                              ),
                              for (var cell = 2; cell < finishCell; cell++)
                                _buildTapTarget(cell, width, height, cellSize),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTapTarget(int cell, double boardWidth, double boardHeight, double cellSize) {
    final centre = cellCenter(cell, boardWidth, boardHeight);
    final highlighted = _pendingStart == cell;
    return Positioned(
      left: centre.dx - cellSize / 2,
      top: centre.dy - cellSize / 2,
      width: cellSize,
      height: cellSize,
      child: GestureDetector(
        onTap: () => _onCellTap(cell),
        child: highlighted
            ? Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
              )
            : null,
      ),
    );
  }
}
