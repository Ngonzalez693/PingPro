class SequenceStep {
  final int hit;
  final int rotation;
  final int zone;
  final int direction;
  final int side;

  SequenceStep({
    required this.hit,
    required this.rotation,
    required this.zone,
    required this.direction,
    required this.side,
  });

  factory SequenceStep.fromJson(Map<String, dynamic> json) {
    return SequenceStep(
      hit: json['hit'] as int,
      rotation: json['rotation'] as int,
      zone: json['zone'] as int,
      direction: json['direction'] as int,
      side: json['side'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'hit': hit,
    'rotation': rotation,
    'zone': zone,
    'direction': direction,
    'side': side,
  };
}