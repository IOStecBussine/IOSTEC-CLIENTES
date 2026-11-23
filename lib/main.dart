
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const azul = Color(0xFF168BFF);
const fondo = Color(0xFF06152F);
const tarjeta = Color(0xFF102C50);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(IostecClientesApp(
    registrado: prefs.getBool('cuenta_creada') ?? false,
  ));
}

class IostecClientesApp extends StatelessWidget {
  final bool registrado;
  const IostecClientesApp({super.key, required this.registrado});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IOSTEC CLIENTES',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: fondo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: azul,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: registrado ? const PrincipalPage() : const RegistroPage(),
    );
  }
}

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final nombre = TextEditingController();
  final apellido = TextEditingController();
  final telefono = TextEditingController();
  bool cargando = false;

  @override
  void dispose() {
    nombre.dispose();
    apellido.dispose();
    telefono.dispose();
    super.dispose();
  }

  Future<void> registrar() async {
    if (nombre.text.trim().isEmpty ||
        apellido.text.trim().isEmpty ||
        telefono.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos.')),
      );
      return;
    }

    setState(() => cargando = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cliente_nombre', nombre.text.trim());
    await prefs.setString('cliente_apellido', apellido.text.trim());
    await prefs.setString('cliente_telefono', telefono.text.trim());
    await prefs.setBool('cuenta_creada', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PrincipalPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.phone_iphone, size: 85, color: azul),
                const SizedBox(height: 15),
                const Text(
                  'IOSTEC CLIENTES',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu celular siempre en buenas manos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: apellido,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefono,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: '+595...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: cargando ? null : registrar,
                    child: Text(
                      cargando ? 'Registrando...' : 'CREAR MI CUENTA',
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Registro sencillo y gratuito. No necesitas código SMS.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  int pagina = 0;

  final titulos = [
    'Mis reparaciones',
    'Mi historial',
    'Soporte técnico',
    'Mi perfil',
  ];

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const InfoPage(
        icono: Icons.build,
        titulo: 'Mis reparaciones',
        mensaje: 'Aquí aparecerán tus reparaciones.',
      ),
      const InfoPage(
        icono: Icons.history,
        titulo: 'Mi historial',
        mensaje: 'Aquí aparecerá tu historial de reparaciones.',
      ),
      const SoportePage(),
      const PerfilPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titulos[pagina],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: SafeArea(child: paginas[pagina]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: pagina,
        onDestinationSelected: (i) => setState(() => pagina = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            label: 'Reparaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent),
            label: 'Soporte',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Future<void> cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres salir de tu cuenta IOSTEC?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SALIR'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cuenta_creada', false);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RegistroPage()),
        (_) => false,
      );
    }
  }
}

class InfoPage extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;

  const InfoPage({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 85, color: azul),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class SoportePage extends StatelessWidget {
  const SoportePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.support_agent, size: 85, color: azul),
            SizedBox(height: 20),
            Text(
              'Soporte técnico IOSTEC',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Estamos para ayudarte con tus consultas y reparaciones.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final prefs = snapshot.data!;
        final nombre = prefs.getString('cliente_nombre') ?? '';
        final apellido = prefs.getString('cliente_apellido') ?? '';
        final telefono = prefs.getString('cliente_telefono') ?? '';

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 90, color: azul),
                const SizedBox(height: 15),
                Text(
                  '$nombre $apellido',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(telefono),
              ],
            ),
          ),
        );
      },
    );
  }
}
