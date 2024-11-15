import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class LiveScoreWidget extends StatefulWidget {
  const LiveScoreWidget({super.key});

  @override
  _LiveScoreWidgetState createState() => _LiveScoreWidgetState();
}

class _LiveScoreWidgetState extends State<LiveScoreWidget> {
  late WebSocketChannel channel;
  final String apiKey = '12e247bda0d087114957894c9b50f2417c5c51bdd248642fa3a8c60e7adeea8e';
  final String timezone = '+03:00';
  List<Map<String, dynamic>> liveMatches = [];
  bool isConnected = false;
  String connectionStatus = 'Connecting...';
  
  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  Future<void> connectWebSocket() async {
    try {
      setState(() {
        connectionStatus = 'Connecting...';
      });

      final uri = Uri.parse('wss://wss.apifootball.com/livescore?WidgetKey=$apiKey&timezone=$timezone');
      
      channel = WebSocketChannel.connect(uri);
      
      channel.sink.add(jsonEncode({
        'action': 'subscribe',
        'timezone': timezone,
      }));

      channel.stream.listen(
        (message) {
          try {
            print('Raw message received: $message');
            
            if (message is String) {
              final data = jsonDecode(message);
              print('Decoded data: $data');
              
              if (data is List) {
                final typedData = data.map((item) => Map<String, dynamic>.from(item)).toList();
                setState(() {
                  liveMatches = typedData;
                  isConnected = true;
                  connectionStatus = 'Connected - ${liveMatches.length} matches found';
                });
              } else if (data is Map) {
              
                print('Received single match update: $data');
                _handleSingleMatchUpdate(data);
              } else {
                print('Unexpected data format: ${data.runtimeType}');
                setState(() {
                  connectionStatus = 'Error: Unexpected data format';
                });
              }
            } else {
              print('Unexpected message type: ${message.runtimeType}');
            }
          } catch (e) {
            print('Error parsing message: $e');
            setState(() {
              connectionStatus = 'Error parsing data: $e';
            });
          }
        },
        onDone: () {
          print('WebSocket connection closed');
          setState(() {
            isConnected = false;
            connectionStatus = 'Connection closed - Reconnecting...';
          });
       
          Future.delayed(const Duration(seconds: 5), connectWebSocket);
        },
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            isConnected = false;
            connectionStatus = 'Connection error: $error';
          });
      
          Future.delayed(const Duration(seconds: 5), connectWebSocket);
        },
      );
    } catch (e) {
      print('Connection error: $e');
      setState(() {
        connectionStatus = 'Failed to connect: $e';
      });
      Future.delayed(const Duration(seconds: 5), connectWebSocket);
    }
  }

  void _handleSingleMatchUpdate(dynamic matchData) {
    if (matchData is Map) {
     
      final Map<String, dynamic> typedMatchData = Map<String, dynamic>.from(matchData);
      
      setState(() {
    
        final index = liveMatches.indexWhere((match) => match['match_id'] == typedMatchData['match_id']);
        if (index != -1) {
          liveMatches[index] = typedMatchData;
        } else {
          liveMatches.add(typedMatchData);
        }
      });
    }
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Scores'),
        actions: [
          IconButton(
            icon: Icon(isConnected ? Icons.wifi : Icons.wifi_off),
            onPressed: () {
              if (!isConnected) {
                connectWebSocket();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
         Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Text(connectionStatus),
          ),
          Expanded(
            child: liveMatches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isConnected 
                          ? 'No live matches available' 
                          : 'Connecting to server...'),
                        if (!isConnected)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: liveMatches.length,
                    itemBuilder: (context, index) {
                      final match = liveMatches[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text('${match['match_hometeam_name']} vs ${match['match_awayteam_name']}'),
                          subtitle: Text('Score: ${match['match_hometeam_score']} - ${match['match_awayteam_score']}'),
                          trailing: Text(match['match_status'] ?? 'N/A'),
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