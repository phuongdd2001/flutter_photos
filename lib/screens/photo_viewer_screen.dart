import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_photos/models/models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<Photo> photos;
  final int currentIndex;

  const PhotoViewerScreen({
    Key? key,
    required this.photos,
    required this.currentIndex,
  }) : super(key: key);

  @override
  _PhotoViewerScreenState createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int indexPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentIndex);
    this.indexPage = widget.currentIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      // appBar: AppBar(
      //   elevation: 0,
      //   backgroundColor: Colors.transparent,
      // ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          MenuAnchor(
            builder: (BuildContext context, MenuController controller,
                Widget? child) {
              return IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                icon: const Icon(Icons.more_vert),
                tooltip: 'Show menu',
              );
            },
            menuChildren: [
              MenuItemButton(
                onPressed: () async {
                  final photo = widget.photos[this.indexPage];
                  // get link image
                  await _askPermission();
                  var response = await Dio().get(photo.url,
                      options: Options(responseType: ResponseType.bytes));
                  final result = await ImageGallerySaver.saveImage(
                      Uint8List.fromList(response.data));

                  // image success open snackbar
                  if (result != null) {
                    final snackBar = SnackBar(
                      backgroundColor: Colors.green,
                      content: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.download_outlined,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 5.0,
                        ),
                        Text('Download image success'),
                      ],
                    ),

                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
                child: Text('Download image'),
                leadingIcon: Icon(Icons.download_outlined),
              ),
              MenuItemButton(
                onPressed: () {
                  final photo = widget.photos[this.indexPage];
                  if (photo != null) {
                    Clipboard.setData(new ClipboardData(text: photo.url));
                    final snackBar = SnackBar(
                      backgroundColor: Colors.green,
                      content: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.copy,
                            color: Colors.white,
                          ),
                          SizedBox(
                            width: 5.0,
                          ),
                          Text('Copy link image success'),
                        ],
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
                child: Text('Copy link'),
                leadingIcon: Icon(Icons.copy),
              ),
            ],
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: _onPageViewChange,
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: Key('${index}_${photo.id}'),
                child: CachedNetworkImage(
                  height: 300.0,
                  width: double.infinity,
                  imageUrl: photo.url,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Center(
                    child: const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 50.0,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '(${index + 1}/${widget.photos.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      photo.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16.0,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: CachedNetworkImageProvider(
                            photo.user.profileImageUrl,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        GestureDetector(
                          onTap: () async {
                            final url = photo.user.profileUrl;
                            if (await canLaunch(url)) {
                              await launch(url);
                            }
                          },
                          child: Text(
                            photo.user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // _save() async {
  //   print("sahil");
  //   await _askPermission();
  //   var response = await Dio().get("https://images.unsplash.com/photo-1587620962725-abab7fe55159?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0OTU0OTh8MHwxfHNlYXJjaHwxfHxwcm9ncmFtbWluZ3xlbnwwfHx8fDE2OTMzNzE3MDl8MA&ixlib=rb-4.0.3&q=80&w=1080", options: Options(responseType: ResponseType.bytes));
  //   final result =
  //   await ImageGallerySaver.saveImage(Uint8List.fromList(response.data));
  //   print(result);
  // }

  _askPermission() async {
    var status = await Permission.storage.status;
    if (status.isPermanentlyDenied) {
      Navigator.pop(context);
    }
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();
    print(statuses[Permission.storage]);
  }

  _onPageViewChange(int page) {
    this.indexPage = page;
  }
}
