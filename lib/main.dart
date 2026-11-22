
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

const azul = Color(0xFF168BFF);
const fondo = Color(0xFF06152F);
const tarjeta = Color(0xFF102C50);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  runApp(const IostecClientesApp());
}

class IostecClientesApp extends StatelessWidget {
  const IostecClientesApp({super.key});

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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const RegistroPage();
        }
        return const PrincipalPage();
      },
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
  final codigo = TextEditingController();

  String? verificationId;
  bool cargando = false;

  @override
  void dispose() {
    nombre.dispose();
    apellido.dispose();
    telefono.dispose();
    codigo.dispose();
    super.dispose();
  }

  Future<void> enviarCodigo() async {
    if (nombre.text.trim().isEmpty ||
        apellido.text.trim().isEmpty ||
        telefono.text.trim().isEmpty) {
      mensaje('Completa nombre, apellido y teléfono.');
      return;
    }

    final numero = telefono.text.trim();
    if (!numero.startsWith('+')) {
      mensaje('Escribe el teléfono con código de país. Ejemplo: +595...');
      return;
    }

    setState(() => cargando = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: numero,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await ingresar(credential);
        },
        verificationFailed: (e) {
          mensaje('No se pudo enviar el SMS: ${e.message ?? e.code}');
        },
        codeSent: (id, token) {
          if (!mounted) return;
          setState(() {
            verificationId = id;
            cargando = false;
          });
          mensaje('Código enviado por SMS.');
        },
        codeAutoRetrievalTimeout: (id) {
          verificationId = id;
        },
      );
    } catch (e) {
      mensaje('Error: $e');
    }

    if (mounted) setState(() => cargando = false);
  }

  Future<void> verificarCodigo() async {
    if (verificationId == null || codigo.text.trim().length != 6) {
      mensaje('Introduce el código de 6 números.');
      return;
    }

    setState(() => cargando = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: codigo.text.trim(),
      );
      await ingresar(credential);
    } on FirebaseAuthException catch (e) {
      mensaje('Código incorrecto o vencido: ${e.message ?? e.code}');
    } catch (e) {
      mensaje('No se pudo verificar: $e');
    }

    if (mounted) setState(() => cargando = false);
  }

  Future<void> ingresar(PhoneAuthCredential credential) async {
    final result = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final user = result.user!;

    await FirebaseFirestore.instance
        .collection('iostec_clientes')
        .doc(user.uid)
        .set({
      'nombre': nombre.text.trim(),
      'apellido': apellido.text.trim(),
      'telefono': user.phoneNumber ?? telefono.text.trim(),
      'uid': user.uid,
      'actualizado': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    }
  }

  void mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
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
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
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
                    labelText: 'Teléfono con código de país',
                    hintText: '+595...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: cargando ? null : enviarCodigo,
                    child: Text(
                      cargando ? 'Enviando...' : 'ENVIAR CÓDIGO SMS',
                    ),
                  ),
                ),
                if (verificationId != null) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: codigo,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Código recibido por SMS',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: cargando ? null : verificarCodigo,
                      child: const Text('VERIFICAR Y ENTRAR'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Al continuar, verificaremos tu número de teléfono.',
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

  User get usuario => FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    final paginas = [
      ReparacionesPage(telefono: usuario.phoneNumber ?? ''),
      HistorialPage(telefono: usuario.phoneNumber ?? ''),
      const SoportePage(),
      const PerfilPage(),
    ];

    const titulos = [
      'Mis reparaciones',
      'Mi historial',
      'Soporte técnico',
      'Mi perfil',
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
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    }
  }
}

class ReparacionesPage extends StatelessWidget {
  final String telefono;
  const ReparacionesPage({super.key, required this.telefono});

  @override
  Widget build(BuildContext context) {
    return ListaReparaciones(
      telefono: telefono,
      historial: false,
    );
  }
}

class HistorialPage extends StatelessWidget {
  final String telefono;
  const HistorialPage({super.key, required this.telefono});

  @override
  Widget build(BuildContext context) {
    return ListaReparaciones(
      telefono: telefono,
      historial: true,
    );
  }
}

class ListaReparaciones extends StatelessWidget {
  final String telefono;
  final bool historial;

  const ListaReparaciones({
    super.key,
    required this.telefono,
    required this.historial,
  });

  bool finalizada(String estado) {
    final e = estado.toLowerCase();
    return e.contains('entregado') ||
        e.contains('completado') ||
        e.contains('finalizado');
  }

  @override
  Widget build(BuildContext context) {
    if (telefono.isEmpty) {
      return const Center(child: Text('Tu cuenta no tiene teléfono registrado.'));
    }

    final consulta = FirebaseFirestore.instance
        .collection('iostec_records')
        .where('type', isEqualTo: 'repair')
        .where('payload.phone', isEqualTo: telefono);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: consulta.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('No se pudieron cargar los registros.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data()['payload'] as Map<String, dynamic>? ?? {};
          final estado = (data['status'] ?? 'Recibido').toString();
          return historial ? finalizada(estado) : !finalizada(estado);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Text(
                historial
                    ? 'Todavía no tienes reparaciones finalizadas.'
                    : 'Todavía no tienes reparaciones registradas.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final data =
                doc.data()['payload'] as Map<String, dynamic>? ?? {};
            final estado = (data['status'] ?? 'Recibido').toString();

            return Card(
              color: tarjeta,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.phone_android, color: azul),
                title: Text(
                  (data['device'] ?? 'Celular').toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Falla: ${data['fault'] ?? 'No especificada'}\nEstado: $estado',
                ),
                isThreeLine: true,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class SoportePage extends StatelessWidget {
  const SoportePage({super.key});

  Future<void> abrirWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/595985913576');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent, size: 85, color: azul),
            const SizedBox(height: 20),
            const Text(
              'Soporte técnico IOSTEC',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Estamos para ayudarte con tus consultas y reparaciones.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => abrirWhatsApp(context),
                icon: const Icon(Icons.chat),
                label: const Text('CONTACTAR POR WHATSAPP'),
              ),
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
    final user = FirebaseAuth.instance.currentUser!;
    final referencia = FirebaseFirestore.instance
        .collection('iostec_clientes')
        .doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: referencia.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final datos = snapshot.data!.data() ?? {};
        final nombre = datos['nombre'] ?? '';
        final apellido = datos['apellido'] ?? '';

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
                Text(user.phoneNumber ?? 'Sin teléfono'),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: () => editarPerfil(
                    context,
                    referencia,
                    nombre.toString(),
                    apellido.toString(),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('EDITAR PERFIL'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> editarPerfil(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> referencia,
    String nombreActual,
    String apellidoActual,
  ) async {
    final nombre = TextEditingController(text: nombreActual);
    final apellido = TextEditingController(text: apellidoActual);

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: apellido,
              decoration: const InputDecoration(labelText: 'Apellido'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );

    if (guardar == true &&
        nombre.text.trim().isNotEmpty &&
        apellido.text.trim().isNotEmpty) {
      await referencia.set({
        'nombre': nombre.text.trim(),
        'apellido': apellido.text.trim(),
        'actualizado': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    nombre.dispose();
    apellido.dispose();
  }
}
