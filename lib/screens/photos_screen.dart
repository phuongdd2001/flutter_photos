import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_photos/blocs/blocs.dart';
import 'package:flutter_photos/widgets/widgets.dart';

class PhotosScreen extends StatefulWidget {
  @override
  _PhotosScreenState createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  late ScrollController _scrollController;
  final TextEditingController text = TextEditingController();
  int order = -1;


  List<String> orders = [
    "Conan",
    "Naruto",
    "One piece",
    "Batman",
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.offset ==
                _scrollController.position.maxScrollExtent &&
            context.read<PhotosBloc>().state.status !=
                PhotosStatus.paginating) {
          context.read<PhotosBloc>().add(PhotosPaginate());
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Photos'),
        ),
        body: BlocConsumer<PhotosBloc, PhotosState>(
          listener: (context, state) {
            if (state.status == PhotosStatus.paginating) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('Loading more photos...'),
                  duration: Duration(seconds: 1),
                ),
              );
            } else if (state.status == PhotosStatus.noMorePhotos) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('No more photos.'),
                  duration: Duration(milliseconds: 1500),
                ),
              );
            } else if (state.status == PhotosStatus.error) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Search Error'),
                  content: Text(state.failure!.message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            }
          },
          builder: (context, state) {
            return Container(
              padding: EdgeInsets.all(8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      TextField(
                        controller: text,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          fillColor: Colors.white,
                          filled: true,
                          suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.search,
                                size: 20,
                                color: Color.fromARGB(255, 228, 228, 228),
                              ),
                              onPressed: () {
                                if (text.text.trim() != '') {
                                  context.read<PhotosBloc>().add(
                                      PhotosSearchPhotos(
                                          query: text.text.trim()));
                                }
                                setState(() {
                                  order = -1;
                                });
                              }),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                width: 16.0, color: Colors.lightBlue.shade50),
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            context
                                .read<PhotosBloc>()
                                .add(PhotosSearchPhotos(query: val.trim()));
                          }
                          setState(() {
                            order = -1;
                          });
                        },
                      ),
                      const SizedBox(
                        height: 15,
                      ),

                      /// TapBar
                      _buildTabBar(),
                      const SizedBox(
                        height: 25,
                      ),
                      Expanded(
                        child: state.photos.isNotEmpty
                            ? GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(20.0),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  mainAxisSpacing: 15.0,
                                  crossAxisSpacing: 15.0,
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.8,
                                ),
                                itemBuilder: (context, index) {
                                  final photo = state.photos[index];
                                  return PhotoCard(
                                    photos: state.photos,
                                    index: index,
                                    photo: photo,
                                  );
                                },
                                itemCount: state.photos.length,
                              )
                            : Center(
                                child: Text('No results.'),
                              ),
                      ),
                    ],
                  ),
                  if (state.status == PhotosStatus.loading)
                    CircularProgressIndicator(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50.0,
      child:  ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            return GestureDetector(
              onTap: () {
                context
                    .read<PhotosBloc>()
                    .add(PhotosSearchPhotos(query: orders[i]));
                setState(() {
                  text.text = orders[i];
                  order = i;
                });
              },
              child: AnimatedContainer(
                margin: EdgeInsets.fromLTRB(i == 0 ? 15 : 5, 0, 5, 0),
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  color: i == order ? Colors.grey[700] : Colors.grey[200],
                ),
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: Text(orders[i], style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500, color: i == order ? Colors.white : Colors.black),),
                ),
              ),
            );
          }),
    );



  }
}
