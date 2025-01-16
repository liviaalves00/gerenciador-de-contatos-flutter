import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Database _database;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'contatos.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE contatos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            email TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getContatos() async {
    return await _database.query('contatos');
  }

  Future<void> _addContato(String nome, String email) async {
    await _database.insert('contatos', {'nome': nome, 'email': email});
    setState(() {});
  }

  Future<void> _editContato(int id, String nome, String email) async {
    await _database.update(
      'contatos',
      {'nome': nome, 'email': email},
      where: 'id = ?',
      whereArgs: [id],
    );
    setState(() {});
  }

  Future<void> _deleteContato(int id) async {
    await _database.delete(
      'contatos',
      where: 'id = ?',
      whereArgs: [id],
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Gerenciador de Contatos',
            style: TextStyle(color: Colors.white),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Listar'),
              Tab(text: 'Criar'),
              Tab(text: 'Editar/Excluir'),
            ],
            labelStyle: TextStyle(color: Colors.white),
            unselectedLabelStyle: TextStyle(color: Colors.grey),
          ), // 48 88 140,
          // backgroundColor: Colors.lightBlue,
          backgroundColor: Color.fromARGB(255, 48, 88, 140),
        ),
        body: TabBarView(
          children: [
            // Aba Listar
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getContatos(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Nenhum contato encontrado.'));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final contato = snapshot.data![index];
                    return ListTile(
                      title: Text(contato['nome']),
                      subtitle: Text(contato['email']),
                    );
                  },
                );
              },
            ),

            // Aba Criar
            CreateContatoTab(onAddContato: _addContato),

            // Aba Editar/Excluir
            EditDeleteContatoTab(
              getContatos: _getContatos,
              onEditContato: _editContato,
              onDeleteContato: _deleteContato,
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 166, 63, 138),
      ),
    );
  }
}

class CreateContatoTab extends StatefulWidget {
  final Function(String, String) onAddContato;

  const CreateContatoTab({required this.onAddContato, super.key});

  @override
  State<CreateContatoTab> createState() => _CreateContatoTabState();
}

class _CreateContatoTabState extends State<CreateContatoTab> {
  final _formKey = GlobalKey<FormState>();
  String _nome = '';
  String _email = '';

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onAddContato(_nome, _email);
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text('Contato adicionado!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white), // Linha inativa
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Linha ativa
                  )),
              style: const TextStyle(color: Colors.white),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Digite o nome' : null,
              onSaved: (value) => _nome = value!,
            ),
            TextFormField(
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white), // Linha inativa
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // Linha ativa
                  )),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Digite o email' : null,
              onSaved: (value) => _email = value!,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text(
                'Adicionar',
                style: TextStyle(color: Colors.white),
              ),
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.lightBlue),
                // overlayColor: WidgetStateProperty.all(Color.fromARGB(1, 113, 255, 12)),

                backgroundColor:
                    WidgetStateProperty.all(Color.fromARGB(255, 115, 41, 89)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 166 63 138
class EditDeleteContatoTab extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() getContatos;
  final Function(int, String, String) onEditContato;
  final Function(int) onDeleteContato;

  const EditDeleteContatoTab({
    required this.getContatos,
    required this.onEditContato,
    required this.onDeleteContato,
    super.key,
  });

  @override
  State<EditDeleteContatoTab> createState() => _EditDeleteContatoTabState();
}

class _EditDeleteContatoTabState extends State<EditDeleteContatoTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.getContatos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum contato encontrado.'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final contato = snapshot.data![index];
            final nomeController = TextEditingController(text: contato['nome']);
            final emailController =
                TextEditingController(text: contato['email']);

            return ListTile(
              title: TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              subtitle: TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      widget.onEditContato(
                        contato['id'],
                        nomeController.text,
                        emailController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contato atualizado!')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      widget.onDeleteContato(contato['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contato excluído!')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
