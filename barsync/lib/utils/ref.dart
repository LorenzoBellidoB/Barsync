import 'package:cloud_firestore/cloud_firestore.dart';

/// Devuelve un DocumentReference válido.
/// Si `ref` ya es un DocumentReference, se retorna tal cual.
/// Si es un String no vacío, se convierte a DocumentReference.
/// Si es null o un String vacío, retorna un fallback.
DocumentReference<Object?> getValidDocRef(dynamic ref, String fallbackPath) {
  if (ref is DocumentReference) return ref;
  if (ref is String && ref.isNotEmpty) {
    return FirebaseFirestore.instance.doc(ref);
  }
  return FirebaseFirestore.instance.doc(fallbackPath);
}
