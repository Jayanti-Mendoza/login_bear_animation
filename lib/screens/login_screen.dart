import 'dart:async'; // 3.1 Importar el timer

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;

  // 1.1 Crear cerebro de la animación
  StateMachineController? _controller;
  // SMI: StateMachineInput / Entrada de máquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;

  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  // 3.2 Variable del recorrido de la mirada
  SMINumber? _numLook;

  // 3.3 Timer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  // 2.1 Crear las variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  // 4.1 Controllers que manipulan lo que el usuario escribe
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // 4.2 Errores para mostrar en la UI
  String? _emailError;
  String? _passError;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  // Password:
  bool isValidPassword(String pass) {
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  // 4.4 Dar acción al botón
  void _onLogin() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final eError = isValidEmail(email) ? null : 'Invalid email';
    final pError = isValidPassword(pass) ? null : 'Invalid password';

    setState(() {
      _emailError = eError;
      _passError = pError;
    });

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();

    // Desactivar estados de mirada y manos
    _isChecking?.value = false;
    _isHandsUp?.value = false;
    _numLook?.value = 50.0;

    // 4.9 Activar triggers
    if (eError == null && pError == null) {
      debugPrint('Disparando Success');
      _trigSuccess?.fire();
    } else {
      debugPrint('Disparando Fail. Valor de _trigFail: $_trigFail');
      if (_trigFail != null) {
        _trigFail!.fire();
      } else {
        debugPrint(
          '⚠️ _trigFail es NULO. Revisa el nombre del input en el .riv',
        );
      }
    }
  }

  // 2.2 Listeners (Oyentes/chismosos)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _isHandsUp?.change(false);
        _isChecking?.change(true);
        _numLook?.value = 50.0;
      } else {
        _isChecking?.change(false);
      }
    });

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        _isChecking?.change(false);
      }
      _isHandsUp?.change(_passwordFocus.hasFocus);
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

                      // Imprimir todos los inputs disponibles para verificar sus nombres
                      for (var input in _controller!.inputs) {
                        debugPrint(
                          'Input encontrado en Rive: ${input.name} (${input.runtimeType})',
                        );
                      }

                      // Vinculación intentando nombres alternativos si no encuentra el exacto
                      _isChecking =
                          _controller!.findSMI('isChecking') ??
                          _controller!.findSMI('Check');
                      _isHandsUp =
                          _controller!.findSMI('isHandsUp') ??
                          _controller!.findSMI('hands_up');

                      _trigSuccess =
                          _controller!.findSMI('trigSuccess') ??
                          _controller!.findSMI('success');
                      _trigFail =
                          _controller!.findSMI('trigFail') ??
                          _controller!.findSMI('fail');

                      _numLook =
                          _controller!.findSMI('numLook') ??
                          _controller!.findSMI('Look');
                    },
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  onChanged: (value) {
                    _isHandsUp?.change(false);
                    _isChecking?.change(true);

                    final look = (value.length / 80.0 * 100.0).clamp(
                      0.0,
                      100.0,
                    );
                    _numLook?.value = look;

                    _typingDebounce?.cancel();
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      if (!mounted) return;
                      _isChecking?.change(false);
                    });
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    errorText: _emailError,
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
                    _isHandsUp?.change(true);
                  },
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    errorText: _passError,
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
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: size.width,
                  child: const Text(
                    'Forgot Password?',
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 10),

                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                          'Sign up',
                          style: TextStyle(
                            color: Colors.black,
                            decoration: TextDecoration.underline,
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
    _typingDebounce?.cancel();
    super.dispose();
  }
}
