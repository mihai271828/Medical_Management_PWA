import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final CollectionReference _subsRef = FirebaseFirestore.instance.collection('subscriptions');

  Future<void> addSubscription(Subscription subscription) {
    // 1. Găsim referința EXACTĂ bazată pe ID-ul generat de noi în formular
    final docRef = _subsRef.doc(subscription.id); 
    
    // 2. Extragem datele și ne asigurăm că ID-ul din interior este corect
    final data = subscription.toMap();
    data['id'] = docRef.id; 
    
    // 3. Salvăm folosind .set() în loc de .add()
    return docRef.set(data);
  }

  Future<void> updateSubscription(Subscription subscription) async {
    await _subsRef.doc(subscription.id).update(subscription.toMap());
  }

  Future<void> deleteSubscription(String id) async {
    await _subsRef.doc(id).delete();
  }
  Future<Subscription?> getActiveSubscription(String patientId, String service) async {
    final query = await _subsRef
        .where('patientId', isEqualTo: patientId)
        .where('service', isEqualTo: service)
        .where('status', isEqualTo: 'activ')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return Subscription.fromFirestore(query.docs.first);
    }
    return null;
  }

 
  Future<void> incrementUsedSession(String subscriptionId) async {
    await _subsRef.doc(subscriptionId).update({
      'usedSessions': FieldValue.increment(1) // Firebase face matematica singur!
    });
  }
}