import 'package:firebase_auth/firebase_auth.dart';

abstract class FirebaseAuthGateway {
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String idToken) onAutoVerified,
    required void Function(String code, String message) onVerificationFailed,
  });

  Future<String> confirmCode({
    required String verificationId,
    required String smsCode,
  });
}

class FirebaseAuthGatewayImpl implements FirebaseAuthGateway {
  final FirebaseAuth _auth;
  const FirebaseAuthGatewayImpl(this._auth);

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String idToken) onAutoVerified,
    required void Function(String code, String message) onVerificationFailed,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        final idToken = await _signInAndGetIdToken(credential);
        onAutoVerified(idToken);
      },
      verificationFailed: (e) => onVerificationFailed(e.code, e.message ?? ''),
      codeSent: (verificationId, forceResendingToken) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<String> confirmCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    return _signInAndGetIdToken(credential);
  }

  Future<String> _signInAndGetIdToken(PhoneAuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    // Sem user/token após signIn é estado interno inesperado do Firebase —
    // vira FirebaseAuthException tipada em vez de crash de null-assert (C9).
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'internal-error',
        message: 'Sign-in returned no user or no idToken.',
      );
    }
    return idToken;
  }
}
