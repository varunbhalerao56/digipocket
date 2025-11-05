import 'dart:io';
import 'package:digipocket/feature/llama_cpp/llama_cpp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Presets for running llama.cpp via FFI on:
///   - iOS Simulator (CPU-only on your Mac)
///   - Real iPhone (Metal offload where possible)
class LlamaPresets {
  LlamaPresets._();

  static Future<String> materializeModel() async {
    final dir = await getApplicationSupportDirectory();
    await Directory(dir.path).create(recursive: true);
    final modelPath = '${dir.path}/LFM2-1.2B-Q8_0.gguf';

    final out = File(modelPath);
    if (!await out.exists()) {
      debugPrint('Copying model → $modelPath');
      final data = await rootBundle.load('assets/LFM2-1.2B-Q8_0.gguf');
      await out.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
    }

    // sanity: GGUF magic + size
    final f = File(modelPath);
    final first4 = await f.openRead(0, 4).fold<List<int>>([], (a, b) {
      a.addAll(b);
      return a;
    });
    if (first4.length < 4 || first4[0] != 0x47 || first4[1] != 0x47 || first4[2] != 0x55 || first4[3] != 0x46) {
      throw 'File at $modelPath is not GGUF (magic missing)';
    }
    debugPrint('Model present (${(await f.length()) ~/ (1024 * 1024)} MB)');
    return modelPath;
  }

  // ----------------------------
  // SIMULATOR (CPU-only) PRESETS
  // ----------------------------
  static ModelParams modelSimulator({bool useMmap = true}) {
    final p = ModelParams();
    p.nGpuLayers = 0; // absolutely no offload on sim
    p.splitMode = LlamaSplitMode.none;
    p.mainGpu = 0;
    p.tensorSplit = const [];
    p.useMemorymap = useMmap; // usually OK on mac host
    p.useMemoryLock = false; // keep false on sim
    p.vocabOnly = false;
    p.checkTensors = false;
    p.rpcServers = '';
    p.kvOverrides = {};
    return p;
  }

  static ContextParams ctxSimulator({
    int nCtx = 1536, // 1024–2048 safe for 1B on sim
    int nBatch = 256,
    int nUbatch = 256,
    int nPredict = 64,
    int? nThreads,
    int? nThreadsBatch,
  }) {
    final c = ContextParams();
    final hostCores = Platform.numberOfProcessors;
    final threads = (nThreads ?? (hostCores ~/ 2)).clamp(1, hostCores);

    c.nCtx = nCtx;
    c.nBatch = nBatch;
    c.nUbatch = nUbatch;
    c.nSeqMax = 1;
    c.nPredict = nPredict;

    c.nThreads = threads;
    c.nThreadsBatch = nThreadsBatch ?? threads;

    c.offloadKqv = false; // ensure CPU path on sim
    c.flashAttn = false;

    c.ropeScalingType = LlamaRopeScalingType.unspecified;
    c.poolingType = LlamaPoolingType.unspecified;
    c.attentionType = LlamaAttentionType.unspecified;
    c.noPerfTimings = false;
    return c;
  }

  static SamplerParams samplerBalancedLowTemp({
    int seed = 42,
    double temp = 0.2,
    int topK = 40,
    double topP = 0.95,
    double minP = 0.05,
    int repeatWindow = 64,
    double repeatPenalty = 1.05,
  }) {
    final s = SamplerParams();
    s.seed = seed;
    s.greedy = false;
    s.softmax = true;

    s.topK = topK;
    s.topP = topP;
    s.minP = minP;
    s.typical = 1.0;
    s.temp = temp;

    s.topPKeep = 1;
    s.minPKeep = 1;
    s.typicalKeep = 1;

    s.penaltyLastTokens = repeatWindow;
    s.penaltyRepeat = repeatPenalty;
    s.penaltyFreq = 0.0;
    s.penaltyPresent = 0.0;
    s.penaltyNewline = false;

    s.dryPenalty = 0.0;
    s.dryMultiplier = 1.75;
    s.dryAllowedLen = 2;
    s.dryLookback = -1;
    s.dryBreakers = const ["\n", ":", "\"", "*"];

    s.grammarStr = "";
    s.grammarRoot = "";

    s.xtcTemperature = 1.0;
    s.xtcStartValue = 0.1;
    s.xtcKeep = 1;
    s.xtcLength = 1;

    s.ignoreEOS = false;
    return s;
  }

