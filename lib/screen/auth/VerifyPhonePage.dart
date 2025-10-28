import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../../config/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/utils.dart';
import '../user/layout.dart';

class VerifyPhonePage extends StatefulWidget {
  final String tempToken;
  const VerifyPhonePage({Key? key, required this.tempToken}) : super(key: key);

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  final TextEditingController _phoneController = TextEditingController();
  String? _verificationId;
  bool _otpSent = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<TextEditingController> _otpDigitControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  /// Send OTP via Firebase
  Future<void> sendOtp() async {
    final phone = formatPhoneNumber(_phoneController.text.trim());
    if (phone.isEmpty) {
      _showSnackBar('Please enter a phone number.');
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          await _handleVerifiedUser(userCredential, phone);
        } catch (e) {
          if (mounted) _showSnackBar('Auto verification failed: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        _showSnackBar('Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
        _showSnackBar('OTP sent to your phone');
        _otpFocusNodes[0].requestFocus();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Verify OTP manually
  Future<void> verifyOtp() async {
    final otp = _otpDigitControllers.map((c) => c.text).join();

    if (otp.length != 6 || _verificationId == null) {
      _showSnackBar('Please enter the 6-digit OTP.');
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: otp);
      final userCredential = await _auth.signInWithCredential(credential);
      final phone = formatPhoneNumber(_phoneController.text.trim());
      await _handleVerifiedUser(userCredential, phone);
    } catch (e) {
      if (mounted) _showSnackBar('OTP verification error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifiedUser(UserCredential userCredential, String phone) async {
    final firebaseUid = userCredential.user!.uid;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/update-phone'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'tempToken': widget.tempToken,
          'phone': phone,
          'firebaseUid': firebaseUid,
        }),
      );

      final data = json.decode(response.body);

      if (data['ok'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (data['token'] != null) await prefs.setString('token', data['token']);

        final int userId = data['user']['id'];
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Layout(userId: userId)),
        );
      } else {
        _showSnackBar('Phone verification failed: ${data['error']}');
      }
    } catch (e) {
      _showSnackBar('Server error: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var c in _otpDigitControllers) c.dispose();
    for (var n in _otpFocusNodes) n.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Phone', style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [theme.scaffoldBackgroundColor, theme.colorScheme.surface]
                : [theme.scaffoldBackgroundColor, theme.colorScheme.surface],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _otpSent ? 'Enter OTP' : 'Verify Your Phone Number',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.primaryColor,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!_otpSent)
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: theme.colorScheme.onBackground),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+85512345678',
                          labelStyle: TextStyle(color: theme.primaryColor.withOpacity(0.8)),
                          hintStyle: TextStyle(color: theme.colorScheme.onBackground.withOpacity(0.6)),
                          prefixIcon: Icon(Icons.phone, color: theme.colorScheme.secondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                        ),
                      ),
                    if (_otpSent) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Enter the 6-digit code sent to your phone',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                              (index) => _buildOtpDigitBox(index, theme, isDarkMode),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    _isLoading
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.secondary),
                    )
                        : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _otpSent ? verifyOtp : sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        child: Text(
                          _otpSent ? 'Verify OTP' : 'Send OTP',
                          style: TextStyle(fontSize: 18, color: theme.colorScheme.onPrimary),
                        ),
                      ),
                    ),
                    if (_otpSent) ...[
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _otpSent = false;
                            for (var c in _otpDigitControllers) c.clear();
                          });
                        },
                        child: Text(
                          'Change Phone Number?',
                          style: TextStyle(color: theme.primaryColor.withOpacity(0.8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpDigitBox(int index, ThemeData theme, bool isDarkMode) {
    return SizedBox(
      width: 45,
      height: 50,
      child: TextFormField(
        controller: _otpDigitControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onBackground, fontSize: 20),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.secondary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.5), width: 1),
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) _otpFocusNodes[index + 1].requestFocus();
            else {
              _otpFocusNodes[index].unfocus();
              verifyOtp(); // auto verify
            }
          } else if (index > 0 && _otpDigitControllers[index].text.isEmpty) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
