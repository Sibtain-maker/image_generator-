// Non-functional comment for GitHub push. No effect on app behavior.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/stability_ai_service.dart';
import '../models/stability_ai_models.dart';
import '../config/api_config.dart';

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController = TextEditingController();
  
  String _selectedAspectRatio = '1:1';
  String _selectedOutputFormat = 'png';
  bool _isGenerating = false;
  Uint8List? _generatedImageBytes;
  String? _errorMessage;

  StabilityAIService? _stabilityService;
  
  late AnimationController _animationController;
  late AnimationController _glowController;
  late AnimationController _imageController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _imageScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _imageScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _imageController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    _animationController.dispose();
    _glowController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _generateImage() async {
    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a prompt';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedImageBytes = null;
    });

    try {
      _stabilityService = StabilityAIService(apiKey: ApiConfig.stabilityAiApiKey);

      final request = StabilityAIRequest(
        prompt: _promptController.text.trim(),
        negativePrompt: _negativePromptController.text.trim().isEmpty 
            ? null 
            : _negativePromptController.text.trim(),
        aspectRatio: _selectedAspectRatio,
        outputFormat: _selectedOutputFormat,
      );

      final response = await _stabilityService!.generateImage(request);
      final imageBytes = base64Decode(response.imageBase64);

      setState(() {
        _generatedImageBytes = imageBytes;
        _isGenerating = false;
      });
      
      // Animate the image appearance
      _imageController.reset();
      _imageController.forward();
    } catch (e) {
      setState(() {
        _isGenerating = false;
        if (e is StabilityAIError) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'Failed to generate image: ${e.toString()}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D21),
              Color(0xFF1A1A3E),
              Color(0xFF2D1B69),
              Color(0xFF1E1E3F),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background effects
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Positioned(
                  top: 120 + (80 * math.sin(_glowController.value * math.pi)),
                  right: 30 + (50 * math.cos(_glowController.value * math.pi * 0.7)),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.orange.withOpacity(0.2 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Positioned(
                  bottom: 100 + (60 * math.cos(_glowController.value * math.pi * 1.3)),
                  left: 20 + (40 * math.sin(_glowController.value * math.pi * 0.9)),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.teal.withOpacity(0.3 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Main content
            SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title
                            AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3 * _glowAnimation.value),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'AI SYNTHESIS LAB',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                            
                            // Input Controls Container
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1.5,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.03),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Prompt field
                                  _buildFuturisticTextField(
                                    controller: _promptController,
                                    label: 'NEURAL VISION PROMPT',
                                    hint: 'Describe your synthetic reality...',
                                    icon: Icons.auto_awesome,
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Negative prompt field
                                  _buildFuturisticTextField(
                                    controller: _negativePromptController,
                                    label: 'EXCLUSION PARAMETERS',
                                    hint: 'Elements to avoid in synthesis...',
                                    icon: Icons.block,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Settings row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildFuturisticDropdown(
                                          value: _selectedAspectRatio,
                                          label: 'DIMENSION MATRIX',
                                          icon: Icons.aspect_ratio,
                                          items: StabilityAIService.getAvailableAspectRatios(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _selectedAspectRatio = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildFuturisticDropdown(
                                          value: _selectedOutputFormat,
                                          label: 'OUTPUT CODEC',
                                          icon: Icons.image,
                                          items: StabilityAIService.getOutputFormats(),
                                          displayMapper: (format) => format.toUpperCase(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _selectedOutputFormat = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  // Generate button
                                  _buildFuturisticButton(),
                                ],
                              ),
                            ),
                            
                            // Error message
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.5),
                                    width: 1,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.1),
                                      Colors.red.withOpacity(0.05),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade300,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade200,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            // Generated image
                            if (_generatedImageBytes != null) ...[
                              const SizedBox(height: 30),
                              AnimatedBuilder(
                                animation: _glowController,
                                builder: (context, child) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.teal.withOpacity(0.4 * _glowAnimation.value),
                                          blurRadius: 25,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'SYNTHESIZED REALITY',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Image container with animation
                              AnimatedBuilder(
                                animation: _imageController,
                                builder: (context, child) {
                                  return ScaleTransition(
                                    scale: _imageScaleAnimation,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.teal.withOpacity(0.6),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.teal.withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.5),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.memory(
                                          _generatedImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                            
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1 * _glowAnimation.value),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: Colors.orange.withOpacity(0.8),
                letterSpacing: 1.5,
                fontSize: 12,
              ),
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.orange.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.orange,
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuturisticDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    String Function(String)? displayMapper,
    required Function(String?) onChanged,
  }) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1 * _glowAnimation.value),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            dropdownColor: const Color(0xFF1A1A3E),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.teal.withOpacity(0.8),
                letterSpacing: 1,
                fontSize: 10,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.teal.withOpacity(0.7),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.teal.withOpacity(0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.teal.withOpacity(0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.teal,
                  width: 2,
                ),
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  displayMapper != null ? displayMapper(item) : item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        );
      },
    );
  }

  Widget _buildFuturisticButton() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                Colors.orange.withOpacity(0.8),
                Colors.deepOrange.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4 * _glowAnimation.value),
                blurRadius: 25,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isGenerating ? null : _generateImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isGenerating
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'SYNTHESIZING REALITY...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'INITIATE SYNTHESIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
          ),
        );
      },
    );
  }
}