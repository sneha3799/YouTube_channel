import 'dart:convert';
import 'dart:io';

import 'package:youtube_app/models/channel_model.dart';
import 'package:youtube_app/models/video_model.dart';
import 'package:youtube_app/utilities/key.dart';
import 'package:http/http.dart' as http;

class ApiService{

  ApiService._instantiate();

  static final ApiService instance = ApiService._instantiate();

  final String _baseUrl = 'www.googleapis.com';
  String _nextPageToken = '';

  Future<Channel> fetchChannel({String channelId}) async {
    Map<String,String> parameters = {
      'part': 'snippet,contentDetails,statistics',
      'id': channelId,
      'key': API_KEY,
    };

    Uri uri = Uri.https(_baseUrl, '/youtube/v3/channels',parameters);

    Map<String,String> headers = {
      HttpHeaders.contentTypeHeader : 'application/json',
    };

    // get channel
    var response = await http.get(uri,headers: headers);
    if(response.statusCode == 200){
      Map<String,dynamic> data = json.decode(response.body)['items'][0];
      Channel channel = Channel.fromMap(data);

      // fetch first batch of videos from uploads playlist
      channel.videos = await fetchVideoFromPlaylist(
        playlistId: channel.uploadPlayListId,
      );
      return channel;
    }
    else{
      throw json.decode(response.body)['error']['message'];
    }
  }

  Future<List<Video>> fetchVideoFromPlaylist({String playlistId}) async {
    Map<String,String> parameters = {
      'part' : 'snippet',
      'playlistId': playlistId,
      'maxResults': '7',
      'pageToken': _nextPageToken,
      'key': API_KEY,
    };

    Uri uri = Uri.https(
      _baseUrl,
      '/youtube/v3/playlistItems',
      parameters,
    );

    Map<String,String> headers = {
      HttpHeaders.contentTypeHeader : 'application/json',
    };

    // get playlist videos
    var response = await http.get(uri,headers: headers);
    if(response.statusCode == 200){
      var data = json.decode(response.body);

      _nextPageToken = data['nextPageToken'] ?? '';
      List<dynamic> videosJson = data['items'];

      // fetch first 8 videos from playlist
      List<Video> videos = [];
      videosJson.forEach((json) => videos.add(
        Video.fromMap(json['snippet']),
      ),
      );
      return videos;
    }
    else{
      throw json.decode(response.body)['error']['message'];
    }
  }

}