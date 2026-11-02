bool blankPageDetected({required int text, required int valid, required int failed}) {
  return text > 500 && valid >= 4 && failed >= (valid < 10 ? (valid / 2).ceil() : 5);
}
