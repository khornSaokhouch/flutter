import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/utils/message_utils.dart';
import '../../core/utils/utils.dart';
import '../../models/user.dart';
import '../../server/auth_service.dart';
import '../user/layout.dart';

class PhoneAuthPage extends StatefulWidget {
  final String phoneNumber;
  final String? verificationId;
  final String? name;
  final String? password;

  const PhoneAuthPage({
    super.key,
    required this.phoneNumber,
    this.verificationId,
    this.name,
    this.password,
  });

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _verificationId;

  Timer? _resendTimer;
  int _startResendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _phoneController.text = widget.phoneNumber;

    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.isNotEmpty &&
            i < _otpControllers.length - 1) {
          _otpFocusNodes[i + 1].requestFocus();
        }
      });
    }

    if (_verificationId == null) sendOtp(widget.phoneNumber);
    _startResendTimerCountdown();
  }

  @override
  void dispose() {
    for (var c in _otpControllers) c.dispose();
    for (var node in _otpFocusNodes) node.dispose();
    _phoneController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimerCountdown() {
    _startResendTimer = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer =
        Timer.periodic(const Duration(seconds: 1), (Timer timer) {
          if (!mounted) return;
          if (_startResendTimer == 0) {
            setState(() {
              _canResend = true;
              timer.cancel();
            });
          } else {
            setState(() => _startResendTimer--);
          }
        });
  }

  Future<void> sendOtp(String phoneNumber) async {
    setState(() => _isLoading = true);
    for (var c in _otpControllers) c.clear();
    _otpFocusNodes[0].requestFocus();

    await _auth.verifyPhoneNumber(
      phoneNumber: formatPhoneNumber(phoneNumber),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
          final user = _auth.currentUser;
          if (user != null) {
            final idToken = await user.getIdToken();
            final userModel = await _handleFirebaseSignIn(idToken!);
            if (userModel?.user != null) {
              _navigateToLayout(userModel!);
            }
          }
        } catch (e) {
          showMessage(context, 'Auto verification failed: $e');
        }
      },
      verificationFailed: (e) {
        setState(() => _isLoading = false);
        showMessage(context, 'Verification failed: ${e.message}');
      },
      codeSent: (verificationId, _) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
          _startResendTimerCountdown();
        });
        showMessage(context, '✅ OTP sent successfully');
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifyOtp() async {
    if (_verificationId == null) {
      showMessage(context, 'Please request OTP first');
      return;
    }

    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.length != 6) {
      showMessage(context, 'Please enter the full 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      await _auth.signInWithCredential(credential);
      final user = _auth.currentUser;

      if (user != null) {
        final idToken = await user.getIdToken();
        final userModel = await _handleFirebaseSignIn(idToken!);
        if (userModel?.user != null) {
          _navigateToLayout(userModel!);
        }
      } else {
        showMessage(context, '⚠️ No authenticated user found.');
      }
    } on FirebaseAuthException catch (e) {
      showMessage(context, 'Sign-in failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<UserModel?> _handleFirebaseSignIn(String idToken) async {
    final formattedPhone = formatPhoneNumber(_phoneController.text);
    try {
      final response = await AuthService.registerWithFirebase(
        name: widget.name ?? 'No Name',
        phone: formattedPhone,
        password: widget.password ?? 'password123',
        passwordConfirmation: widget.password ?? 'password123',
        idToken: idToken,
      );

      if (response != null) {
        if (response.needsPhone == true) {
          showMessage(context,
              '⚠️ Phone verification required. Please verify your phone.');
          return null;
        } else if (response.user != null) {
          showMessage(
              context, '✅ Registration/Login successful: ${response.user!.name}');
          return response;
        }
      }

      showMessage(context, '❌ Registration/Login failed on backend.');
      return null;
    } catch (e) {
      showMessage(context, '❌ Error sending token to backend: $e');
      return null;
    }
  }

  void _navigateToLayout(UserModel userModel) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => Layout(userId: userModel.user!.id!)),
          (route) => false,
    );
  }

  Widget _otpInputField(int index) {
    final theme = Theme.of(context);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _otpFocusNodes[index].hasFocus
              ? theme.colorScheme.secondary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge,
        decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          } else if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verification code',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 28)),
            const SizedBox(height: 10),
            Text('We sent the code to ${_phoneController.text}',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
              List.generate(_otpControllers.length, (index) => _otpInputField(index)),
            ),
            const SizedBox(height: 20),
            Center(
              child: _canResend
                  ? GestureDetector(
                onTap: _isLoading ? null : () => sendOtp(widget.phoneNumber),
                child: Text(
                  'Resend code',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : Text(
                'Resend code after 0:${_startResendTimer.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Confirm', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
