enum GameModeKind {
  local('Local'),
  bluetooth('Bluetooth'),
  online('En ligne');

  const GameModeKind(this.label);

  final String label;
}
