// import 'package:multicast_dns/multicast_dns.dart';

// Future<String?> resolveMdnsHost(String hostName) async {
//   final MDnsClient client = MDnsClient();
//   try {
//     await client.start();
//     await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
//       ResourceRecordQuery.serverPointer('_printer._tcp.local'),
//     )) {
//       if (ptr.domainName.toLowerCase().contains(hostName.toLowerCase())) {
//         print('➡️ Encontrado PTR: ${ptr.domainName}');
//         await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
//           ResourceRecordQuery.service(ptr.domainName),
//         )) {
//           print('➡️ Encontrado SRV: ${srv.target}');
//           await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
//             ResourceRecordQuery.addressIPv4(srv.target),
//           )) {
//             return ip.address.address;
//           }
//         }
//       }
//     }
//   } catch (e) {
//     print('❌ Error mDNS: $e');
//   } finally {
//     client.stop();
//   }
//   return null;
// }
