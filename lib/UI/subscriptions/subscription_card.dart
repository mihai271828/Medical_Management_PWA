import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import '../../app_contants.dart'; 
import '../../Data/models/subscription_model.dart'; 

class SubscriptionProgressCard extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionProgressCard({Key? key, required this.subscription}) : super(key: key);

  
  void _updateSessionCount(BuildContext context, int newCount) {
    try {
      bool isNowFinished = newCount >= subscription.totalSessions;
      String newStatus = isNowFinished ? 'finalizat' : 'activ';

      // Map cu actualizările de bază
      Map<String, dynamic> updates = {
        'usedSessions': newCount,
        'status': newStatus,
      };

      
      if (isNowFinished && subscription.status != 'finalizat') {
        updates['completedAt'] = DateTime.now().toIso8601String();
      } else if (!isNowFinished && subscription.status == 'finalizat') {
        updates['completedAt'] = null;
      }

      FirebaseFirestore.instance.collection('subscriptions').doc(subscription.id).update(updates);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la actualizare: $e')),
      );
    }
  }


  void _deleteSubscription(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Șterge Abonamentul', style: TextStyle(color: AppColors.bordeaux)),
        content: const Text(
          'Ești sigur că vrei să ștergi definitiv acest abonament? Această acțiune nu poate fi anulată.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text('Anulează', style: TextStyle(color:Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bordeaux,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true) {
        try {
          FirebaseFirestore.instance.collection('subscriptions').doc(subscription.id).delete(); // Ștergere instantanee
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Abonamentul a fost șters.'),
                backgroundColor: Colors.grey,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Eroare la ștergere: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    });
  }

  // Dialog inteligent pentru editarea sumei totale achitate
  void _showAddPaymentDialog(BuildContext context) {
    // Pre-completăm căsuța cu suma deja existentă în baza de date!
    final TextEditingController amountController = TextEditingController(
      text: subscription.amountPaid > 0 ? subscription.amountPaid.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Actualizează Plata', style: TextStyle(color: AppColors.bordeaux)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preț total abonament: ${subscription.totalPrice} lei', 
                 style: const TextStyle(fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Total achitat (lei)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bordeaux,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Preluăm noua valoare exact cum a fost scrisă
              double newTotalPaid = double.tryParse(amountController.text) ?? 0.0;
              
              // Ne asigurăm că nu e negativă și nu depășește prețul total
              if (newTotalPaid < 0) newTotalPaid = 0.0;
              if (newTotalPaid > subscription.totalPrice) newTotalPaid = subscription.totalPrice;

              // Suprascriem suma în Firebase
              FirebaseFirestore.instance.collection('subscriptions').doc(subscription.id).update({
                'amountPaid': newTotalPaid,
              });
              
              Navigator.pop(context); // Se închide instantaneu
            },
            child: const Text('Salvează', style: TextStyle(color: AppColors.cream)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double remainingMoney = subscription.totalPrice - subscription.amountPaid;
    bool isFinished = subscription.status == 'finalizat' || subscription.usedSessions >= subscription.totalSessions;

    if (isFinished && subscription.completedAt == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FirebaseFirestore.instance.collection('subscriptions').doc(subscription.id).update({
          'status': 'finalizat',
          'completedAt': DateTime.now().toIso8601String(),
        });
      });
    }

    String formattedDate = DateFormat('dd MMM yyyy').format(subscription.createdAt);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isFinished ? Colors.green.shade300 : Colors.transparent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey.shade700, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subscription.patientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.bordeaux),
                  onPressed: () => _deleteSubscription(context),
                  tooltip: 'Șterge abonamentul',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.service,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.bordeaux),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      isFinished ? 'Finalizat' : 'Activ',
                      style: TextStyle(
                        color: isFinished ? Colors.green : Colors.orange.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '  • Creat: $formattedDate ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (isFinished && subscription.completedAt != null)
                      Text(
                        '  • Finalizat: ${DateFormat('dd MMM yyyy').format(subscription.completedAt!)}',
                        style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            Text(
              'Ședințe efectuate: ${subscription.usedSessions} / ${subscription.totalSessions}',
              style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Apasă pe cerc gol pentru bifare sau pe ultimul bifat pentru a anula.',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(subscription.totalSessions, (index) {
                bool isDone = index < subscription.usedSessions;
                bool isNextToComplete = index == subscription.usedSessions;
                bool isLastCompleted = index == subscription.usedSessions - 1;
                bool isClickable = isNextToComplete || isLastCompleted;

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: isClickable
                      ? () {
                          if (isNextToComplete) {
                            _updateSessionCount(context, subscription.usedSessions + 1);
                          } else if (isLastCompleted) {
                            _updateSessionCount(context, subscription.usedSessions - 1);
                          }
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? Colors.teal
                          : (isNextToComplete ? Colors.teal.withOpacity(0.1) : Colors.grey.shade200),
                      border: Border.all(
                        color: isDone ? Colors.teal : (isNextToComplete ? Colors.teal : Colors.grey.shade300),
                        width: isNextToComplete ? 2 : 1,
                      ),
                      boxShadow: isNextToComplete
                          ? [BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                          : [],
                    ),
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : (isNextToComplete ? const Icon(Icons.touch_app, color: Colors.teal, size: 18) : null),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: () => _showAddPaymentDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: remainingMoney > 0 ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: remainingMoney > 0 ? Colors.red.shade200 : Colors.green.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        remainingMoney > 0 ? Icons.account_balance_wallet : Icons.check_circle,
                        size: 18,
                        color: remainingMoney > 0 ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        remainingMoney > 0 ? 'Rest plată: $remainingMoney lei' : 'Achitat integral',
                        style: TextStyle(
                          color: remainingMoney > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}