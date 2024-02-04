class WarnRecord {
  final int checkPointIndex;
  final String warnCreateTime;
  final List<String> sessionIds;

  WarnRecord({
    required this.checkPointIndex,
    required this.warnCreateTime,
    required this.sessionIds,
  });

  factory WarnRecord.fromJson(Map<String, dynamic> json) {
    return WarnRecord(
      checkPointIndex: json['checkPointIndex'],
      warnCreateTime: json['warnCreateTime'],
      sessionIds: List<String>.from(json['sessionIds'].map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkPointIndex': checkPointIndex,
      'warnCreateTime': warnCreateTime,
      'sessionIds': sessionIds,
    };
  }
}
