class StabilityAIRequest {
  final String prompt;
  final String? negativePrompt;
  final String aspectRatio;
  final String outputFormat;
  final int? seed;

  StabilityAIRequest({
    required this.prompt,
    this.negativePrompt,
    this.aspectRatio = '1:1',
    this.outputFormat = 'png',
    this.seed,
  });

  Map<String, dynamic> toFormData() {
    final Map<String, dynamic> data = {
      'prompt': prompt,
      'aspect_ratio': aspectRatio,
      'output_format': outputFormat,
    };

    if (negativePrompt != null && negativePrompt!.isNotEmpty) {
      data['negative_prompt'] = negativePrompt;
    }

    if (seed != null) {
      data['seed'] = seed.toString();
    }

    return data;
  }
}

class StabilityAIResponse {
  final String imageBase64;
  final int? seed;
  final String? finishReason;

  StabilityAIResponse({
    required this.imageBase64,
    this.seed,
    this.finishReason,
  });

  factory StabilityAIResponse.fromJson(Map<String, dynamic> json) {
    return StabilityAIResponse(
      imageBase64: json['image'] ?? '',
      seed: json['seed'],
      finishReason: json['finish_reason'],
    );
  }
}

class StabilityAIError {
  final String message;
  final int? code;

  StabilityAIError({
    required this.message,
    this.code,
  });

  factory StabilityAIError.fromJson(Map<String, dynamic> json) {
    return StabilityAIError(
      message: json['message'] ?? 'Unknown error',
      code: json['code'],
    );
  }
}