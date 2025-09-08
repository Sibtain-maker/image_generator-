import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/stability_ai_service.dart';
import '../services/api_key_service.dart';
import '../models/stability_ai_models.dart';

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  
  String _selectedAspectRatio = '1:1';
  String _selectedOutputFormat = 'png';
  bool _isGenerating = false;
  Uint8List? _generatedImageBytes;
  String? _errorMessage;

  StabilityAIService? _stabilityService;

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedApiKey() async {
    final savedApiKey = await ApiKeyService.getApiKey();
    if (savedApiKey != null) {
      setState(() {
        _apiKeyController.text = savedApiKey;
      });
    }
  }

  Future<void> _generateImage() async {
    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a prompt';
      });
      return;
    }

    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your Stability AI API key';
      });
      return;
    }

    if (!ApiKeyService.isValidApiKey(apiKey)) {
      setState(() {
        _errorMessage = 'Invalid API key format. It should start with "sk-"';
      });
      return;
    }

    await ApiKeyService.saveApiKey(apiKey);

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedImageBytes = null;
    });

    try {
      _stabilityService = StabilityAIService(apiKey: _apiKeyController.text.trim());

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
      appBar: AppBar(
        title: const Text('Generate Image'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Stability AI API Key',
                hintText: 'Enter your API key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'Describe the image you want to generate...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _negativePromptController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Negative Prompt (Optional)',
                hintText: 'What to avoid in the image...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAspectRatio,
                    decoration: const InputDecoration(
                      labelText: 'Aspect Ratio',
                      border: OutlineInputBorder(),
                    ),
                    items: StabilityAIService.getAvailableAspectRatios()
                        .map((ratio) => DropdownMenuItem(
                              value: ratio,
                              child: Text(ratio),
                            ))
                        .toList(),
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
                  child: DropdownButtonFormField<String>(
                    value: _selectedOutputFormat,
                    decoration: const InputDecoration(
                      labelText: 'Format',
                      border: OutlineInputBorder(),
                    ),
                    items: StabilityAIService.getOutputFormats()
                        .map((format) => DropdownMenuItem(
                              value: format,
                              child: Text(format.toUpperCase()),
                            ))
                        .toList(),
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
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Generating...'),
                      ],
                    )
                  : const Text('Generate Image'),
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
            
            if (_generatedImageBytes != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Generated Image:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _generatedImageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}