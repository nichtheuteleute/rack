class RackEntry {
  final Type type;
  final Object Function() create;
  final void Function(Object)? dispose;

  RackEntry({required this.type, required this.create, this.dispose});
}

class RackBindings {
  final List<RackEntry> _entries = [];

  void add<T extends Object>(T Function() create, {void Function(T)? dispose}) {
    _entries.add(RackEntry(
      type: T,
      create: create,
      dispose: dispose != null ? (obj) => dispose(obj as T) : null,
    ));
  }

  List<RackEntry> get entries => List.unmodifiable(_entries);
}
