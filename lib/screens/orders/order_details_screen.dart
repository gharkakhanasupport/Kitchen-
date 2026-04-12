import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';

/// Order Details Screen
/// Shows detailed information about an order with accept/reject/update status actions
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final _orderService = OrderService();
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
    });

    final order = await _orderService.getOrderById(widget.orderId);
    
    setState(() {
      _order = order;
      _isLoading = false;
    });
  }

  Future<void> _acceptOrder() async {
    final success = await _orderService.acceptOrder(widget.orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadOrder();
    }
  }

  Future<void> _rejectOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('Are you sure you want to reject this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _orderService.rejectOrder(widget.orderId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    final success = await _orderService.updateOrderStatus(widget.orderId, newStatus);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.toString().split('.').last}'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadOrder();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order!.id.substring(_order!.id.length - 6)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Details',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    Row(
                      children: [
                        Icon(Icons.person, size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(_order!.customerName, style: AppTextStyles.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    Row(
                      children: [
                        Icon(Icons.phone, size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(_order!.customerPhone, style: AppTextStyles.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(_order!.deliveryAddress, style: AppTextStyles.bodyLarge),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Order Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Items',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    ..._order!.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(item.name, style: AppTextStyles.bodyLarge),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )),
                    
                    const Divider(height: AppSpacing.lg),
                    
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total Amount',
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        Text(
                          '₹${_order!.totalAmount.toStringAsFixed(0)}',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Action Buttons
            if (_order!.status == OrderStatus.pending) ...[
              FilledButton(
                onPressed: _acceptOrder,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  backgroundColor: AppColors.success,
                ),
                child: const Text('Accept Order'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _rejectOrder,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Reject Order'),
              ),
            ] else if (_order!.status == OrderStatus.accepted) ...[
              FilledButton(
                onPressed: () => _updateStatus(OrderStatus.preparing),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('Start Preparing'),
              ),
            ] else if (_order!.status == OrderStatus.preparing) ...[
              FilledButton(
                onPressed: () => _updateStatus(OrderStatus.ready),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const Text('Mark as Ready'),
              ),
            ] else if (_order!.status == OrderStatus.ready) ...[
              FilledButton(
                onPressed: () => _updateStatus(OrderStatus.completed),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  backgroundColor: AppColors.success,
                ),
                child: const Text('Complete Order'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
