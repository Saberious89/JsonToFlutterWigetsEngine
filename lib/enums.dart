enum DocumentStatusEnum {
  pending(1),
  approved(2),
  rejicted(3);

  final int value;
  const DocumentStatusEnum(this.value);
}
