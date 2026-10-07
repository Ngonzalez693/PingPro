// Duración de las transiciones decorativas.
//
// Con animaciones reducidas (ajuste del sistema o "Reducir animaciones", que
// ReduceMotionScope suma en MediaQuery) el cambio es instantáneo: los
// AnimatedSwitcher, AnimatedScale o TweenAnimationBuilder con Duration.zero
// saltan directo al estado final.
import 'package:flutter/widgets.dart';

Duration motionDuration(BuildContext context, Duration normal) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : normal;
