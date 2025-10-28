// import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
//
// class PusherService {
//   final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
//
//   Future<void> initPusher() async {
//     try {
//       await pusher.init(
//         apiKey: '40f776efa31ab56d4edb',
//         cluster: 'ap1',
//         onConnectionStateChange: (state) {
//           print('📡 Pusher state changed: $state');
//         },
//         onError: (message, code, exception) {
//           print('❌ Pusher error: $message');
//         },
//       );
//
//       await pusher.connect();
//       await pusher.subscribe(channelName: 'test-channel');
//
//       pusher.onEvent((event) {
//         print('📡 EVENT RECEIVED!');
//         print('Channel: ${event.channelName}');
//         print('Event: ${event.eventName}');
//         print('Data: ${event.data}');
//       });
//
//       print('✅ Pusher initialized and listening...');
//     } catch (e) {
//       print('❌ Pusher initialization failed: $e');
//     }
//   }
// }
