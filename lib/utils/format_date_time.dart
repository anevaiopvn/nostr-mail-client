String formatDateTime(DateTime date) {
  return '${date.day}/${date.month}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