  static LlamaLoad buildLoadForSimulator({
    required String modelPath,
    OlmoFormat? format,
    bool verbose = false,
    bool useMmap = true,
    int? nCtx,
    int? nThreads,
  }) {
    return LlamaLoad(
      path: modelPath,
      modelParams: modelSimulator(useMmap: useMmap),
      contextParams: ctxSimulator(nCtx: nCtx ?? 1536, nThreads: nThreads),
      samplingParams: samplerBalancedLowTemp(),
      format: format ?? OlmoFormat(),
      verbose: verbose,
    );
  }

  // ----------------------------
  // REAL DEVICE (iPhone 16 Pro)
  // ----------------------------
  /// Tuned for iPhone 16 Pro (A18 Pro). Uses Metal offload.
  /// Start conservative; you can push nCtx higher if memory permits.
  // In your LlamaPresets (device section)

  static ModelParams modelDevice({
    int nGpuLayers = 999, // offload as many as possible
    bool useMmap = true, // faster load
    bool useMlock = false, // iOS usually disallows mlock
  }) {
    final p = ModelParams();
    p.nGpuLayers = nGpuLayers;
    p.splitMode = LlamaSplitMode.layer;
    p.mainGpu = 0;
    p.tensorSplit = const [];
    p.useMemorymap = useMmap;
    p.useMemoryLock = useMlock;
    p.vocabOnly = false;
    p.checkTensors = false;
    p.rpcServers = '';
    p.kvOverrides = {};
    return p;
  }

  static ContextParams ctxDevice({
    int nCtx = 6144, // bump from 4096 → 6144; try 8192 if stable
    int nBatch = 384, // a bit smaller for smoothness
    int nUbatch = 384,
    int nPredict = 256, // typical single reply length
    int? nThreads,
    int? nThreadsBatch,
    bool offloadKqv = true, // keep on for Metal
    bool flashAttn = false, // default OFF (stability); try true later
  }) {
    final c = ContextParams();
    final cores = Platform.numberOfProcessors;
    final th = (nThreads ?? (cores - 1)).clamp(2, cores); // leave 1 core free

    c.nCtx = nCtx;
    c.nBatch = nBatch;
    c.nUbatch = nUbatch;
    c.nSeqMax = 1;
    c.nPredict = nPredict;

    c.nThreads = th;
    c.nThreadsBatch = nThreadsBatch ?? th;

    c.offloadKqv = offloadKqv;
    c.flashAttn = flashAttn;

    c.ropeScalingType = LlamaRopeScalingType.unspecified;
    c.poolingType = LlamaPoolingType.unspecified;
    c.attentionType = LlamaAttentionType.unspecified;
    c.noPerfTimings = false;
    return c;
  }

  static ContextParams ctxDeviceOptimized({
    int nCtx = 4096, // 4K is plenty for chat, saves memory
    int nBatch = 256, // smaller for mobile responsiveness
    int nUbatch = 256,
    int nPredict = 512, // allow longer responses
    int? nThreads,
    int? nThreadsBatch,
    bool offloadKqv = true,
    bool flashAttn = false,
  }) {
    final c = ContextParams();
    final cores = Platform.numberOfProcessors;
    // For mobile: use fewer threads to avoid thermal throttling
    final th = (nThreads ?? (cores > 4 ? cores - 2 : cores - 1)).clamp(2, cores);

    c.nCtx = nCtx;
    c.nBatch = nBatch;
    c.nUbatch = nUbatch;
    c.nSeqMax = 1;
    c.nPredict = nPredict;

    c.nThreads = th;
    c.nThreadsBatch = nThreadsBatch ?? (th > 2 ? th - 1 : th); // slightly fewer for batch

    c.offloadKqv = offloadKqv;
    c.flashAttn = flashAttn;

    c.ropeScalingType = LlamaRopeScalingType.unspecified;
    c.poolingType = LlamaPoolingType.unspecified;
    c.attentionType = LlamaAttentionType.unspecified;
    c.noPerfTimings = false;
    return c;
  }

  /// —— Samplers tuned for small instruct models ——

  /// Optimized for 1B instruct models - prevents repetition and improves coherence
  static SamplerParams samplerDevice1BInstruct({
    int seed = 0,
    double temp = 0.65, // slightly lower for better coherence
    int topK = 30, // smaller topK for focused outputs
    double topP = 0.85, // tighter topP
    double minP = 0.05, // filter very low probability tokens
    int lastN = 192, // longer context for repetition penalty
    double repeat = 1.15, // stronger repetition penalty
    double freqPenalty = 0.05, // add frequency penalty
    double presPenalty = 0.05, // add presence penalty
  }) {
    final s = SamplerParams();
    s.seed = seed;
    s.greedy = false;
    s.softmax = true;

    s.temp = temp;
    s.topK = topK;
    s.topP = topP;
    s.minP = minP; // Important: filters low-quality tokens
    s.typical = 1.0;

    s.penaltyLastTokens = lastN;
    s.penaltyRepeat = repeat;
    s.penaltyFreq = freqPenalty; // Helps with repetition
    s.penaltyPresent = presPenalty; // Encourages variety
    s.penaltyNewline = false;

    s.ignoreEOS = false;

    // Keep DRY off for simplicity
    s.dryPenalty = 0.0;
    s.dryMultiplier = 1.75;
    s.dryAllowedLen = 2;
    s.dryLookback = -1;
    s.dryBreakers = const ["\n", ":", "\"", "*"];
    s.grammarStr = "";
    s.grammarRoot = "";
    s.xtcTemperature = 1.0;
    s.xtcStartValue = 0.1;
    s.xtcKeep = 1;
    s.xtcLength = 1;
    return s;
  }

