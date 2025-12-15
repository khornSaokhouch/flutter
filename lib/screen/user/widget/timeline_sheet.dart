// lib/screen/order/widgets/timeline_sheet.dart
import 'package:flutter/material.dart';

void showTrackingSheet(BuildContext context, String currentStatus, {required Color freshMintGreen, required Color espressoBrown}) {
  int activeStep = 0;
  if (currentStatus == 'preparing') activeStep = 1;
  if (currentStatus == 'ready') activeStep = 2;
  if (currentStatus == 'completed') activeStep = 3;
  if (currentStatus == 'cancelled') activeStep = -1;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const SizedBox(width: 24), Text("TRACKING ORDER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: espressoBrown, letterSpacing: 1.0)), InkWell(onTap: () => Navigator.pop(context), child: CircleAvatar(backgroundColor: Colors.grey[100], radius: 15, child: const Icon(Icons.close, size: 18, color: Colors.grey)))]),
            const SizedBox(height: 30),
            if (currentStatus == 'cancelled')
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.cancel, color: Colors.red), const SizedBox(width: 12), const Expanded(child: Text("This order has been cancelled.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)))]))
            else
              Column(children: [
                _buildTimelineStep(title: "Order Received", subtitle: "Waiting for store confirmation", stepIndex: 0, currentStep: activeStep, isLast: false, freshMintGreen: freshMintGreen, espressoBrown: espressoBrown),
                _buildTimelineStep(title: "Order Confirmed", subtitle: "Store is preparing your order", stepIndex: 1, currentStep: activeStep, isLast: false, freshMintGreen: freshMintGreen, espressoBrown: espressoBrown),
                _buildTimelineStep(title: "Order Ready", subtitle: "Your order is ready to pickup", stepIndex: 2, currentStep: activeStep, isLast: true, freshMintGreen: freshMintGreen, espressoBrown: espressoBrown),
              ]),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

Widget _buildTimelineStep({
  required String title,
  required String subtitle,
  required int stepIndex,
  required int currentStep,
  required bool isLast,
  required Color freshMintGreen,
  required Color espressoBrown,
}) {
  final bool isCompleted = currentStep >= stepIndex;
  final bool isActive = currentStep == stepIndex;
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? freshMintGreen : Colors.white,
                shape: BoxShape.circle,
                border: isCompleted ? null : Border.all(color: Colors.grey[300]!, width: 2),
                boxShadow: isActive ? [BoxShadow(color: freshMintGreen.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))] : [],
              ),
              child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 4,
                  color: isCompleted ? freshMintGreen : Colors.grey[200],
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32.0, top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isCompleted ? espressoBrown : Colors.black)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
        )
      ],
    ),
  );
}
