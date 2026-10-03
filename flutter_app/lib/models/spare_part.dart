import 'package:cloud_firestore/cloud_firestore.dart';

class SparePart {
  final String id;
  final String title;
  final String carBrand;
  final String carModel;
  final String category;
  final String subcategory;
  final String condition;
  final double price;
  final bool isNegotiable;
  final String location;
  final String district;
  final String? contactName;
  final String? contactPhone;
  final String? description;
  final String imageUrl;
  final List<String> imageUrls;
  final String sellerId;
  final String? sellerEmail;
  final DateTime createdAt;
  final bool isSold;
  final bool verified;
  final int views;
  final String? oemNumber;
  final String? compatibleYears;
  final String status;
  final bool approved;
  final bool featured;
  final bool reported;
  final bool isDeleted;

  final String isSoldLocation = ''; // Helper
  final double? latitude;
  final double? longitude;

  // Convenience getters/aliases
  String get year => compatibleYears ?? '';
  String get userId => sellerId;
  List<String> get images => imageUrls;

  SparePart({
    required this.id,
    required this.title,
    required this.carBrand,
    required this.carModel,
    required this.category,
    this.subcategory = '',
    required this.condition,
    required this.price,
    required this.isNegotiable,
    required this.location,
    this.district = '',
    this.contactName,
    this.contactPhone,
    this.description,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.sellerId,
    this.sellerEmail,
    required this.createdAt,
    this.isSold = false,
    this.verified = true,
    this.views = 0,
    this.oemNumber,
    this.compatibleYears,
    this.status = 'approved',
    this.approved = true,
    this.featured = false,
    this.reported = false,
    this.isDeleted = false,
    this.latitude,
    this.longitude,
  });

  SparePart copyWith({
    String? id,
    String? title,
    String? carBrand,
    String? carModel,
    String? category,
    String? subcategory,
    String? condition,
    double? price,
    bool? isNegotiable,
    String? location,
    String? district,
    String? contactName,
    String? contactPhone,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    String? sellerId,
    String? sellerEmail,
    DateTime? createdAt,
    bool? isSold,
    bool? verified,
    int? views,
    String? oemNumber,
    String? compatibleYears,
    String? status,
    bool? approved,
    bool? featured,
    bool? reported,
    bool? isDeleted,
    double? latitude,
    double? longitude,
  }) {
    return SparePart(
      id: id ?? this.id,
      title: title ?? this.title,
      carBrand: carBrand ?? this.carBrand,
      carModel: carModel ?? this.carModel,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      isNegotiable: isNegotiable ?? this.isNegotiable,
      location: location ?? this.location,
      district: district ?? this.district,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId ?? this.sellerId,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      createdAt: createdAt ?? this.createdAt,
      isSold: isSold ?? this.isSold,
      verified: verified ?? this.verified,
      views: views ?? this.views,
      oemNumber: oemNumber ?? this.oemNumber,
      compatibleYears: compatibleYears ?? this.compatibleYears,
      status: status ?? this.status,
      approved: approved ?? this.approved,
      featured: featured ?? this.featured,
      reported: reported ?? this.reported,
      isDeleted: isDeleted ?? this.isDeleted,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory SparePart.fromJson(Map<String, dynamic> data, {String id = ''}) {
    DateTime created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is int) {
      created = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
    } else {
      created = DateTime.now();
    }

    List<String> images = [];
    if (data['imageUrls'] is List) {
      images = List<String>.from(data['imageUrls']);
    } else if (data['images'] is List) {
      images = List<String>.from(data['images']);
    } else if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      images = [data['imageUrl'].toString()];
    }

    final mainImage = (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
        ? data['imageUrl'].toString()
        : (images.isNotEmpty ? images.first : '');

    final bool isNegotiable = (data['isNegotiable'] is bool)
        ? data['isNegotiable'] as bool
        : (data['negotiable'] is bool
            ? data['negotiable'] as bool
            : (data['isNegotiable'] == true || data['negotiable'] == true));

    return SparePart(
      id: id.isNotEmpty ? id : (data['id']?.toString() ?? ''),
      title: data['title'] ?? '',
      carBrand: data['carBrand'] ?? data['brand'] ?? '',
      carModel: data['carModel'] ?? data['model'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      condition: data['condition'] ?? 'Used - Good',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      isNegotiable: isNegotiable,
      location: data['location'] ?? 'India',
      district: data['district'] ?? '',
      contactName: data['contactName'] ?? data['sellerName'] ?? data['name'],
      contactPhone: data['contactPhone'] ?? data['phone'] ?? data['sellerPhone'],
      description: data['description'],
      imageUrl: mainImage,
      imageUrls: images.isNotEmpty ? images : (mainImage.isNotEmpty ? [mainImage] : []),
      sellerId: data['sellerId'] ?? data['userId'] ?? '',
      sellerEmail: data['sellerEmail'] ?? data['email'],
      createdAt: created,
      isSold: data['isSold'] == true || data['sold'] == true || (data['status']?.toString().toLowerCase() == 'sold'),
      verified: data['verified'] != false,
      views: data['views'] is int ? data['views'] : 0,
      oemNumber: data['oemNumber'],
      compatibleYears: data['compatibleYears'] ?? data['year']?.toString(),
      status: data['status'] ?? 'approved',
      approved: data['approved'] != false,
      featured: data['featured'] == true,
      reported: data['reported'] == true,
      isDeleted: data['isDeleted'] == true,
      latitude: (data['latitude'] is num)
          ? (data['latitude'] as num).toDouble()
          : (data['lat'] is num ? (data['lat'] as num).toDouble() : null),
      longitude: (data['longitude'] is num)
          ? (data['longitude'] as num).toDouble()
          : (data['lng'] is num ? (data['lng'] as num).toDouble() : null),
    );
  }

  factory SparePart.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SparePart.fromJson(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'carBrand': carBrand,
      'carModel': carModel,
      'category': category,
      'subcategory': subcategory,
      'condition': condition,
      'price': price,
      'isNegotiable': isNegotiable,
      'location': location,
      'district': district,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'description': description,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'sellerId': sellerId,
      'sellerEmail': sellerEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'isSold': isSold,
      'verified': verified,
      'views': views,
      'oemNumber': oemNumber,
      'compatibleYears': compatibleYears,
      'status': status,
      'approved': approved,
      'featured': featured,
      'reported': reported,
      'isDeleted': isDeleted,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
