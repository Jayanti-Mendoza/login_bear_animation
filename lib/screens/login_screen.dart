import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async'; // 3.1 Importar el timer

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
  SMIBool? _trigSuccess;
  SMIBool? _trigFail;

  // 3.2 Variable del recorrido de la mirada
  SMINumber? _numLook;

  // 3.3 Timer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  // 2.1 Crear las variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // 2.2 Listeners (Oyentes/chismosos)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        // Manos abajo y ACTIVAR el modo de revisar/mirar
        _isHandsUp?.change(false);
        _isChecking?.change(true); // ✅ Importante para que los ojos se muevan
        _numLook?.value = 50.0;
      } else {
        // Al quitar el foco del email, apagar la mirada atenta
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
      body: SafeArea(
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
                    // 1.2 Vincular animación
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );
                    if (_controller == null) return;
                    artboard.addController(_controller!);

                    // Vinculamos variables
                    _isChecking = _controller!.findSMI('isChecking');
                    _isHandsUp = _controller!.findSMI('isHandsUp');
                    _trigSuccess = _controller!.findSMI('trigSuccess');
                    _trigFail = _controller!.findSMI('trigFail');

                    // 3.5 Vincular numLook (si es nulo, prueba buscar 'Look')
                    _numLook =
                        _controller!.findSMI('numLook') ??
                        _controller!.findSMI('Look');
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Campo de texto para el email
              TextField(
                focusNode: _emailFocus,
                onChanged: (value) {
                  // Activar las manos abajo y la mirada atenta
                  _isHandsUp?.change(false);
                  _isChecking?.change(true); // ✅ Activa el seguimiento visual

                  // 3.6 Calcular y asignar la mirada (0 a 100)
                  final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                  _numLook?.value = look;

                  // 3.7 Debounce: al dejar de escribir, regresar a mirada neutra
                  _typingDebounce?.cancel();
                  _typingDebounce = Timer(const Duration(seconds: 3), () {
                    if (!mounted) return; // ✅ Corregido (!mounted)
                    _isChecking?.change(false); // Apagar modo chismoso
                  });
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Campo de texto para la contraseña
              TextField(
                focusNode: _passwordFocus,
                onChanged: (value) {
                  _isChecking?.change(false);
                  _isHandsUp?.change(true);
                },
                obscureText: _obscureText,
                decoration: InputDecoration(
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}
