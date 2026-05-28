class PagedResultEntity<T> {
  final List<T> items;
  final int totalCount;
  final int offset;
  final int limit;

  const PagedResultEntity({
    required this.items,
    required this.totalCount,
    required this.offset,
    required this.limit,
  });

  bool get hasMore => offset + items.length < totalCount;
}
