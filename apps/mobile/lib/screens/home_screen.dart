
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_button.dart';
import 'package:svezko_app/widgets/app_bottom_navigation.dart';
import '../widgets/app_text_field.dart';
import '../widgets/product_card.dart';
import 'item_detail_screen.dart';
import 'package:go_router/go_router.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 16,
        title: const Row(
          children: [
            SizedBox(width: 10),
            Text('Svezko'),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppTextField(
              label: 'Ime i prezime',
              hint: 'Unesi ime i prezime',
              prefixIcon: const Icon(Icons.person_outline),
            ),

            const SizedBox(height: 20),

            ProductCard(
              name: 'Domace maline',
              producer: 'Bojan Matic',
              price: 150,
              unit: 'kg',
              onAddToCart: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proizvod je dodat u korpu!'),
                  ),
                );
              },
              onTap: () {
                context.push('/item-detail');
              },
            ),

            const SizedBox(height: 20),

            AppButton(
              text: 'Moje porudžbine',
              onPressed: () => context.push('/orders'),
            ),
          ],
        ),
      ),


      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
        onTap: (index) {
        },
      ),

    );
  }
}
