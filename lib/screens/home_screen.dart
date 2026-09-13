
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'search_providers_screen.dart';
import 'service_providers_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> services = [
    {
      'name': 'Waste Pickup',
      'icon': Icons.delete_outline,
    },
    {
      'name': 'Tailor',
      'icon': Icons.person_outline,
    },
    {
      'name': 'Shoe Seller',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'name': 'Vegetables and Kayan Miya',
      'icon': Icons.grass,
    },
    {
      'name': 'Meat Seller',
      'icon': Icons.restaurant,
    },
    {
      'name': 'Plumber',
      'icon': Icons.plumbing,
    },
    {
      'name': 'Electrician',
      'icon': Icons.electrical_services,
    },
    {
      'name': 'Carpenter',
      'icon': Icons.carpenter,
    },
    {
      'name': 'Phone Repair',
      'icon': Icons.phone_android,
    },
    {
      'name': 'Welding',
      'icon': Icons.home_repair_service,
    },
    {
      'name': 'Car Wash',
      'icon': Icons.local_car_wash,
    },
    {
      'name': 'Gardener',
      'icon': Icons.grass,
    },
    {
      'name': 'Gas Refill',
      'icon': Icons.gas_meter,
    },
    {
      'name': 'POS Agent',
      'icon': Icons.point_of_sale,
    },
    {
      'name': 'Car Repair',
      'icon': Icons.car_repair,
    },
    {
      'name': 'Cleaning',
      'icon': Icons.cleaning_services,
    },
    {
      'name': 'Laundry',
      'icon': Icons.local_laundry_service,
    },
    {
      'name': 'Food Delivery',
      'icon': Icons.delivery_dining,
    },
    {
      'name': 'Lesson Teacher',
      'icon': Icons.book_outlined,
    },
    {
      'name': 'Book Barbing Queue',
      'icon': Icons.content_cut,
    },
    {
      'name': 'Mai Kitso',
      'icon': Icons.person_outline,
    },
    {
      'name': 'Mai Lalle',
      'icon': Icons.person_outline,
    },
    {
      'name': 'Book Salon Queue',
      'icon': Icons.spa_outlined,
    },
    {
      'name': 'Fish Seller',
      'icon': Icons.set_meal_outlined,
    },
    {
      'name': 'Painter',
      'icon': Icons.format_paint_outlined,
    },
    {
      'name': 'Delivery Services',
      'icon': Icons.local_shipping_outlined,
    },
    {
      'name': 'Order Snacks',
      'icon': Icons.fastfood_outlined,
    },
    {
      'name': 'Napep Booking',
      'icon': Icons.two_wheeler,
    },
    {
      'name': 'Electronic Appliances Repair',
      'icon': Icons.electrical_services,
    },
    {
      'name': 'Animal Clinic',
      'icon': Icons.pets_outlined,
    },
    {
      'name': 'Chicken Booking, Feeds and Drugs',
      'icon': Icons.egg_outlined,
    },
    {
      'name': 'Diagnostic Centre',
      'icon': Icons.local_hospital_outlined,
    },
    {
      'name': 'Hospital',
      'icon': Icons.local_hospital,
    },
    {
      'name': 'Building Materials',
      'icon': Icons.construction,
    },
    {
      'name': 'Plumbing Materials Seller',
      'icon': Icons.plumbing,
    },
    {
      'name': 'Carpentry Materials Seller',
      'icon': Icons.handyman_outlined,
    },
    {
      'name': 'Cement Seller',
      'icon': Icons.foundation,
    },
    {
      'name': 'Pharmacy',
      'icon': Icons.local_pharmacy,
    },
    {
      'name': 'Fabrics (Shadda/Yadi) Dealer',
      'icon': Icons.checkroom_outlined,
    },
    {
      'name': 'Abaya Seller',
      'icon': Icons.checkroom_outlined,
    },
    {
      'name': 'Football Kits Seller',
      'icon': Icons.sports_soccer_outlined,
    },
    {
      'name': 'Kitchen Utensils Seller',
      'icon': Icons.kitchen_outlined,
    },
    {
      'name': 'Restaurant',
      'icon': Icons.restaurant_outlined,
    },
    {
      'name': 'Graphic Designer',
      'icon': Icons.design_services_outlined,
    },
    {
      'name': 'Building Labourer',
      'icon': Icons.engineering_outlined,
    },
    {
      'name': 'Construction Firms',
      'icon': Icons.construction,
    },
    {
      'name': 'Real Estate Agent',
      'icon': Icons.real_estate_agent_outlined,
    },
    {
      'name': 'Pure Water Distributor',
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'Cloths/Baby Cloths Seller',
      'icon': Icons.child_friendly_outlined,
    },
    {
      'name': 'Make-up Salon',
      'icon': Icons.face_retouching_natural,
    },
    {
      'name': 'Printing, Writing and Reading Materials (Books)',
      'icon': Icons.menu_book_outlined,
    },
    {
      'name': 'Electronic Appliances Seller',
      'icon': Icons.devices_other_outlined,
    },
    {
      'name': 'Solar Installer',
      'icon': Icons.solar_power,
    },
    {
      'name': 'Satellite Dish Repair',
      'icon': Icons.satellite_alt,
    },
    {
      'name': 'Event Centre',
      'icon': Icons.event_outlined,
    },
    {
      'name': 'Laptop Seller',
      'icon': Icons.laptop_mac,
    },
    {
      'name': 'Phone Seller',
      'icon': Icons.phone_android,
    },
    {
      'name': 'TV Repair',
      'icon': Icons.tv,
    },
    {
      'name': 'Flowers Seller',
      'icon': Icons.local_florist_outlined,
    },
    {
      'name': 'Islamic Lesson Teacher',
      'icon': Icons.menu_book_outlined,
    },
    {
      'name': 'Rental Services',
      'icon': Icons.roofing,
    },
    {
      'name': 'Beds Seller',
      'icon': Icons.bed_outlined,
    },
    {
      'name': 'Furniture Seller',
      'icon': Icons.chair_outlined,
    },
    {
      'name': 'Suya Spot',
      'icon': Icons.outdoor_grill_outlined,
    },
    {
      'name': 'Animals Seller',
      'icon': Icons.pets_outlined,
    },
    {
      'name': 'Rice Seller',
      'icon': Icons.grain,
    },
    {
      'name': 'Grain Seller',
      'icon': Icons.grain,
    },
    {
      'name': 'Yam Seller',
      'icon': Icons.eco_outlined,
    },
    {
      'name': 'Fruits Seller',
      'icon': Icons.apple_outlined,
    },
    {
      'name': 'Rubber Home Equipment Seller',
      'icon': Icons.home_work_outlined,
    },
    {
      'name': 'Palm Oil/Groundnut Oil Seller',
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'Petrol Black Marketer',
      'icon': Icons.local_gas_station_outlined,
    },
    {
      'name': 'Women Beauty Products Seller',
      'icon': Icons.spa_outlined,
    },
    {
      'name': 'School',
      'icon': Icons.school_outlined,
    },
    {
      'name': 'Other Services',
      'icon': Icons.more_horiz_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final columns = width >= 1100
        ? 5
        : width >= 760
            ? 4
            : width >= 520
                ? 3
                : 2;

    final featured = services.take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 20,
            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Icon(
                        Icons.home_work_rounded,
                        color: AppColors.primary,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gida Services',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Local help, made simple',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Search providers',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SearchProvidersScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _hero(context),

                  const SizedBox(height: 28),

                  _sectionTitle(
                    context,
                    'Popular services',
                    'Quickly find what you need',
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    height: 126,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _featuredService(
                          context,
                          featured[index],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  _sectionTitle(
                    context,
                    'All services',
                    '${services.length} categories',
                  ),

                  const SizedBox(height: 14),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: services.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: columns == 2
                          ? 1.03
                          : columns == 3
                              ? 1.02
                              : 1.08,
                    ),
                    itemBuilder: (context, index) {
                      return _serviceCard(
                        context,
                        services[index],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 22,
        compact ? 20 : 22,
        compact ? 16 : 18,
        compact ? 18 : 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'NEED A HAND?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  compact
                      ? 'Get trusted help\nwhen you need it.'
                      : 'Get trusted help\nwhen you need it.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 21 : 24,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'From repairs to everyday essentials, discover local providers in a few taps.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 17),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchProvidersScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.explore_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Explore providers',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: compact ? 64 : 78,
            height: compact ? 64 : 78,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return Icon(
                    Icons.home_work_rounded,
                    color: AppColors.primary,
                    size: compact ? 30 : 38,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featuredService(
    BuildContext context,
    Map<String, dynamic> service,
  ) {
    final name = service['name'] as String;
    final icon = service['icon'] as IconData;

    return SizedBox(
      width: 118,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openCategory(context, name),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(
    BuildContext context,
    Map<String, dynamic> service,
  ) {
    final name = service['name'] as String;
    final icon = service['icon'] as IconData;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openCategory(context, name),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategory(
    BuildContext context,
    String category,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceProvidersScreen(
          category: category,
        ),
      ),
    );
  }
}
