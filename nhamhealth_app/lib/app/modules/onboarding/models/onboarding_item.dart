class OnboardingItem {
  const OnboardingItem({
    required this.imagePath,
    required this.title,
    required this.description,
    this.accentTitle,
    this.titleAboveImage = false,
    this.showBrandHeader = true,
  });

  final String imagePath;
  final String title;
  final String description;
  final String? accentTitle;
  final bool titleAboveImage;
  final bool showBrandHeader;
}
