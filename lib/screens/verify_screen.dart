import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../bloc/auth_cubit.dart';
import '../core/localization/app_localizations.dart';
import '../utils/responsive.dart';

class VerifyScreen extends StatefulWidget {
  final String phone;
  final bool isSignup;
  const VerifyScreen({Key? key, required this.phone, this.isSignup = false}) : super(key: key);

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  static const int _otpLength = 6;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (index) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (index) => FocusNode());
  late Timer _timer;
  int _start = 45;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verify() {
    FocusScope.of(context).unfocus();
    final code = _controllers.map((e) => e.text).join();
    context.read<AuthCubit>().verifyCode(code.trim());
  }

  void _resend() {
    if (_start == 0) {
      setState(() {
        _start = 45;
      });
      _startTimer();
      context.read<AuthCubit>().submitPhone(widget.phone, isSignup: widget.isSignup);
    }
  }

  Future<bool> _onWillPop() async {
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().backToPhone();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final responsive = context.responsive;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        body: SafeArea(
          child: Padding(
            padding:
                responsive.scaledSymmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    size: responsive.scale(22),
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    context.read<AuthCubit>().backToPhone();
                  },
                ),
                SizedBox(height: responsive.scale(16)),
                Text(
                  l.verifyNumberTitle,
                  style: TextStyle(
                    fontSize: responsive.scaleText(26),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: responsive.scale(8)),
                Text(
                  l.verifyCodeDescription,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: responsive.scaleText(15),
                  ),
                ),
                SizedBox(height: responsive.scale(30)),
                Text(
                  l.enterCodeLabel,
                  style: TextStyle(
                    fontSize: responsive.scaleText(16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: responsive.scale(12)),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final spacing = availableWidth < 320
                        ? responsive.scale(6)
                        : responsive.scale(10);
                    final fieldHeight = availableWidth < 320
                        ? responsive.scale(52)
                        : responsive.scale(58);
                    return Row(
                      children: [
                        for (var index = 0; index < _otpLength; index++) ...[
                          Expanded(
                            child: SizedBox(
                              height: fieldHeight,
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.scale(12),
                                    ),
                                    borderSide:
                                        const BorderSide(color: Colors.transparent),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      responsive.scale(12),
                                    ),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                ),
                                onChanged: (value) {
                                  final trimmedValue = value.trim();
                                  if (trimmedValue.length > 1) {
                                    final digits = trimmedValue.replaceAll(
                                      RegExp(r'[^0-9]'),
                                      '',
                                    );
                                    if (digits.isEmpty) {
                                      _controllers[index].clear();
                                      return;
                                    }
                                    for (var i = 0; i < digits.length; i++) {
                                      final targetIndex = index + i;
                                      if (targetIndex >= _otpLength) break;
                                      _controllers[targetIndex].text = digits[i];
                                    }
                                    final nextIndex = index + digits.length;
                                    if (nextIndex < _otpLength) {
                                      _focusNodes[nextIndex].requestFocus();
                                    } else {
                                      FocusScope.of(context).unfocus();
                                    }
                                    return;
                                  }

                                  if (trimmedValue.isNotEmpty) {
                                    if (index < _otpLength - 1) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else {
                                      FocusScope.of(context).unfocus();
                                    }
                                  } else if (trimmedValue.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                },
                              ),
                            ),
                          ),
                          if (index != _otpLength - 1)
                            SizedBox(width: spacing),
                        ],
                      ],
                    );
                  },
                ),
                SizedBox(height: responsive.scale(40)),
                SizedBox(
                  width: double.infinity,
                  height: responsive.scale(55),
                  child: ElevatedButton(
                    onPressed: _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(responsive.scale(30)),
                      ),
                    ),
                    child: Text(
                      l.verifyOtpButton,
                      style: TextStyle(
                        fontSize: responsive.scaleText(18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.scale(20)),
                Center(
                  child: TextButton(
                    onPressed: _resend,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF007BFF),
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: responsive.scaleText(15),
                        ),
                        children: [
                          TextSpan(
                            text: '${l.resendPromptQuestion} ',
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: _start > 0
                                ? l.resendCountdown(_start)
                                : l.resendCode,
                            style: const TextStyle(
                              color: Color(0xFF007BFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
