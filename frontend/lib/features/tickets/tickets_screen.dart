import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/ticket.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';
import '../../widgets/section_header.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final PageController _ctrl = PageController(viewportFraction: 0.86);
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final tickets = state.tickets.all();
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop())
            : null,
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.scanner),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.7, animated: false)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: SectionHeader(
                    title: 'Your tickets',
                    subtitle: tickets.isEmpty
                        ? 'Reserve a slot to issue a wallet pass.'
                        : '${tickets.length} pass${tickets.length == 1 ? '' : 'es'} stored offline',
                  ),
                ),
                if (tickets.isEmpty)
                  Expanded(
                    child: PFEmptyState(
                      icon: Icons.qr_code_2_rounded,
                      title: 'No tickets yet',
                      message:
                          'Reserve a slot to receive a wallet-style pass.',
                      actionLabel: 'Reserve a slot',
                      onAction: () => Navigator.of(context)
                          .pushNamed(AppRoutes.parkingMap),
                    ),
                  )
                else
                  Expanded(
                    child: PageView.builder(
                      controller: _ctrl,
                      itemCount: tickets.length,
                      onPageChanged: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _page = i);
                      },
                      itemBuilder: (_, i) {
                        final t = tickets[i];
                        return _TicketCard(
                            ticket: t, focused: i == _page);
                      },
                    ),
                  ),
                if (tickets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(tickets.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? PFColors.brand
                                : context.scheme.outline,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: PFPrimaryButton(
                    label: 'Scan a QR ticket',
                    icon: Icons.qr_code_scanner_rounded,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.scanner),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.focused});
  final PFTicket ticket;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final dateF = DateFormat('MMM d • HH:mm');
    // Responsive QR: scales with screen width, clamped for tiny/large devices.
    final double qrSize =
        (MediaQuery.sizeOf(context).width * 0.24).clamp(80.0, 110.0).toDouble();
    return AnimatedScale(
      duration: const Duration(milliseconds: 280),
      scale: focused ? 1.0 : 0.92,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 240),
        opacity: focused ? 1 : 0.7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1F1B), Color(0xFF052017)],
              ),
              boxShadow: [
                BoxShadow(
                  color: PFColors.brand.withValues(alpha: 0.35),
                  blurRadius: 30,
                  spreadRadius: 1,
                  offset: const Offset(0, 16),
                ),
              ],
              border: Border.all(
                color: PFColors.brand.withValues(alpha: 0.32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const GlowChip(
                        label: 'PARKFLOW PASS',
                        icon: Icons.bolt_rounded,
                        dense: true,
                      ),
                      const Spacer(),
                      Text(
                        ticket.id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ticket.slotLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'Level F${ticket.floor} • ${ticket.vehiclePlate}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _TicketStat(
                          label: 'ISSUED',
                          value: dateF.format(ticket.issuedAt)),
                      const SizedBox(width: 16),
                      _TicketStat(
                          label: 'EXPIRES',
                          value: dateF.format(ticket.expiresAt)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        QrImageView(
                          data: ticket.qrPayload,
                          size: qrSize,
                          version: QrVersions.auto,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0F172A),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tap-free entry',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Present at the gate scanner. Works offline.',
                                style: TextStyle(
                                  color: const Color(0xFF334155),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketStat extends StatelessWidget {
  const _TicketStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
