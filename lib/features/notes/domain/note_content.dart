/// Shared helpers for deciding whether a note is worth persisting.
bool noteHasContent({required String title, required String plainBody}) {
  return title.trim().isNotEmpty || plainBody.trim().isNotEmpty;
}
