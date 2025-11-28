import 'dart:convert';
import 'dart:typed_data'; // Necesario para manejar bytes en Web
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// CONFIGURACIÓN PARA(LOCALHOST)
const String baseUrl = "http://127.0.0.1:8000"; 

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Paquexpress Web',
      home: const LoginPage(),
    );
  }
}

//LOGIN
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  Future<void> login() async {
    try {
      var url = Uri.parse("$baseUrl/login/");
      var response = await http.post(url, 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": _userController.text, "password": _passController.text})
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PackageListPage(agentId: data['user_id'])));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error de acceso")));
      }
    } catch (e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Agente")),
      body: Center( // Centrado para que se vea mejor
        child: Container(
          width: 400, // Limitamos ancho para que no se estire en monitores
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            TextField(controller: _userController, decoration: const InputDecoration(labelText: "Usuario")),
            TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Contraseña")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: const Text("Entrar"))
          ]),
        ),
      ),
    );
  }
}

//LISTA Y MAPA
class PackageListPage extends StatefulWidget {
  final int agentId;
  const PackageListPage({super.key, required this.agentId});
  @override
  _PackageListPageState createState() => _PackageListPageState();
}

class _PackageListPageState extends State<PackageListPage> {
  List packages = [];

  @override
  void initState() {
    super.initState();
    loadPackages();
  }

  Future<void> loadPackages() async {
    try {
      var res = await http.get(Uri.parse("$baseUrl/paquetes/${widget.agentId}"));
      if (res.statusCode == 200) setState(() => packages = jsonDecode(res.body));
    } catch (e) {
      print("Error cargando paquetes: $e");
    }
  }

  Future<void> entregar(int id) async {
    final ImagePicker picker = ImagePicker();
    // En Web, pickImage abre el selector de archivos del navegador
    final XFile? photo = await picker.pickImage(source: ImageSource.camera); 
    
    if (photo != null) {
      var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/entregar/"));
      request.fields['paquete_id'] = id.toString();

      Uint8List data = await photo.readAsBytes();
      List<int> list = data.cast();
      request.files.add(http.MultipartFile.fromBytes('file', list, filename: 'entrega.jpg'));
      // ----------------------------------

      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Entrega registrada")));
        loadPackages(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al subir")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Paquetes")),
      body: packages.isEmpty 
        ? const Center(child: Text("No hay paquetes asignados"))
        : ListView.builder(
            itemCount: packages.length,
            itemBuilder: (ctx, i) {
              var p = packages[i];
              // Convertimos a double seguro
              double lat = double.parse(p['latitud_destino'].toString());
              double lng = double.parse(p['longitud_destino'].toString());

              return Card(
                margin: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.local_shipping, color: p['estado'] == 'entregado' ? Colors.green : Colors.orange),
                      title: Text("Guía: ${p['tracking_number']}"),
                      subtitle: Text("${p['direccion_destino']} (${p['estado']})"),
                    ),
                    SizedBox(
                      height: 300,
                      child: FlutterMap( 
                        options: MapOptions(
                          initialCenter: LatLng(lat, lng), 
                          initialZoom: 15.0, 
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.paquexpress.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat, lng), 
                                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                              )
                            ]
                          )
                        ],
                      ),
                    ),
                    if (p['estado'] == 'pendiente')
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: () => entregar(p['id']), 
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("📸 Subir Evidencia"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
    );
  }
}