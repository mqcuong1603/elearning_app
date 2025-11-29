import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}


import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Service
/// Generic CRUD operations for all Firestore collections
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  Future<String> create({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        // Create with specific ID
        final dataWithId = {...data, 'id': documentId};
        await _firestore.collection(collection).doc(documentId).set(dataWithId);
        return documentId;
      } else {
        // Create with auto-generated ID
        final docRef = await _firestore.collection(collection).add(data);
        final generatedId = docRef.id;

        // Update the document to include its own ID
        await docRef.update({'id': generatedId});

        return generatedId;
      }
    } catch (e) {
      print('Firestore create error: $e');
      throw Exception('Failed to create document: ${e.toString()}');
    }
  }

  /// Read a single document by ID
  Future<Map<String, dynamic>?> read({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      return {
        ...doc.data()!,
        'id': doc.id,
      };
    } catch (e) {
      print('Firestore read error: $e');
      throw Exception('Failed to read document: ${e.toString()}');
    }
  }

  /// Update a document
  Future<void> update({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Firestore update error: $e');
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }

  /// Delete a document
  Future<void> delete({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Firestore delete error: $e');
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getAll({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore getAll error: $e');
      throw Exception('Failed to get documents: ${e.toString()}');
    }
  }

  /// Query documents with filters
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Firestore query error: $e');
      throw Exception('Failed to query documents: ${e.toString()}');
    }
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return {
          ...doc.data()!,
          'id': doc.id,
        };
      },
    );
  }

  /// Stream all documents from a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Stream query with filters
  Stream<List<Map<String, dynamic>>> streamQuery({
    required String collection,
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters
    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();
      },
    );
  }

  /// Batch create multiple documents
  Future<void> batchCreate({
    required String collection,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final data in dataList) {
        final docRef = _firestore.collection(collection).doc();
        // Include the document ID in the data
        final dataWithId = {...data, 'id': docRef.id};
        batch.set(docRef, dataWithId);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch create error: $e');
      throw Exception('Failed to batch create: ${e.toString()}');
    }
  }

  /// Batch update multiple documents
  Future<void> batchUpdate({
    required String collection,
    required List<BatchUpdateItem> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final update in updates) {
        final docRef = _firestore.collection(collection).doc(update.documentId);
        batch.update(docRef, update.data);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch update error: $e');
      throw Exception('Failed to batch update: ${e.toString()}');
    }
  }

  /// Batch delete multiple documents
  Future<void> batchDelete({
    required String collection,
    required List<String> documentIds,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(collection).doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      print('Firestore batch delete error: $e');
      throw Exception('Failed to batch delete: ${e.toString()}');
    }
  }

  /// Count documents in a collection
  Future<int> count({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(
            filter.field,
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
            isNull: filter.isNull,
          );
        }
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Firestore count error: $e');
      throw Exception('Failed to count documents: ${e.toString()}');
    }
  }

  /// Check if document exists
  Future<bool> exists({
    required String collection,
    required String documentId,
  }) async {
    try {
      final doc =
          await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      print('Firestore exists error: $e');
      return false;
    }
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Batch update helper class
class BatchUpdateItem {
  final String documentId;
  final Map<String, dynamic> data;

  BatchUpdateItem({
    required this.documentId,
    required this.data,
  });
}
