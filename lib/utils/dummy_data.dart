import 'dart:math';
import '../models/cook.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/earnings.dart';
import '../models/issue.dart';

/// This file contains dummy data generators for testing the app
/// In a real app, this data would come from a backend server

class DummyData {
  static final Random _random = Random();

  /// Generate a sample cook profile
  static Cook getSampleCook() {
    return Cook(
      id: 'cook_001',
      phoneNumber: '+919876543210',
      email: 'priya.sharma@example.com',
      kitchenName: 'Maa Ke Haath Ka Khana',
      ownerName: 'Priya Sharma',
      address: '123, Green Park, New Delhi - 110016',
      specialty: 'North Indian',
      profileImageUrl: null,
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  /// Generate sample menu items
  static List<MenuItem> getSampleMenuItems(String cookId) {
    return [
      MenuItem(
        id: 'menu_001',
        cookId: cookId,
        name: 'Dal Makhani with Rice',
        description:
            'Creamy black lentils cooked overnight with butter and cream, served with steamed basmati rice',
        price: 120.0,
        quantityAvailable: 10,
        category: 'Lunch',
        imageUrl: null,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      MenuItem(
        id: 'menu_002',
        cookId: cookId,
        name: 'Paneer Butter Masala',
        description:
            'Cottage cheese cubes in rich tomato and butter gravy with aromatic spices',
        price: 150.0,
        quantityAvailable: 8,
        category: 'Lunch',
        imageUrl: null,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      MenuItem(
        id: 'menu_003',
        cookId: cookId,
        name: 'Aloo Paratha (2 pcs)',
        description:
            'Whole wheat flatbread stuffed with spiced potato filling, served with curd and pickle',
        price: 80.0,
        quantityAvailable: 15,
        category: 'Breakfast',
        imageUrl: null,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      MenuItem(
        id: 'menu_004',
        cookId: cookId,
        name: 'Chole Bhature',
        description: 'Spicy chickpea curry served with fluffy deep-fried bread',
        price: 100.0,
        quantityAvailable: 12,
        category: 'Breakfast',
        imageUrl: null,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      MenuItem(
        id: 'menu_005',
        cookId: cookId,
        name: 'Rajma Chawal',
        description:
            'Red kidney beans curry cooked in tomato gravy with steamed rice',
        price: 110.0,
        quantityAvailable: 10,
        category: 'Lunch',
        imageUrl: null,
        isAvailable: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MenuItem(
        id: 'menu_006',
        cookId: cookId,
        name: 'Samosa (4 pcs)',
        description: 'Crispy fried pastry filled with spiced potatoes and peas',
        price: 40.0,
        quantityAvailable: 20,
        category: 'Snacks',
        imageUrl: null,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// Generate sample orders
  static List<Order> getSampleOrders(String cookId) {
    final now = DateTime.now();

    return [
      Order(
        id: 'order_001',
        cookId: cookId,
        customerName: 'Rahul Kumar',
        customerPhone: '+919876543211',
        deliveryAddress: '45, Sector 18, Noida - 201301',
        items: [
          OrderItem(
            menuItemId: 'menu_001',
            name: 'Dal Makhani with Rice',
            quantity: 2,
            price: 120.0,
          ),
          OrderItem(
            menuItemId: 'menu_006',
            name: 'Samosa (4 pcs)',
            quantity: 1,
            price: 40.0,
          ),
        ],
        totalAmount: 280.0,
        status: OrderStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      Order(
        id: 'order_002',
        cookId: cookId,
        customerName: 'Anjali Verma',
        customerPhone: '+919876543212',
        deliveryAddress: '78, Vasant Vihar, New Delhi - 110057',
        items: [
          OrderItem(
            menuItemId: 'menu_002',
            name: 'Paneer Butter Masala',
            quantity: 1,
            price: 150.0,
          ),
        ],
        totalAmount: 150.0,
        status: OrderStatus.accepted,
        createdAt: now.subtract(const Duration(minutes: 15)),
        acceptedAt: now.subtract(const Duration(minutes: 14)),
      ),
      Order(
        id: 'order_003',
        cookId: cookId,
        customerName: 'Vikram Singh',
        customerPhone: '+919876543213',
        deliveryAddress: '12, Lajpat Nagar, New Delhi - 110024',
        items: [
          OrderItem(
            menuItemId: 'menu_003',
            name: 'Aloo Paratha (2 pcs)',
            quantity: 2,
            price: 80.0,
          ),
        ],
        totalAmount: 160.0,
        status: OrderStatus.preparing,
        createdAt: now.subtract(const Duration(minutes: 30)),
        acceptedAt: now.subtract(const Duration(minutes: 28)),
      ),
      Order(
        id: 'order_004',
        cookId: cookId,
        customerName: 'Sneha Patel',
        customerPhone: '+919876543214',
        deliveryAddress: '56, Connaught Place, New Delhi - 110001',
        items: [
          OrderItem(
            menuItemId: 'menu_005',
            name: 'Rajma Chawal',
            quantity: 1,
            price: 110.0,
          ),
          OrderItem(
            menuItemId: 'menu_006',
            name: 'Samosa (4 pcs)',
            quantity: 2,
            price: 40.0,
          ),
        ],
        totalAmount: 190.0,
        status: OrderStatus.ready,
        createdAt: now.subtract(const Duration(hours: 1)),
        acceptedAt: now.subtract(const Duration(minutes: 58)),
      ),
      Order(
        id: 'order_005',
        cookId: cookId,
        customerName: 'Amit Gupta',
        customerPhone: '+919876543215',
        deliveryAddress: '89, Karol Bagh, New Delhi - 110005',
        items: [
          OrderItem(
            menuItemId: 'menu_004',
            name: 'Chole Bhature',
            quantity: 2,
            price: 100.0,
          ),
        ],
        totalAmount: 200.0,
        status: OrderStatus.completed,
        createdAt: now.subtract(const Duration(hours: 2)),
        acceptedAt: now.subtract(const Duration(hours: 1, minutes: 58)),
        completedAt: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
    ];
  }

  /// Generate sample daily earnings
  static DailyEarnings getSampleDailyEarnings(String cookId) {
    return DailyEarnings(
      cookId: cookId,
      date: DateTime.now(),
      totalRevenue: 1250.0,
      totalOrders: 12,
      completedOrders: 10,
      rejectedOrders: 2,
    );
  }

  /// Generate sample earnings transactions
  static List<EarningsTransaction> getSampleTransactions() {
    final now = DateTime.now();

    return [
      EarningsTransaction(
        id: 'txn_001',
        orderId: 'order_005',
        customerName: 'Amit Gupta',
        amount: 200.0,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
      EarningsTransaction(
        id: 'txn_002',
        orderId: 'order_006',
        customerName: 'Neha Sharma',
        amount: 150.0,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      EarningsTransaction(
        id: 'txn_003',
        orderId: 'order_007',
        customerName: 'Rajesh Kumar',
        amount: 280.0,
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      EarningsTransaction(
        id: 'txn_004',
        orderId: 'order_008',
        customerName: 'Pooja Singh',
        amount: 120.0,
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
      EarningsTransaction(
        id: 'txn_005',
        orderId: 'order_009',
        customerName: 'Sanjay Verma',
        amount: 340.0,
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  /// Generate a random customer name
  static String getRandomCustomerName() {
    final firstNames = [
      'Rahul',
      'Priya',
      'Amit',
      'Sneha',
      'Vikram',
      'Anjali',
      'Rajesh',
      'Neha',
    ];
    final lastNames = [
      'Kumar',
      'Sharma',
      'Verma',
      'Singh',
      'Patel',
      'Gupta',
      'Reddy',
      'Shah',
    ];
    return '${firstNames[_random.nextInt(firstNames.length)]} ${lastNames[_random.nextInt(lastNames.length)]}';
  }

  /// Generate a random phone number
  static String getRandomPhone() {
    return '+9198765${_random.nextInt(90000) + 10000}';
  }

  /// Generate a random address
  static String getRandomAddress() {
    final areas = [
      'Sector 18, Noida',
      'Vasant Vihar, Delhi',
      'Lajpat Nagar, Delhi',
      'Connaught Place, Delhi',
      'Karol Bagh, Delhi',
      'Green Park, Delhi',
    ];
    return '${_random.nextInt(100) + 1}, ${areas[_random.nextInt(areas.length)]}';
  }

  /// Generate sample issues/complaints
  static List<Issue> getSampleIssues() {
    final now = DateTime.now();

    return [
      Issue(
        id: 'issue_001',
        title: 'Order delivery delayed',
        description:
            'Customer complained that the delivery took 45 minutes instead of the promised 30 minutes. Need to improve coordination with delivery partners.',
        reportedBy: 'Rajesh Kumar',
        reporterType: ReporterType.admin,
        status: IssueStatus.open,
        priority: IssuePriority.high,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Issue(
        id: 'issue_002',
        title: 'Payment not received',
        description:
            'Completed delivery for order #1234 but payment has not been credited to my account yet. Please check the payment gateway.',
        reportedBy: 'Vikram Singh',
        reporterType: ReporterType.deliveryBoy,
        status: IssueStatus.inProgress,
        priority: IssuePriority.high,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      Issue(
        id: 'issue_003',
        title: 'App crashing on order acceptance',
        description:
            'The app crashes when trying to accept orders. This is affecting business. Please fix urgently.',
        reportedBy: 'Amit Sharma',
        reporterType: ReporterType.deliveryBoy,
        status: IssueStatus.open,
        priority: IssuePriority.high,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      Issue(
        id: 'issue_004',
        title: 'Incorrect kitchen address shown',
        description:
            'The pickup address shown to delivery partners is incorrect. It shows the old address instead of the updated one.',
        reportedBy: 'Priya Verma',
        reporterType: ReporterType.admin,
        status: IssueStatus.resolved,
        priority: IssuePriority.medium,
        createdAt: now.subtract(const Duration(days: 1)),
        resolvedAt: now.subtract(const Duration(hours: 12)),
      ),
      Issue(
        id: 'issue_005',
        title: 'Unable to update menu items',
        description:
            'Getting an error when trying to update menu item prices. The save button is not working properly.',
        reportedBy: 'Sneha Patel',
        reporterType: ReporterType.admin,
        status: IssueStatus.inProgress,
        priority: IssuePriority.medium,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      Issue(
        id: 'issue_006',
        title: 'GPS navigation issues',
        description:
            'GPS is not working properly in the delivery app. Having trouble finding customer locations.',
        reportedBy: 'Rahul Gupta',
        reporterType: ReporterType.deliveryBoy,
        status: IssueStatus.open,
        priority: IssuePriority.medium,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Issue(
        id: 'issue_007',
        title: 'Notification delay',
        description:
            'Not receiving order notifications on time. Sometimes notifications arrive 10-15 minutes late.',
        reportedBy: 'Anjali Reddy',
        reporterType: ReporterType.deliveryBoy,
        status: IssueStatus.resolved,
        priority: IssuePriority.low,
        createdAt: now.subtract(const Duration(days: 3)),
        resolvedAt: now.subtract(const Duration(days: 2, hours: 12)),
      ),
      Issue(
        id: 'issue_008',
        title: 'Commission rate clarification needed',
        description:
            'Need clarification on the commission structure for different order values. The current information is unclear.',
        reportedBy: 'Sanjay Shah',
        reporterType: ReporterType.admin,
        status: IssueStatus.resolved,
        priority: IssuePriority.low,
        createdAt: now.subtract(const Duration(days: 4)),
        resolvedAt: now.subtract(const Duration(days: 3, hours: 8)),
      ),
      Issue(
        id: 'issue_009',
        title: 'Customer contact number not visible',
        description:
            'Unable to see customer contact number for delivery coordination. This is causing delivery delays.',
        reportedBy: 'Deepak Kumar',
        reporterType: ReporterType.deliveryBoy,
        status: IssueStatus.open,
        priority: IssuePriority.high,
        createdAt: now.subtract(const Duration(hours: 10)),
      ),
      Issue(
        id: 'issue_010',
        title: 'Earnings report discrepancy',
        description:
            'The earnings shown in the app do not match with the actual orders completed. Please verify the calculation.',
        reportedBy: 'Neha Singh',
        reporterType: ReporterType.admin,
        status: IssueStatus.inProgress,
        priority: IssuePriority.medium,
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
      ),
      Issue(
        id: 'issue_011',
        title: 'Food quality issue',
        description:
            'The dal makhani I received was cold and not properly cooked. Very disappointed with the quality.',
        reportedBy: 'Karan Mehta',
        reporterType: ReporterType.customer,
        status: IssueStatus.open,
        priority: IssuePriority.high,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      Issue(
        id: 'issue_012',
        title: 'Wrong order delivered',
        description:
            'I ordered paneer butter masala but received dal makhani instead. Please be more careful with order packaging.',
        reportedBy: 'Pooja Desai',
        reporterType: ReporterType.customer,
        status: IssueStatus.inProgress,
        priority: IssuePriority.high,
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
      ),
      Issue(
        id: 'issue_013',
        title: 'Missing items in order',
        description:
            'I ordered 2 samosas but only received 1. Please ensure all items are included in the package.',
        reportedBy: 'Arjun Nair',
        reporterType: ReporterType.customer,
        status: IssueStatus.resolved,
        priority: IssuePriority.medium,
        createdAt: now.subtract(const Duration(days: 2)),
        resolvedAt: now.subtract(const Duration(days: 1, hours: 12)),
      ),
      Issue(
        id: 'issue_014',
        title: 'Refund not processed',
        description:
            'My order was cancelled but the refund has not been processed yet. It has been 5 days already.',
        reportedBy: 'Meera Shah',
        reporterType: ReporterType.customer,
        status: IssueStatus.inProgress,
        priority: IssuePriority.high,
        createdAt: now.subtract(const Duration(days: 3, hours: 8)),
      ),
      Issue(
        id: 'issue_015',
        title: 'Delivery person was rude',
        description:
            'The delivery person was very rude and unprofessional. Please train your staff better.',
        reportedBy: 'Suresh Yadav',
        reporterType: ReporterType.customer,
        status: IssueStatus.open,
        priority: IssuePriority.medium,
        createdAt: now.subtract(const Duration(hours: 15)),
      ),
    ];
  }
}
