import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:file_picker/file_picker.dart';
import 'package:subtitle/subtitle.dart';
import 'package:video_cast/chrome_cast_media_type.dart';
import 'package:video_cast/video_cast.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  State<MyScreen> createState() => MyScreenState();
}

class MyScreenState extends State<MyScreen> {
  late final Player player = Player();
  late ChromeCastController _controller;
  ChromeCastController? castController;

  late final VideoController controller = VideoController(player,
      configuration: VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ));
  void _showSpeedSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                title: Text('0.5x'),
                onTap: () {
                  _changePlaybackSpeed(0.5);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('1.0x'),
                onTap: () {
                  _changePlaybackSpeed(1.0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('1.5x'),
                onTap: () {
                  _changePlaybackSpeed(1.5);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('2.0x'),
                onTap: () {
                  _changePlaybackSpeed(2.0);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      playbackSpeed = speed;
    });
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isDismissible: true,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.speed_sharp),
                title: Text('Playback Speed'),
                onTap: () {
                  _showSpeedSelector(context);
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.info),
              //   title: Text('About'),
              //   onTap: () {
              //     // Add functionality for About option
              //     Navigator.pop(context);
              //   },
              // ),
              // ListTile(
              //   leading: Icon(Icons.help),
              //   title: Text('Help'),
              //   onTap: () {
              //     // Add functionality for Help option
              //     Navigator.pop(context);
              //   },
              // ),
              ListTile(
                leading: Icon(Icons.close),
                title: Text('Close'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  bool isSubtitlesEnabled = false;
  double playbackSpeed = 1.0;
  bool isCasting = false;
  String videoSource = '';
  // double speed = 1.0;
  @override
  void initState() {
    super.initState();
  }

  Future<void> toggleSubtitles() async {
    setState(() {
      isSubtitlesEnabled = !isSubtitlesEnabled;
      if (isSubtitlesEnabled == true) {
        print(isSubtitlesEnabled);
        Fluttertoast.showToast(
            msg: "Captions ON",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Color.fromARGB(255, 0, 195, 52),
            textColor: Colors.white,
            fontSize: 16.0);
      } else if (isSubtitlesEnabled == false) {
        print(isSubtitlesEnabled);
        Fluttertoast.showToast(
            msg: "Captions Off",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color.fromARGB(255, 240, 47, 33),
            textColor: Colors.white,
            fontSize: 16.0);
      }
    });
    // if (isSubtitlesEnabled) {
    //   player.stream.track.listen((event) async {
    //     await player.setSubtitleTrack(SubtitleTrack.auto());
    //     // player.state.track.subtitle;
    //   });
    // } else {
    //   player.stream.track.listen((event) async {
    //     await player.setSubtitleTrack(SubtitleTrack.no());
    //   });
    // }
  }

  Future<void> pickSubtitleFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'srt',
        'vtt',
        'sub'
      ], // Add more supported subtitle extensions if necessary
    );

    if (result != null) {
      setState(() {
        subtitleFilePath = result.files.single.path;
      });
    }
  }

  List<PlatformFile> selectedVideos = [];

  Future<void> pickMultipleVideos() async {
    List<PlatformFile> pickedFiles = [];

    try {
      pickedFiles = (await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      ))!
          .files;
    } catch (e) {
      // Handle any errors that occur during the file picking process
      print('Error picking files: $e');
      return;
    }

    List<Media> mediaList = pickedFiles
        .map((file) => Media(
              file.path!,
              httpHeaders: {
                'Foo': 'Bar',
                'Accept': '*/*',
                'Range': 'bytes=0-',
              },
            ))
        .toList();
    Playlist playlist = Playlist(
      mediaList,
    );

    try {
      await player.open(playlist);
    } catch (e) {
      // Handle any errors that occur while opening the playlist
      print('Error opening playlist: $e');
      return;
    }

    setState(() {
      selectedVideos = pickedFiles;
    });

    player.stream.position.listen((event) {
      player.setRate(playbackSpeed);
    });
  }

  void toggleCasting() {
    setState(() {
      isCasting = !isCasting;
      // Implement casting logic here
    });
  }

  late SubtitleController subtitleController;
  late TextEditingController videoLinkController = TextEditingController();
  String? subtitleFilePath;
  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() async {
        await player.stream.position.listen((event) {
          player.setRate(playbackSpeed);
        });
        if (isSubtitlesEnabled == true) {
          await player.setSubtitleTrack(SubtitleTrack.auto());
        } else if (isSubtitlesEnabled == false) {
          await player.setSubtitleTrack(SubtitleTrack.no());
        }
        videoSource = result.files.single.path ?? '';

        player.open(
          Media(
            videoSource,
            httpHeaders: {
              'Foo': 'Bar',
              'Accept': '*/*',
              'Range': 'bytes=0-',
            },
          ),
        );
      });
    }
  }

  void playVideoFromLink(String link) {
    setState(() async {
      videoSource = link;
      await player.stream.position.listen((event) {
        player.setRate(playbackSpeed);
      });

      if (isSubtitlesEnabled == true) {
        await player.setSubtitleTrack(SubtitleTrack.auto());
      } else if (isSubtitlesEnabled == false) {
        await player.setSubtitleTrack(SubtitleTrack.no());
      }
      player.open(Media(
        videoSource,
        httpHeaders: {
          'Foo': 'Bar',
          'Accept': '*/*',
          'Range': 'bytes=0-',
        },
      ));
    });
  }

  @override
  void dispose() {
    player.dispose();
    videoLinkController.dispose(); // Dispose of the text input controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: SafeArea(
        child: MaterialVideoControlsTheme(
          normal: MaterialVideoControlsThemeData(
            primaryButtonBar: [
              Spacer(
                flex: 2,
              ),
              MaterialSkipPreviousButton(
                iconSize: 30,
              ),
              Spacer(),
              MaterialPlayOrPauseButton(
                iconSize: 30,
              ),
              Spacer(),
              MaterialSkipNextButton(
                iconSize: 30,
              ),
              Spacer(
                flex: 2,
              ),
            ],
            automaticallyImplySkipNextButton: false,
            automaticallyImplySkipPreviousButton: false,
            brightnessGesture: true,
            shiftSubtitlesOnControlsVisibilityChange: true,
            volumeGesture: true,
            buttonBarButtonSize: 24.0,
            buttonBarButtonColor: Colors.white,
            topButtonBar: [
              const Spacer(),
              IconButton(
                icon: Icon(isSubtitlesEnabled
                    ? Icons.closed_caption
                    : Icons.closed_caption_off),
                onPressed: () => toggleSubtitles(),
              ),
              MaterialDesktopCustomButton(
                onPressed: () {
                  print('Custom "Settings" button pressed.');
                  _showBottomSheet(context);
                },
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 25,
                ),
              ),
            ],
          ),
          fullscreen: const MaterialVideoControlsThemeData(
            displaySeekBar: true,
            shiftSubtitlesOnControlsVisibilityChange: true,
            automaticallyImplySkipNextButton: false,
            automaticallyImplySkipPreviousButton: false,
            volumeGesture: true,
            brightnessGesture: true,
            seekOnDoubleTap: true,
            primaryButtonBar: [
              Spacer(
                flex: 2,
              ),
              MaterialSkipPreviousButton(
                iconSize: 30,
              ),
              Spacer(),
              MaterialPlayOrPauseButton(
                iconSize: 30,
              ),
              Spacer(),
              MaterialSkipNextButton(
                iconSize: 30,
              ),
              Spacer(
                flex: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // TracksSelector(player: player),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                    child: Video(
                      controller: controller,
                      subtitleViewConfiguration:
                          const SubtitleViewConfiguration(
                        style: TextStyle(
                          height: 1.4,
                          fontSize: 24.0,
                          letterSpacing: 0.0,
                          wordSpacing: 0.0,
                          color: Color.fromARGB(255, 214, 247, 0),
                          fontWeight: FontWeight.normal,
                          backgroundColor: Color.fromARGB(170, 45, 46, 98),
                        ),
                        textAlign: TextAlign.center,
                        padding: EdgeInsets.all(24.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     IconButton(
                //       icon: Icon(Icons.folder_open), // Added file picker icon
                //       onPressed: () =>
                //           pickSubtitleFile(), // Function to pick subtitle file
                //     ),
                //   ],
                // ),
                Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Cast : "),
                      SizedBox(
                        width: 5,
                      ),
                      ChromeCastButton(
                        onButtonCreated: (controller) {
                          setState(() => _controller = controller);
                          _controller.addSessionListener();
                        },
                        onSessionStarted: () {
                          castController?.loadMedia(
                            url:
                                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                            position: 30000,
                            autoplay: true,
                            title: 'Spider-Man: No Way Home',
                            description:
                                'Peter Parker is unmasked and no longer able to separate his normal life from the high-stakes of being a super-hero. When he asks for help from Doctor Strange the stakes become even more dangerous, forcing him to discover what it truly means to be Spider-Man.',
                            image:
                                'https://terrigen-cdn-dev.marvel.com/content/prod/1x/marvsmposterbk_intdesign.jpg',
                            type: ChromeCastMediaType.movie,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: pickVideo,
                              child: Text('Choose Video'),
                            ),
                            if (videoSource.isNotEmpty)
                              Text(
                                'Video Source: $videoSource',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: TextField(
                          controller: videoLinkController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Video Link',
                            hintText: 'e.g. https://www.example.com/video.mp4',
                            border: OutlineInputBorder(
                              // Add an outline border
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 242, 227, 227),
                                  width: 0.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 16.0), // Add some padding
                          ),
                          style: TextStyle(
                              color: Colors.white), // Change the text color
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          playVideoFromLink(videoLinkController.text.trim());
                        },
                        child: Text('Play from Link'),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => pickMultipleVideos(),
                            child: Text(
                                'Choose Playlist(Select Multiples Videos)'),
                          ),
                          if (selectedVideos.isNotEmpty)
                            ...selectedVideos.map(
                              (video) => Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(video.name),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Flexible(
                //       child: TextField(
                //         controller: videoLinkController,
                //         decoration:
                //             InputDecoration(labelText: 'Enter Video Link'),
                //       ),
                //     ),
                //     ElevatedButton(
                //       onPressed: () {
                //         playVideoFromLink(videoLinkController.text);
                //       },
                //       child: Text('Play from Link'),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class TracksSelector extends StatefulWidget {
//   final Player player;

//   const TracksSelector({
//     Key? key,
//     required this.player,
//   }) : super(key: key);

//   @override
//   State<TracksSelector> createState() => _TracksSelectorState();
// }

// class _TracksSelectorState extends State<TracksSelector> {
//   late Track track = widget.player.state.track;
//   late Tracks tracks = widget.player.state.tracks;

//   List<StreamSubscription> subscriptions = [];

//   @override
//   void initState() {
//     super.initState();
//     track = widget.player.state.track;
//     tracks = widget.player.state.tracks;
//     subscriptions.addAll(
//       [
//         widget.player.stream.track.listen((track) {
//           setState(() {
//             this.track = track;
//           });
//         }),
//         widget.player.stream.tracks.listen((tracks) {
//           setState(() {
//             this.tracks = tracks;
//           });
//         }),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     for (final s in subscriptions) {
//       s.cancel();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Expanded(
//           child: DropdownButton<VideoTrack>(
//             isExpanded: true,
//             itemHeight: null,
//             value: track.video,
//             items: tracks.video
//                 .map(
//                   (e) => DropdownMenuItem(
//                     value: e,
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Text(
//                         '${e.id} • ${e.title} • ${e.language}',
//                         style: const TextStyle(
//                           fontSize: 14.0,
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//                 .toList(),
//             onChanged: (track) async {
//               if (track != null) {
//                 await widget.player.setVideoTrack(track);
//                 setState(() {});
//               }
//             },
//           ),
//         ),
//         const SizedBox(width: 16.0),
//         Expanded(
//           child: DropdownButton<AudioTrack>(
//             isExpanded: true,
//             itemHeight: null,
//             value: track.audio,
//             items: tracks.audio
//                 .map(
//                   (e) => DropdownMenuItem(
//                     value: e,
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Text(
//                         '${e.id} • ${e.title} • ${e.language}',
//                         style: const TextStyle(
//                           fontSize: 14.0,
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//                 .toList(),
//             onChanged: (track) async {
//               if (track != null) {
//                 await widget.player.setAudioTrack(track);
//                 setState(() {});
//               }
//             },
//           ),
//         ),
//         const SizedBox(width: 16.0),
//         Expanded(
//           child: DropdownButton<SubtitleTrack>(
//             isExpanded: true,
//             itemHeight: null,
//             value: track.subtitle,
//             items: tracks.subtitle
//                 .map(
//                   (e) => DropdownMenuItem(
//                     value: e,
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Text(
//                         '${e.id} • ${e.title} • ${e.language}',
//                         style: const TextStyle(
//                           fontSize: 14.0,
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//                 .toList(),
//             onChanged: (track) async {
//               if (track != null) {
//                 await widget.player.setSubtitleTrack(track);
//                 setState(() {});
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
