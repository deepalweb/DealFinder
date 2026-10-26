/** JSON must not be able to close its enclosing JSON-LD script element. */
export function serializeStructuredData(value: unknown): string {
  return (JSON.stringify(value) ?? 'null').replace(/</g, '\\u003c');
}