  /// For even more coherent but creative responses
  static SamplerParams samplerDevice1BBalanced() {
    return samplerDevice1BInstruct(
      temp: 0.7,
      topK: 40,
      topP: 0.9,
      minP: 0.05,
      lastN: 256,
      repeat: 1.12,
      freqPenalty: 0.03,
      presPenalty: 0.03,
    );
  }

  /// For very short, focused responses (good for quick Q&A)
  static SamplerParams samplerDevice1BConcise() {
    return samplerDevice1BInstruct(
      temp: 0.5,
      topK: 20,
      topP: 0.8,
      minP: 0.08,
      lastN: 128,
      repeat: 1.2,
      freqPenalty: 0.08,
      presPenalty: 0.08,
    );
  }

  /// Balanced chat (recommended default)
  static SamplerParams samplerDeviceChat({
    int seed = 0, // 0 → random
    double temp = 0.7,
    int topK = 40,
    double topP = 0.9,
    int lastN = 128,
    double repeat = 1.12,
  }) {
    final s = SamplerParams();
    s.seed = seed;
    s.greedy = false;
    s.softmax = true;

    s.temp = temp;
    s.topK = topK;
    s.topP = topP;
    s.minP = 0.0;
    s.typical = 1.0;

    s.penaltyLastTokens = lastN;
    s.penaltyRepeat = repeat;
    s.penaltyFreq = 0.0;
    s.penaltyPresent = 0.0;
    s.penaltyNewline = false;

    s.ignoreEOS = false;

    // keep DRY/grammar/XTC off
    s.dryPenalty = 0.0;
    s.dryMultiplier = 1.75;
    s.dryAllowedLen = 2;
    s.dryLookback = -1;
    s.dryBreakers = const ["\n", ":", "\"", "*"];
    s.grammarStr = "";
    s.grammarRoot = "";
    s.xtcTemperature = 1.0;
    s.xtcStartValue = 0.1;
    s.xtcKeep = 1;
    s.xtcLength = 1;
    return s;
  }

  /// More creative/verbose
  static SamplerParams samplerDeviceCreative() {
    return samplerDeviceChat(seed: 0, temp: 0.9, topK: 64, topP: 0.95, lastN: 128, repeat: 1.1);
  }

  /// More deterministic/concise (but not too brittle)
  static SamplerParams samplerDeviceDeterministic() {
    final s = samplerDeviceChat(
      seed: 42,
      temp: 0.4,
      topK: 0, // 0 = disable topK in many builds
      topP: 0.9,
      lastN: 128,
      repeat: 1.18,
    );
    return s;
  }

  /// Great with tiny models: adaptive control
  static SamplerParams samplerDeviceMirostat2({
    double tau = 5.0,
    double eta = 0.1,
    int lastN = 128,
    double repeat = 1.12,
  }) {
    final s = SamplerParams();
    s.seed = 0;
    s.greedy = false;
    s.softmax = true;

    // many llama.cpp bindings expose these:
    s.mirostatTau = tau;
    s.mirostatEta = eta;

    // still keep top-p as a soft cap in some builds
    s.topP = 0.9;
    s.topK = 0;
    s.temp = 0.7;
    s.minP = 0.0;

    s.penaltyLastTokens = lastN;
    s.penaltyRepeat = repeat;

    s.ignoreEOS = false;
    return s;
  }

  static SamplerParams samplerDeviceBalanced() => samplerBalancedLowTemp(); // same default is fine for 1B instruct

  static LlamaLoad buildLoadForDevice({
    required String modelPath,
    OlmoFormat? format,
    bool verbose = false,
    int? nCtx,
  }) {
    return LlamaLoad(
      path: modelPath,
      modelParams: modelDevice(),
      contextParams: ctxDevice(nCtx: nCtx ?? 4096),
      samplingParams: samplerDeviceBalanced(),
      format: format ?? OlmoFormat(),
      verbose: verbose,
    );
  }
}
