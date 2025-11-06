import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vendor_model.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Get vendors collection reference
  CollectionReference get _vendorsRef => _firestore.collection('vendors');

  // Add new vendor
  Future<Map<String, dynamic>> addVendor({
    required String name,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Check if phone number already exists
      final existingVendor = await _vendorsRef
          .where('userId', isEqualTo: _userId)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      if (existingVendor.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Vendor with this phone number already exists'
        };
      }

      final vendorId = _vendorsRef.doc().id;
      final vendor = Vendor(
        id: vendorId,
        name: name,
        phoneNumber: phoneNumber,
        address: address,
        createdAt: DateTime.now(),
        userId: _userId!,
      );

      await _vendorsRef.doc(vendorId).set(vendor.toMap());

      return {'success': true, 'message': 'Vendor added successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Update vendor
  Future<Map<String, dynamic>> updateVendor({
    required String vendorId,
    required String name,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Check if phone number exists for other vendors
      final existingVendor = await _vendorsRef
          .where('userId', isEqualTo: _userId)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      if (existingVendor.docs.isNotEmpty &&
          existingVendor.docs.first.id != vendorId) {
        return {
          'success': false,
          'message': 'Phone number already used by another vendor'
        };
      }

      await _vendorsRef.doc(vendorId).update({
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
      });

      return {'success': true, 'message': 'Vendor updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Delete vendor
  Future<Map<String, dynamic>> deleteVendor(String vendorId) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _vendorsRef.doc(vendorId).delete();

      return {'success': true, 'message': 'Vendor deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get all vendors for current user (Stream)
  Stream<List<Vendor>> getVendors() {
    if (_userId == null) return Stream.value([]);

    return _vendorsRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final vendors = snapshot.docs.map((doc) {
        return Vendor.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      
      // Sort by createdAt descending
      vendors.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return vendors;
    });
  }

  // Get single vendor
  Future<Vendor?> getVendor(String vendorId) async {
    try {
      DocumentSnapshot doc = await _vendorsRef.doc(vendorId).get();
      if (doc.exists) {
        return Vendor.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Search vendors
  Stream<List<Vendor>> searchVendors(String query) {
    if (_userId == null) return Stream.value([]);

    return _vendorsRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final vendors = snapshot.docs.map((doc) {
        return Vendor.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      vendors.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (query.isEmpty) return vendors;
      
      return vendors.where((vendor) {
        return vendor.name.toLowerCase().contains(query.toLowerCase()) ||
            vendor.phoneNumber.toLowerCase().contains(query.toLowerCase()) ||
            vendor.address.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // Get vendor count
  Future<int> getVendorCount() async {
    if (_userId == null) return 0;

    final snapshot = await _vendorsRef
        .where('userId', isEqualTo: _userId)
        .get();

    return snapshot.docs.length;
  }
}