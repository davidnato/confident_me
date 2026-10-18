/// 32-bit FNV-1a hash. Unlike String.hashCode, this is guaranteed to give the
/// same number on every run, so "random-looking but repeatable" choices (like
/// tie-breaks in the daily challenge) are stable.
int stableHash(String input) {
  var hash = 0x811C9DC5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
