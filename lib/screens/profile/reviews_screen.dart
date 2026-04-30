import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/profile_service.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';

/// Reads kitchen reviews from the reviews table in Kitchen DB.
/// Streams live — inserts from User DB's dual-write show up in real time.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _profileService = ProfileService();
  final _orderService = OrderService();
  final _db = Supabase.instance.client;
  String? _cookId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCook();
  }

  Future<void> _loadCook() async {
    final cook = await _profileService.getCurrentProfile();
    if (!mounted) return;
    setState(() {
      _cookId = cook?.id;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text(
          'Customer Reviews',
          style: TextStyle(color: Color(0xFF111814), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111814)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cookId == null
              ? _buildEmpty('Please log in to see reviews', 'Customer reviews will appear here once you log in.')
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db
                      .from('reviews')
                      .stream(primaryKey: ['id'])
                      .eq('cook_id', _cookId!)
                      .order('created_at', ascending: false),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _buildEmpty('Could not load reviews', 'Check your connection and try again.');
                    }
                    final reviews = snap.data ?? [];
                    if (reviews.isEmpty) {
                      return _buildEmpty(
                        'No Reviews Yet',
                        'When customers review your food, they will appear here.',
                      );
                    }
                    final avg = reviews.fold<double>(
                      0,
                      (sum, r) => sum + ((r['kitchen_rating'] ?? 0) as num).toDouble(),
                    ) / reviews.length;
                    return RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reviews.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) return _buildHeader(avg, reviews.length);
                          return _buildReviewCard(reviews[i - 1]);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildHeader(double avg, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < avg.round();
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 18,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              '$count review${count == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r) {
    final rating = ((r['kitchen_rating'] ?? 0) as num).toInt();
    final comment = (r['kitchen_comment'] ?? '').toString();
    final orderId = (r['order_id'] ?? '').toString();
    final customerName = _orderService.getCustomerNameForOrder(orderId);
    final createdAt = DateTime.tryParse(r['created_at'] ?? '');
    String when = '';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inHours < 24) {
        when = '${diff.inHours}h ago';
      } else {
        when = '${diff.inDays}d ago';
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF111814),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14,
                            color: Colors.amber,
                          );
                        }),
                        const Spacer(),
                        Text(when, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: const Color(0xFF111814).withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(String title, String body) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rate_review,
              size: 64,
              color: AppColors.secondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111814).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
