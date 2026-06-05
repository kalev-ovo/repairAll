class OrderModel {
  final int id;
  final String orderNo;
  final int? customerId;
  final int? workerId;
  final int categoryId;
  final String description;
  final String images;
  final String address;
  final double lat;
  final double lng;
  final String status;
  final int price;
  final String cancelReason;
  final String createdAt;
  final String? acceptedAt;
  final String? arrivedAt;
  final String? completedAt;
  final String? customerName;
  final String? workerName;
  final String? categoryName;
  final double distance;

  OrderModel({
    required this.id,
    required this.orderNo,
    this.customerId,
    this.workerId,
    required this.categoryId,
    required this.description,
    required this.images,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    required this.price,
    required this.cancelReason,
    required this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.completedAt,
    this.customerName,
    this.workerName,
    this.categoryName,
    this.distance = 0,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      orderNo: json['order_no'] as String? ?? '',
      customerId: json['customer_id'] as int?,
      workerId: json['worker_id'] as int?,
      categoryId: json['category_id'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      images: json['images'] as String? ?? '[]',
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      cancelReason: json['cancel_reason'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      acceptedAt: json['accepted_at'] as String?,
      arrivedAt: json['arrived_at'] as String?,
      completedAt: json['completed_at'] as String?,
      customerName: json['customer_name'] as String?,
      workerName: json['worker_name'] as String?,
      categoryName: json['category_name'] as String?,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
    );
  }

  String get statusText {
    switch (status) {
      case 'pending': return '待接单';
      case 'accepted': return '已接单';
      case 'ongoing': return '进行中';
      case 'completed': return '已完成';
      case 'cancelled': return '已取消';
      default: return status;
    }
  }

  bool get canCancel => ['pending', 'accepted', 'ongoing'].contains(status);

  String get formattedDistance {
    if (distance <= 0) return '';
    if (distance >= 9999) return '';
    if (distance < 1) return '${(distance * 1000).toInt()}m';
    return '${distance.toStringAsFixed(1)}km';
  }
}
