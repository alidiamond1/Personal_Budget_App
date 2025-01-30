import 'package:flutter/material.dart';
import 'sign_in_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  bool isLastPage = false;

  //  Define the onboarding pages with their content
  final List<OnboardingPage> _pages = [
    //  First page - Expense Tracking Feature
    OnboardingPage(
      image:
          'https://img.freepik.com/free-vector/savings-concept-illustration_114360-5766.jpg',
      title: 'Track Your Expenses',
      description:
          'Easily monitor your daily spending and keep your finances in check',
    ),
    //  Second page - Budget Management Feature
    OnboardingPage(
      image:
          'https://img.freepik.com/free-vector/investment-data-concept-illustration_114360-5159.jpg',
      title: 'Smart Budgeting',
      description:
          'Set budgets for different categories and achieve your financial goals',
    ),
    //  Third page - Analytics Feature
    OnboardingPage(
      image:
          'https://img.freepik.com/free-vector/data-analysis-concept-illustration_114360-5240.jpg',
      title: 'Insightful Analytics',
      description:
          'Get detailed insights about your spending habits with beautiful charts',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade800,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  isLastPage = index == _pages.length - 1;
                });
              },
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            ),
            Container(
              alignment: const Alignment(0, 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: WormEffect(
                      spacing: 16,
                      dotColor: Colors.white.withOpacity(0.3),
                      activeDotColor: Colors.white,
                      dotHeight: 10,
                      dotWidth: 10,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        //  Handle navigation - either go to sign in page or show next onboarding page
                        onPressed: () {
                          if (isLastPage) {
                            //  On last page, navigate to sign in screen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignInPage()),
                            );
                          } else {
                            //  Show next onboarding page with animation
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Text(
                          isLastPage ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isLastPage) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      // Skip button to directly navigate to sign in page
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignInPage()),
                        );
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds individual onboarding page with image, title and description
  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            page.image,
            height: 280,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 64),
          Text(
            page.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Class representing each onboarding page with its content
class OnboardingPage {
  final String image; // The URL of the illustration image
  final String title; // The main title of the page
  final String description; // Detailed description of the feature

  OnboardingPage({
    required this.image,
    required this.title,
    required this.description,
  });
}
