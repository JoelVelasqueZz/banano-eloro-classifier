import 'package:flutter/material.dart';

class SampleImage {
  final String asset;
  final String label;

  const SampleImage({required this.asset, required this.label});
}

const List<SampleImage> sampleImages = [
  SampleImage(asset: 'assets/galeria/sigatoka.jpeg', label: 'Sigatoka'),
  SampleImage(asset: 'assets/galeria/cordana.jpeg', label: 'Cordana'),
  SampleImage(
    asset: 'assets/galeria/pestalotiopsis.jpeg',
    label: 'Pestalotiopsis',
  ),
  SampleImage(asset: 'assets/galeria/healthy.jpeg', label: 'Healthy'),
  SampleImage(asset: 'assets/galeria/moko_disease.jpg', label: 'Moko'),
  SampleImage(
    asset: 'assets/galeria/panama_disease.jpg',
    label: 'Panama_Disease',
  ),
  SampleImage(asset: 'assets/galeria/insect_pest.jpg', label: 'Insect_Pest'),
];

/// Lets the user pick one of the bundled sample images instead of using the
/// camera or device gallery, useful for demos without depending on adb push.
class SampleGalleryScreen extends StatelessWidget {
  const SampleGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galería de prueba')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: sampleImages.length,
        itemBuilder: (context, index) {
          final sample = sampleImages[index];
          return InkWell(
            onTap: () => Navigator.pop(context, sample),
            borderRadius: BorderRadius.circular(12),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(sample.asset, fit: BoxFit.cover, width: double.infinity),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      sample.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
