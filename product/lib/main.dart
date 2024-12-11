import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ntffubxxftdrtobsejta.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im50ZmZ1Ynh4ZnRkcnRvYnNlanRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE2OTcwODQsImV4cCI6MjA0NzI3MzA4NH0.uliXXU8Y7uEfrGAWWf3iBLfqsd25itIQuSIunUnYHhE',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Справочник Продуктов',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      routes: {
        '/favorites': (context) => FavoritesPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> products = [];
  List<dynamic> categories = [];
  List<dynamic> filteredProducts = [];
  List<int> favoriteIds = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchFavorites();
    fetchProducts();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  // Получение категорий
  Future<void> fetchCategories() async {
    try {
      final response = await supabase.from('categories').select();
      setState(() {
        categories = response;
      });
    } catch (error) {
      print('Ошибка при получении категорий: $error');
    }
  }

  // Получение избранных продуктов
  Future<void> fetchFavorites() async {
    try {
      final response = await supabase
          .from('favorites')
          .select('product_id')
          .eq('user_id', '1111aaaa-aa11-11aa-1a1a-111111aaaaaa');

      setState(() {
        favoriteIds =
            List<int>.from(response.map((item) => item['product_id']));
      });
    } catch (error) {
      print('Ошибка при получении избранного: $error');
    }
  }

  // Получение продуктов
  Future<void> fetchProducts() async {
    try {
      final response = await supabase.from('products').select();
      setState(() {
        products = response;
        filteredProducts = products;
      });
    } catch (error) {
      print('Ошибка при получении продуктов: $error');
    }
  }

  // Обработка поиска
  void _onSearchChanged() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((product) {
        String name = product['name'].toString().toLowerCase();
        String category = categories
            .firstWhere((cat) => cat['id'] == product['category'],
                orElse: () => {'name': ''})['name']
            .toString()
            .toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
    });
  }

  // Добавление в избранное
  Future<void> toggleFavoriteFromMain(int productId) async {
    bool isCurrentlyFavorite =
        favoriteIds.contains(productId); // Текущее состояние

    setState(() {
      if (isCurrentlyFavorite) {
        favoriteIds.remove(productId);
      } else {
        favoriteIds.add(productId);
      }
    });

    try {
      if (isCurrentlyFavorite) {
        // Удаление из избранного
        // ignore: unused_local_variable
        final response = await supabase
            .from('favorites')
            .delete()
            .eq('user_id', '1111aaaa-aa11-11aa-1a1a-111111aaaaaa')
            .eq('product_id', productId);
      } else {
        // Добавление в избранное
        // ignore: unused_local_variable
        final response = await supabase.from('favorites').insert([
          {
            'user_id': '1111aaaa-aa11-11aa-1a1a-111111aaaaaa',
            'product_id': productId,
          }
        ]);
      }
    } catch (error) {
      setState(() {
        if (isCurrentlyFavorite) {
          favoriteIds.add(productId);
        } else {
          favoriteIds.remove(productId);
        }
      });
    }
  }

// удаление из избранного

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Справочник Продуктов'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites').then((_) {
                fetchFavorites();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по продуктам или категориям',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          // Список продуктов
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(child: Text('Нет продуктов'))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final category = categories.firstWhere(
                          (cat) => cat['id'] == product['category'],
                          orElse: () => {'name': 'Неизвестно'})['name'];
                      final isFavorite = favoriteIds.contains(product['id']);
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: product['image_url'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                          title: Text(product['name']),
                          subtitle: Text(category),
                          trailing: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey[600],
                            ),
                            onPressed: () {
                              toggleFavoriteFromMain(product['id']);
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailPage(product: product),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final dynamic product;

  ProductDetailPage({required this.product});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name']),
      ),
      body: FutureBuilder(
        future: supabase
            .from('categories')
            .select()
            .eq('id', product['category'])
            .single(),
        builder: (context, snapshot) {
          // ignore: unused_local_variable
          String category = '';
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            }
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Изображение продукта
                  CachedNetworkImage(
                    imageUrl: product['image_url'] ?? '',
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.error, size: 100),
                  ),
                  SizedBox(height: 20),

                  Text(
                    product['name'],
                    style:
                        TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 20),

                  Text(
                    'Калорийность: ${product['calories']} ккал/100г',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    'Белки: ${product['proteins']} г',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    'Жиры: ${product['fats']} г',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Text(
                    'Углеводы: ${product['carbohydrates']} г',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  SizedBox(height: 20),

                  Text(
                    'Описание',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product['description'] ?? 'Нет описания.',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  SizedBox(height: 20),

                  Text(
                    'Вред и противопоказания',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product['health_info'] ?? 'Нет информации.',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> favoriteProducts = [];

  @override
  void initState() {
    super.initState();
    fetchFavoriteProducts();
  }

  Future<void> fetchFavoriteProducts() async {
    try {
      final response = await supabase
          .from('favorites')
          .select('product_id, products(*)')
          .eq('user_id', '1111aaaa-aa11-11aa-1a1a-111111aaaaaa');

      if (response.isNotEmpty) {
        setState(() {
          favoriteProducts = response;
        });
      } else {
        print('Нет избранных продуктов');
      }
    } catch (error) {
      print('Ошибка при получении избранных продуктов: $error');
    }
  }

  // Удаление из избранного
  Future<void> removeFavoriteFromList(int productId) async {
    try {
      setState(() {
        favoriteProducts.removeWhere((item) => item['product_id'] == productId);
      });

      // Удаление из базы данных
      final response = await supabase
          .from('favorites')
          .delete()
          .eq('user_id', '1111aaaa-aa11-11aa-1a1a-111111aaaaaa')
          .eq('product_id', productId);

      if (response == null || response.isEmpty) {
        print('Successfull');

        setState(() {});
      }
    } catch (error) {
      print('Ошибка в removeFavoriteFromList: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Избранное'),
        ),
        body: favoriteProducts.isEmpty
            ? Center(child: Text('Нет избранных продуктов'))
            : ListView.builder(
                itemCount: favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = favoriteProducts[index]['products'];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 4,
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: product['image_url'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                      ),
                      title: Text(product['name']),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          removeFavoriteFromList(product['id']);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailPage(product: product),
                          ),
                        ).then((_) {
                          fetchFavoriteProducts();
                        });
                      },
                    ),
                  );
                },
              ));
  }
}
