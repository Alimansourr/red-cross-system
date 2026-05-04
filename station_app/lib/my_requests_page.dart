import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/assigned_requests_service.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final AssignedRequestsService _service = AssignedRequestsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Requests'),
        backgroundColor: const Color(0xffef3b4c),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AssignedRequest>>(
        stream: _service.watchAssignedRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No requests assigned to you',
                      style: TextStyle(fontSize: 16, color: Color(0xff6b7280)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When admins assign emergency or transport requests to you, they will appear here.',
                      style: TextStyle(fontSize: 12, color: Color(0xff9ca3af)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (_, i) => _RequestCard(
              request: requests[i],
              onStatusChange: (s) async {
                try {
                  await _service.updateStatus(requests[i], s);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Status updated to $s')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AssignedRequest request;
  final void Function(String) onStatusChange;

  const _RequestCard({
    required this.request,
    required this.onStatusChange,
  });

  Future<void> _callPatient(BuildContext context) async {
    final phone = request.patientPhone.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final rawPhone = request.patientPhone.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    final formattedPhone = _formatPhoneForWhatsApp(rawPhone);
    if (formattedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number')),
      );
      return;
    }

    final whatsappAppUri = Uri.parse('whatsapp://send?phone=$formattedPhone');
    final whatsappWebUri = Uri.parse('https://wa.me/$formattedPhone');

    try {
      bool opened = await launchUrl(
        whatsappAppUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        opened = await launchUrl(
          whatsappWebUri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp for $formattedPhone'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp for $formattedPhone'),
          ),
        );
      }
    }
  }

  Future<void> _openMap(BuildContext context) async {
    final lat = request.latitude;
    final lng = request.longitude;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location available')),
      );
      return;
    }

    final url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map')),
      );
    }
  }

  String _formatPhoneForWhatsApp(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('00961')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('961')) {
      return digits;
    } else if (digits.startsWith('03') && digits.length == 8) {
      digits = '961${digits.substring(1)}';
    } else if (digits.startsWith('3') && digits.length == 7) {
      digits = '961$digits';
    } else if (digits.startsWith('70') && digits.length == 8) {
      digits = '961$digits';
    } else if (digits.startsWith('71') && digits.length == 8) {
      digits = '961$digits';
    } else if (digits.startsWith('76') && digits.length == 8) {
      digits = '961$digits';
    } else if (digits.startsWith('78') && digits.length == 8) {
      digits = '961$digits';
    } else if (digits.startsWith('79') && digits.length == 8) {
      digits = '961$digits';
    } else if (digits.startsWith('81') && digits.length == 8) {
      digits = '961$digits';
    }

    return digits;
  }

  Color get _priorityColor {
    switch (request.data['aiPriority']) {
      case 'CRITICAL':
        return const Color(0xffdc2626);
      case 'HIGH':
        return const Color(0xfff97316);
      case 'MEDIUM':
        return const Color(0xfff59e0b);
      case 'LOW':
        return const Color(0xff16a34a);
      default:
        return const Color(0xff6b7280);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xfff59e0b);
      case 'dispatched':
        return const Color(0xff2563eb);
      case 'completed':
        return const Color(0xff16a34a);
      case 'cancelled':
        return const Color(0xff6b7280);
      default:
        return const Color(0xff6b7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priority = request.data['aiPriority']?.toString() ?? '';
    final isCritical = priority == 'CRITICAL';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCritical ? const Color(0xffdc2626) : Colors.grey.shade200,
          width: isCritical ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: request.isEmergency
                        ? const Color(0xfffee2e2)
                        : const Color(0xffe0f2fe),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.isEmergency ? '🚨 EMERGENCY' : '🚐 TRANSPORT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: request.isEmergency
                          ? const Color(0xffdc2626)
                          : const Color(0xff0284c7),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (priority.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _priorityColor,
                      ),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(request.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(request.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.patientName.isNotEmpty
                  ? request.patientName
                  : 'Unknown Patient',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (request.isEmergency) ...[
              if (request.emergencyType.isNotEmpty)
                Text(
                  'Type: ${request.emergencyType}',
                  style: const TextStyle(color: Color(0xff6b7280), fontSize: 13),
                ),
              if (request.currentCondition.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    request.currentCondition,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ] else ...[
              if (request.pickupLocation.isNotEmpty)
                Text(
                  'From: ${request.pickupLocation}',
                  style: const TextStyle(fontSize: 13),
                ),
              if (request.destination.isNotEmpty)
                Text(
                  'To: ${request.destination}',
                  style: const TextStyle(fontSize: 13),
                ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (request.patientAge != null && request.patientAge!.isNotEmpty)
                  _InfoChip(label: 'Age ${request.patientAge}'),
                if (request.patientBloodType.isNotEmpty)
                  _InfoChip(label: 'Blood: ${request.patientBloodType}'),
                if (request.patientAddress.isNotEmpty)
                  _InfoChip(label: '📍 ${_truncate(request.patientAddress, 30)}'),
              ],
            ),
            if (request.patientMedicalHistory.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xfffef2f2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xfffecaca)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medical History',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xffb91c1c),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.patientMedicalHistory,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callPatient(context),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffef3b4c),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(context),
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff25d366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (request.latitude != null && request.longitude != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _openMap(context),
                    icon: const Icon(Icons.map_outlined),
                    color: const Color(0xff2563eb),
                    tooltip: 'Open Map',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Update status:',
                  style: TextStyle(fontSize: 12, color: Color(0xff6b7280)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: request.status,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'dispatched', child: Text('Dispatched')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (val) {
                      if (val != null) onStatusChange(val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}...';
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xfff3f4f6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xff374151)),
      ),
    );
  }
}