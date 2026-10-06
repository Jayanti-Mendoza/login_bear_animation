import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  bool _rememberMe = false;

  // 1. BANDERA ANTI-SPAM: controla si la interacción está bloqueada
  bool _isAnimatingToggle = false;

  StateMachineController? _controller;
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  Timer? _typingDebunce;
  // Timer adicional para liberar el bloqueo si la animación es por tiempo definido
  Timer? _toggleLockTimer;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? emailError;
  String? passError;

  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  void _onLogin() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final eError = isValidEmail(email) ? null : 'Invalid email format';
    final pError = isValidPassword(pass) ? null : 'Invalid password';

    setState(() {
      emailError = eError;
      passError = pError;
    });

    FocusScope.of(context).unfocus();
    _typingDebunce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  void _updateLookPosition(String text) {
    _isChecking?.change(true);
    final look = (text.length / 80.0 * 100.0).clamp(0.0, 100.0);
    _numLook?.value = look;

    _typingDebunce?.cancel();
    _typingDebunce = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _isChecking?.change(false);
    });
  }

  // 2. LÓGICA DEL TOGGLE CON BLOQUEO ANTI-SPAM
  void _onToggleRememberMe(bool? value) {
    // Si ya está ejecutando la animación, ignoramos el toque por completo
    if (_isAnimatingToggle) return;

    setState(() {
      _isAnimatingToggle = true; // Bloqueamos la interfaz
      _rememberMe = value ?? false;
    });

    FocusScope.of(context).unfocus();
    _isHandsUp?.change(false);
    _isChecking?.change(true);
    _numLook?.value = 50.0;

    _typingDebunce?.cancel();
    _typingDebunce = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _isChecking?.change(false);
    });

    // Simulamos la duración de la animación (ajusta el tiempo al de tu animación)
    _toggleLockTimer?.cancel();
    _toggleLockTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _isAnimatingToggle = false; // Liberamos el bloqueo al terminar
      });
    });
  }

  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _isHandsUp?.change(false);
        _updateLookPosition(_emailCtrl.text);
      } else {
        _isChecking?.change(false);
      }
    });

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        _isChecking?.change(false);
        _isHandsUp?.change(_obscureText);
      } else {
        _isHandsUp?.change(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    stateMachines: const ['Login Machine'],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

                      if (_controller == null) return;
                      artboard.addController(_controller!);

                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  onChanged: (value) {
                    _isHandsUp?.change(false);
                    _updateLookPosition(value);
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    errorText: emailError,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _passCtrl,
                  focusNode: _passwordFocus,
                  onChanged: (value) {
                    _isChecking?.change(false);
                    if (_passwordFocus.hasFocus) {
                      _isHandsUp?.change(_obscureText);
                    }
                  },
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    errorText: passError,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                        if (_passwordFocus.hasFocus) {
                          _isHandsUp?.change(_obscureText);
                        }
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // Sección con Remember Me y Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 3. WIDGET ABSORBPOINTER: Absorbe los eventos táctiles mientras esté animando
                    AbsorbPointer(
                      absorbing: _isAnimatingToggle,
                      child: GestureDetector(
                        onTap: () => _onToggleRememberMe(!_rememberMe),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: Colors.pinkAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: _onToggleRememberMe,
                            ),
                            const Text('Remember me'),
                          ],
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  onPressed: _onLogin,
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.pinkAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebunce?.cancel();
    _toggleLockTimer?.cancel(); // Liberar la memoria del Timer del bloqueo
    _controller?.dispose();
    super.dispose();
  }
}
