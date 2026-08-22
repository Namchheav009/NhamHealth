import 'package:flutter/material.dart';

class ProfilePostCard extends StatelessWidget {
  const ProfilePostCard({super.key});

  static const green = Color(0xFF009B46);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 21,
                backgroundImage: AssetImage('assets/images/profile/profile.jpg'),
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sophia Martinez',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 3),

                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text('2h ago', style: TextStyle(color: Colors.grey)),
                        Text(
                          'Nutritionist',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Text(
                'Following',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Healthy breakfast idea!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 6),

          const Text(
            'Avocado toast with poached egg and fresh fruits.\n'
            'Simple, quick and nutritious!',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(0xFF555555),
            ),
          ),

          const SizedBox(height: 8),

          const Wrap(
            spacing: 8,
            children: [
              _Tag(text: '#HealthyMeal'),
              _Tag(text: '#HighProtein'),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'assets/images/profile/profile.jpg',
              width: double.infinity,
              height: 170,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F6EA),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: ProfilePostCard.green,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
