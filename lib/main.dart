import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PokemonApp());
}

class PokemonApp extends StatelessWidget {
  const PokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon API',
      theme: ThemeData(
        primarySwatch: Colors.blue, 
        scaffoldBackgroundColor:
            Colors.white, 
      ),
      home: const PokemonList(),
    );
  }
}

class PokemonList extends StatefulWidget {
  const PokemonList({super.key});

  @override
  _PokemonListState createState() => _PokemonListState();
}

class _PokemonListState extends State<PokemonList> {
  List<Map<String, dynamic>> _pokemonList = [];
  List<Map<String, dynamic>> _filteredPokemonList = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ipSearchController = TextEditingController();
  String _ipInfo = '';

  @override
  void initState() {
    super.initState();
    fetchPokemon();
    _searchController.addListener(_filterPokemons);
  }

  Future<void> fetchPokemon() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        List<Map<String, dynamic>> pokemonWithImages = [];

        for (var pokemon in results) {
          final detailsResponse = await http.get(Uri.parse(pokemon['url']));
          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            pokemonWithImages.add({
              'name': pokemon['name'],
              'image': detailsData['sprites']['front_default'],
              'id': detailsData['id'],
              'height': detailsData['height'],
              'weight': detailsData['weight'],
              'abilities': detailsData['abilities']
                  .map((ability) => ability['ability']['name'])
                  .toList(),
            });
          }
        }

        setState(() {
          _pokemonList = pokemonWithImages;
          _filteredPokemonList = pokemonWithImages;
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar los Pokémon.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  void _filterPokemons() {
    setState(() {
      _filteredPokemonList = _pokemonList
          .where((pokemon) => pokemon['name']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _fetchIpInfo() async {
    final ip = _ipSearchController.text;
    const apiKey = '5bfa51c315854c6f8e968cc048c7fb6b';
    final url = Uri.parse('http://api.ipstack.com/$ip?access_key=$apiKey');

    setState(() {
      _ipInfo = 'Cargando...';
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ipInfo = '''
IP: ${data['ip']}
País: ${data['country_name']}
Ciudad: ${data['city']}
Código del país: ${data['country_code']}
Nombre del país: ${data['country_name']}
Código de la región: ${data['region_code']}
''';
        });
      } else {
        setState(() {
          _ipInfo = 'No se pudo obtener información para esta IP.';
        });
      }
    } catch (e) {
      setState(() {
        _ipInfo = 'Error al obtener la información de la IP.';
      });
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ipSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Filtrar por nombre',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: _filteredPokemonList.length,
                    itemBuilder: (context, index) {
                      final pokemon = _filteredPokemonList[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () => _showPokemonDetails(context, pokemon),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              pokemon['image'] != null
                                  ? Image.network(pokemon['image'], height: 80)
                                  : const Icon(Icons.image_not_supported),
                              const SizedBox(height: 10),
                              Text(
                                pokemon['name'].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _ipSearchController,
                    decoration: InputDecoration(
                      hintText: 'Ingresa la dirección IP',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _fetchIpInfo,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (_ipInfo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _ipInfo,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
    );
  }

  void _showPokemonDetails(BuildContext context, Map<String, dynamic> pokemon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(pokemon['name'].toUpperCase()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              pokemon['image'] != null
                  ? Image.network(pokemon['image'])
                  : const Icon(Icons.image_not_supported, size: 50),
              const SizedBox(height: 10),
              Text('ID: ${pokemon['id']}'),
              Text('Altura: ${pokemon['height']}'),
              Text('Peso: ${pokemon['weight']}'),
              Text('Habilidades: ${pokemon['abilities'].join(', ')}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
